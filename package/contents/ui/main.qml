import QtQuick 2.15
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.components 3.0 as PlasmaComponents
import org.kde.plasma.core as PlasmaCore
import QtQuick.Layouts 1.1
import org.kde.plasma.plasma5support 2.0 as P5Support

// to see logging set ENV variable: export QT_LOGGING_RULES="qml.debug=true"
// NOTE: currently this does not work if the following ENV variable is not set: export QML_XHR_ALLOW_FILE_READ=1

PlasmoidItem{
    id: main_item

    property var data: []

    property string text_value: ""
    property string next_text: ""

    preferredRepresentation: compactRepresentation
    
    readonly property string currentDate: Qt.locale().toString(dataSource.data["Local"]["DateTime"], Qt.locale().dateFormat(Locale.ShortFormat))
    readonly property string currentTime: Qt.locale().toString(dataSource.data["Local"]["DateTime"], Qt.locale().timeFormat(Locale.ShortFormat))
    property int count_tdy: 0
    property int count_tmrw: 0

    function pad(num) {
        if (num < 10) return `0${num}`;
        return `${num}`;
    }

    function date_format(date) {
        return `${pad(date.getDate())}/${pad(date.getMonth() + 1)}/${date.getFullYear()}`;
    }

    function date_unformat(date, hours, minutes) {
        let parts = date.split("/");
        return new Date(parts[2], parts[1] - 1, parts[0], hours, minutes, 0);
    }

    function my_func() {
        let req = new XMLHttpRequest();

        req.onreadystatechange = e => {
            if (req.readyState == 4) {
                data = JSON.parse(req.responseText);

                let due_tdy = 0;
                let due_tmrw = 0;

                let [year, month, day] = currentDate.split("/");
                year = Number(year);
                month = Number(month);
                day = Number(day);

                let [hours, minutes] = currentTime.split(":");
                hours = Number(hours);
                minutes = Number(minutes);

                let today_date = new Date(year, month - 1, day, hours, minutes, 0);
                let today = date_format(today_date);
                let tmrw = date_format(new Date(year, month - 1, day + 1));

                let text = "";
                let prev_date = "";

                // TODO: sort data by date and time in case it isn't already

                let found_next = false;
                data.forEach(item => {
                    let [h, m] = item[3].split(":");
                    h = Number(h);
                    m = Number(m)

                    let diff_seconds = (date_unformat(item[2], h, m).getTime() - today_date.getTime()) / 1000;
                    let diff_minutes = Math.floor(diff_seconds / 60);
                    let diff_hours = Math.floor(diff_minutes / 60);
                    let diff_days = Math.floor(diff_hours / 24);

                    if (diff_seconds > 0) {
                        if (!found_next) {
                            found_next = true;
                            if (diff_days < 1) {
                                if (diff_hours < 1) {
                                    next_text = "" + diff_minutes + "m";
                                }
                                else next_text = "" + diff_hours + "h";
                            } else next_text = "" + diff_days + "d";
                        }
                    }
                    else text += `\n----- ${prev_date} (${Math.abs(diff_days)} days ago) -----\n`;

                    if (item[2] == today) {
                        text += `\n----- today -----\n`;
                        due_tdy++;
                    } else if (item[2] == tmrw) {
                        text += `\n----- tomorrow -----\n`;
                        due_tmrw++;
                    } else if (prev_date != item[2]) {
                        prev_date = item[2];

                        if (diff_seconds > 0) {
                            text += `\n----- ${prev_date} (in ${Math.abs(diff_days)} days) -----\n`;
                        }
                        else text += `\n----- ${prev_date} (${Math.abs(diff_days)} days ago) -----\n`;
                    }

                    text += `${item[0]}: ${item[1]}\n`;
                });
                text_value = text;

                count_tdy = due_tdy;
                count_tmrw = due_tmrw;
            }
        };

        req.open("get", "./data.json");
        req.send();
    }

    compactRepresentation: Item {
            Layout.minimumWidth: 2*label.implicitWidth
            Layout.minimumHeight: label.implicitHeight
            Layout.preferredWidth: 500 * PlasmaCore.Units.devicePixelRatio
            Layout.preferredHeight: 500 * PlasmaCore.Units.devicePixelRatio
        

        Layout.fillHeight: true

        anchors {
            fill: parent
            // margins: 2
        }

        ColumnLayout {
            Layout.minimumWidth: label.implicitWidth + next_label.implicitWidth
            Layout.minimumHeight: label.implicitHeight
            Layout.preferredWidth: 500 * PlasmaCore.Units.devicePixelRatio
            Layout.preferredHeight: 500 * PlasmaCore.Units.devicePixelRatio
            
            Rectangle {
                color: count_tdy > 0 ? "#ff5d9c" : count_tmrw > 0 ? "#ffa15d" : "#5dffbb"
                // #5d69ff
                width: 4
                height: label.implicitHeight
            }

            MouseArea {
                id: hoverArea
                property bool expanded: false
                anchors.fill: parent
                // onPressed: expanded = 
                onClicked: mouse => {
                    main_item.expanded = !main_item.expanded
                }
            }

            PlasmaComponents.Label {
                // color: "#ff0000"
                id: next_label

                anchors {
                    fill: parent
                    // margins: 2
                }

                font.pixelSize: 10
                text: "                       next in " + next_text
            }

            PlasmaComponents.Label {
                // color: "#ff0000"
                id: label

                Layout.fillHeight: true
                Layout.fillWidth: true

                anchors {
                    fill: parent
                    // margins: 2
                }

                font.pixelSize: 10
                text: "  due today:    " + count_tdy + "\n  due tomorrow: " + count_tmrw

                // horizontalAlignment: Text.AlignHCenter
                Component.onCompleted: {
                    my_func();
                }
            }
        }
    }

    fullRepresentation: Item {
        Layout.minimumWidth: label.implicitWidth
        Layout.minimumHeight: label.implicitHeight
        Layout.preferredWidth: 500 * PlasmaCore.Units.devicePixelRatio
        Layout.preferredHeight: 500 * PlasmaCore.Units.devicePixelRatio
        
        PlasmaComponents.Label {
            id: label
            anchors.fill: parent
            text: text_value
            horizontalAlignment: Text.AlignHLeft
            Component.onCompleted: {
                my_func();
            }
        }
    }


    P5Support.DataSource {
        id: dataSource
        engine: "time"
        connectedSources: "Local"
        interval: 30000 // check every 30 seconds
        onDataChanged: {
            my_func();
        }
        Component.onCompleted: {
            dataChanged();
        }
    }
}