# KDE Plasma widget for displaying due dates
## [work in progress]

### Set-up
To allow this widget to be selectable, everything underneath `./package` must be placed in the directory `~/.local/share/plasma/plasmoids/schmarx.custom_widget`.

The widget looks for a file `package/contents/ui/data.json` that contains a list of the following form:
```jsonc
[
    [
        "Module",
        "Assignment",
        "dd/mm/yyyy", // date
        "hh:mm"       // time
    ]
    // ...
]
```

The directory structure should then be:
```
~/.local/share/plasma/plasmoids
...
├── schmarx.custom_widget
│   ├── contents
│   │   ├── config
│   │   │   ├── config.qml
│   │   │   └── main.xml
│   │   └── ui
│   │       ├── configGeneral.qml
│   │       ├── data.json
│   │       └── main.qml
│   └── metadata.json
...

```

The widget then displays the amount due today, the amount due tomorrow, and duration until the next due item.

### This currently only works when an ENV variable is set as follows: `export QML_XHR_ALLOW_FILE_READ=1`.