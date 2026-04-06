import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.SystemTray

PanelWindow {
    id: barWindow
    
    anchors {
        top: true
        left: true
        right: true
    }
    
    height: 48
    margins { top: 8; bottom: 0; left: 4; right: 4 }
    exclusiveZone: 52
    color: "transparent"

    MatugenColors { id: mocha }

    property string defaultFont: "JetBrainsMono Nerd Font Propo"

    function toJapaneseNumber(num) {
        const kanji = ["零", "一", "二", "三", "四", "五", "六", "七", "八", "九", "十"];
        let n = parseInt(num);
        if (isNaN(n) || n < 0 || n > 10) return num;
        return kanji[n];
    }

    property bool isStartupReady: false
    Timer { interval: 10; running: true; onTriggered: barWindow.isStartupReady = true }
    
    property bool startupCascadeFinished: false
    Timer { interval: 1000; running: true; onTriggered: barWindow.startupCascadeFinished = true }
    
    property bool isDataReady: false
    Timer { interval: 600; running: true; onTriggered: barWindow.isDataReady = true }
    
    property string timeStr: ""
    property string fullDateStr: ""
    property int typeInIndex: 0
    property string dateStr: fullDateStr.substring(0, typeInIndex)

    property string weatherIcon: ""
    property string weatherTemp: "--°"
    property string weatherHex: mocha.yellow
    
    // Unified Sys Info
    property var sysData: {
        "wifi": { "status": "Off", "icon": "󰤮", "ssid": "" },
        "bluetooth": { "status": "Off", "icon": "󰂲", "device": "" },
        "audio": { "volume": "0", "icon": "󰕾", "muted": false },
        "battery": { "percent": "100", "icon": "󰁹", "status": "Unknown" },
        "kb_layout": "US"
    }
    
    ListModel { id: workspacesModel }
    property var musicData: { "status": "Stopped", "title": "", "artUrl": "", "timeStr": "" }

    // Derived properties
    property bool isMediaActive: musicData.status !== "Stopped" && musicData.title !== ""
    property bool isWifiOn: sysData.wifi.status.toLowerCase() === "enabled" || sysData.wifi.status.toLowerCase() === "on"
    property bool isBtOn: sysData.bluetooth.status.toLowerCase() === "on"
    property bool isSoundActive: !sysData.audio.muted && parseInt(sysData.audio.volume) > 0
    property int batCap: parseInt(sysData.battery.percent) || 0
    property bool isCharging: sysData.battery.status === "Charging" || sysData.battery.status === "Full"
    property color batDynamicColor: {
        if (isCharging) return mocha.green;
        if (batCap >= 70) return mocha.blue;
        if (batCap >= 30) return mocha.yellow;
        return mocha.red;
    }

    // --- DATA FETCHING ---

    Process {
        id: wsDaemon
        command: ["bash", "-c", "/home/_null/.config/hypr/scripts/quickshell/workspaces.sh > /tmp/qs_workspaces.json"]
        running: true
    }

    Process {
        id: wsPoller
        command: ["bash", "-c", "tail -n 1 /tmp/qs_workspaces.json 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                let txt = this.text.trim();
                if (txt !== "") {
                    try { 
                        let newData = JSON.parse(txt);
                        if (workspacesModel.count !== newData.length) {
                            workspacesModel.clear();
                            for (let i = 0; i < newData.length; i++) {
                                workspacesModel.append({ "wsId": newData[i].id.toString(), "wsState": newData[i].state });
                            }
                        } else {
                            for (let i = 0; i < newData.length; i++) {
                                if (workspacesModel.get(i).wsState !== newData[i].state) workspacesModel.setProperty(i, "wsState", newData[i].state);
                                if (workspacesModel.get(i).wsId !== newData[i].id.toString()) workspacesModel.setProperty(i, "wsId", newData[i].id.toString());
                            }
                        }
                    } catch(e) {}
                }
            }
        }
    }
    Timer { interval: 200; running: true; repeat: true; onTriggered: wsPoller.running = true }

    // Unified System Poller (500ms for responsiveness with low overhead)
    Process {
        id: sysPoller
        command: ["bash", "-c", "/home/_null/.config/hypr/scripts/quickshell/sys_info.sh --all"]
        stdout: StdioCollector {
            onStreamFinished: {
                let txt = this.text.trim();
                if (txt !== "") {
                    try { 
                        barWindow.sysData = JSON.parse(txt); 
                        barWindow.isDataReady = true;
                    } catch(e) {}
                }
            }
        }
    }
    Timer { interval: 500; running: true; repeat: true; triggeredOnStart: true; onTriggered: sysPoller.running = true }

    Process {
        id: musicPoller
        command: ["bash", "-c", "cat /tmp/music_info.json 2>/dev/null || bash /home/_null/.config/hypr/scripts/quickshell/music/music_info.sh"]
        stdout: StdioCollector {
            onStreamFinished: {
                let txt = this.text.trim();
                if (txt !== "") {
                    try { barWindow.musicData = JSON.parse(txt); } catch(e) {}
                }
            }
        }
    }
    Timer { interval: 800; running: true; repeat: true; onTriggered: musicPoller.running = true }

    Process {
        id: weatherPoller
        command: ["bash", "-c", `
            echo "$(/home/_null/.config/hypr/scripts/quickshell/calendar/weather.sh --current-icon)"
            echo "$(/home/_null/.config/hypr/scripts/quickshell/calendar/weather.sh --current-temp)"
            echo "$(/home/_null/.config/hypr/scripts/quickshell/calendar/weather.sh --current-hex)"
        `]
        stdout: StdioCollector {
            onStreamFinished: {
                let lines = this.text.trim().split("\n");
                if (lines.length >= 3) {
                    barWindow.weatherIcon = lines[0];
                    barWindow.weatherTemp = lines[1];
                    barWindow.weatherHex = lines[2] || mocha.yellow;
                }
            }
        }
    }
    Timer { interval: 300000; running: true; repeat: true; triggeredOnStart: true; onTriggered: weatherPoller.running = true }

    Timer {
        interval: 1000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: {
            let d = new Date();
            barWindow.timeStr = Qt.formatDateTime(d, "hh:mm:ss AP");
            barWindow.fullDateStr = Qt.formatDateTime(d, "dddd, MMMM dd");
        }
    }

    Timer {
        id: typewriterTimer
        interval: 40
        running: barWindow.isStartupReady && barWindow.typeInIndex < barWindow.fullDateStr.length
        repeat: true
        onTriggered: barWindow.typeInIndex += 1
    }

    // --- UI LAYOUT ---
    Item {
        anchors.fill: parent

        RowLayout {
            id: leftLayout
            anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter; spacing: 4 
            property bool showLayout: false
            opacity: showLayout ? 1 : 0
            transform: Translate { x: leftLayout.showLayout ? 0 : -30; Behavior on x { NumberAnimation { duration: 800; easing.type: Easing.OutBack } } }
            Timer { running: barWindow.isStartupReady; interval: 10; onTriggered: leftLayout.showLayout = true }
            Behavior on opacity { NumberAnimation { duration: 600 } }

            // Search
            Rectangle {
                id: searchBtn; radius: 14; Layout.preferredHeight: 48; Layout.preferredWidth: 48
                color: searchMouse.containsMouse ? mocha.surface1 : mocha.base
                opacity: searchMouse.containsMouse ? 0.95 : 0.75
                Text { anchors.centerIn: parent; text: "󰍉"; font.pixelSize: 24; font.family: barWindow.defaultFont; color: searchMouse.containsMouse ? mocha.blue : mocha.text }
                MouseArea { id: searchMouse; anchors.fill: parent; hoverEnabled: true; onClicked: Quickshell.execDetached(["bash", "-c", "/home/_null/.config/hypr/scripts/rofi_show.sh drun"]) }
            }

            // Notifs
            Rectangle {
                radius: 14; Layout.preferredHeight: 48; Layout.preferredWidth: 48
                color: notifMouse.containsMouse ? mocha.surface1 : mocha.base
                opacity: notifMouse.containsMouse ? 0.95 : 0.75
                Text { anchors.centerIn: parent; text: ""; font.pixelSize: 18; font.family: barWindow.defaultFont; color: notifMouse.containsMouse ? mocha.yellow : mocha.text }
                MouseArea { id: notifMouse; anchors.fill: parent; hoverEnabled: true; onClicked: Quickshell.execDetached(["swaync-client", "-t", "-sw"]) }
            }

            // Workspaces
            Rectangle {
                color: mocha.base; opacity: 0.75; radius: 14; Layout.preferredHeight: 48
                Layout.preferredWidth: wsLayout.implicitWidth + 20
                visible: workspacesModel.count > 0
                RowLayout { id: wsLayout; anchors.centerIn: parent; spacing: 6
                    Repeater {
                        model: workspacesModel
                        delegate: Rectangle {
                            Layout.preferredWidth: 32; Layout.preferredHeight: 32; radius: 10
                            color: model.wsState === "active" ? mocha.mauve : (wsMouse.containsMouse ? mocha.surface2 : "transparent")
                            Text { 
                                anchors.centerIn: parent
                                text: barWindow.toJapaneseNumber(model.wsId)
                                font.family: barWindow.defaultFont
                                font.pixelSize: 16
                                color: (model.wsState === "active" || wsMouse.containsMouse) ? mocha.base : mocha.text 
                            }
                            MouseArea { id: wsMouse; anchors.fill: parent; hoverEnabled: true; onClicked: Quickshell.execDetached(["bash", "-c", "/home/_null/.config/hypr/scripts/qs_manager.sh " + model.wsId]) }
                        }
                    }
                }
            }
        }

        // Center
        Rectangle {
            id: centerBox; anchors.centerIn: parent; radius: 14; height: 48
            color: centerMouse.containsMouse ? mocha.surface1 : mocha.base
            opacity: centerMouse.containsMouse ? 0.95 : 0.75
            width: centerLayout.implicitWidth + 36
            RowLayout {
                id: centerLayout; anchors.centerIn: parent; spacing: 24
                ColumnLayout { spacing: -2
                    Text { text: barWindow.timeStr; font.pixelSize: 16; font.weight: Font.Black; font.family: barWindow.defaultFont; color: mocha.blue }
                    Text { text: barWindow.dateStr; font.pixelSize: 11; font.weight: Font.Bold; font.family: barWindow.defaultFont; color: mocha.subtext0 }
                }
                RowLayout { spacing: 8
                    Text { text: barWindow.weatherIcon; font.pixelSize: 24; font.family: barWindow.defaultFont; color: barWindow.weatherHex }
                    Text { text: barWindow.weatherTemp; font.pixelSize: 17; font.weight: Font.Black; font.family: barWindow.defaultFont; color: mocha.peach }
                }
            }
            MouseArea { id: centerMouse; anchors.fill: parent; hoverEnabled: true; onClicked: Quickshell.execDetached(["bash", "-c", "/home/_null/.config/hypr/scripts/qs_manager.sh toggle calendar"]) }
        }

        RowLayout {
            id: rightLayout
            anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; spacing: 4
            property bool showLayout: false
            opacity: showLayout ? 1 : 0
            transform: Translate { x: rightLayout.showLayout ? 0 : 30; Behavior on x { NumberAnimation { duration: 800; easing.type: Easing.OutBack } } }
            Timer { running: barWindow.isStartupReady && barWindow.isDataReady; interval: 250; onTriggered: rightLayout.showLayout = true }

            // Tray
            Rectangle {
                height: 48; radius: 14; color: mocha.base; opacity: 0.75
                Layout.preferredWidth: trayLayout.implicitWidth + 24; visible: trayRepeater.count > 0
                RowLayout { id: trayLayout; anchors.centerIn: parent; spacing: 10
                    Repeater {
                        id: trayRepeater; model: SystemTray.items
                        delegate: Image {
                            source: modelData.icon || ""; Layout.preferredWidth: 18; Layout.preferredHeight: 18
                            MouseArea { anchors.fill: parent; onClicked: modelData.activate() }
                        }
                    }
                }
            }

            // System Pill
            Rectangle {
                height: 48; radius: 14; color: mocha.base; opacity: 0.75
                Layout.preferredWidth: sysLayout.implicitWidth + 20
                RowLayout {
                    id: sysLayout; anchors.centerIn: parent; spacing: 8
                    // Layout
                    Rectangle { 
                        radius: 10; Layout.preferredHeight: 34; Layout.preferredWidth: 40; color: mocha.surface0 
                        Text { anchors.centerIn: parent; text: barWindow.sysData.kb_layout; color: mocha.text; font.weight: Font.Black; font.family: barWindow.defaultFont }
                    }
                    // Wifi
                    Rectangle { 
                        radius: 10; Layout.preferredHeight: 34; Layout.preferredWidth: 40; color: barWindow.isWifiOn ? mocha.blue : mocha.surface0 
                        Text { anchors.centerIn: parent; text: barWindow.sysData.wifi.icon; color: barWindow.isWifiOn ? mocha.base : mocha.text; font.family: barWindow.defaultFont }
                        MouseArea { anchors.fill: parent; onClicked: Quickshell.execDetached(["bash", "-c", "/home/_null/.config/hypr/scripts/qs_manager.sh toggle network wifi"]) }
                    }
                    // Audio
                    Rectangle { 
                        radius: 10; Layout.preferredHeight: 34; Layout.preferredWidth: 60; color: barWindow.isSoundActive ? mocha.peach : mocha.surface0 
                        RowLayout { anchors.centerIn: parent; spacing: 4
                            Text { text: barWindow.sysData.audio.icon; color: barWindow.isSoundActive ? mocha.base : mocha.text; font.family: barWindow.defaultFont }
                            Text { text: barWindow.sysData.audio.volume + "%"; color: barWindow.isSoundActive ? mocha.base : mocha.text; font.weight: Font.Black; font.family: barWindow.defaultFont }
                        }
                        MouseArea { anchors.fill: parent; onClicked: Quickshell.execDetached(["bash", "-c", "/home/_null/.config/hypr/scripts/quickshell/sys_info.sh --toggle-mute"]) }
                    }
                    // Battery
                    Rectangle { 
                        radius: 10; Layout.preferredHeight: 34; Layout.preferredWidth: 60; color: (barWindow.isCharging || barWindow.batCap <= 20) ? barWindow.batDynamicColor : mocha.surface0 
                        RowLayout { anchors.centerIn: parent; spacing: 4
                            Text { text: barWindow.sysData.battery.icon; color: (barWindow.isCharging || barWindow.batCap <= 20) ? mocha.base : barWindow.batDynamicColor; font.family: barWindow.defaultFont }
                            Text { text: barWindow.sysData.battery.percent + "%"; color: (barWindow.isCharging || barWindow.batCap <= 20) ? mocha.base : barWindow.batDynamicColor; font.weight: Font.Black; font.family: barWindow.defaultFont }
                        }
                        MouseArea { anchors.fill: parent; onClicked: Quickshell.execDetached(["bash", "-c", "/home/_null/.config/hypr/scripts/qs_manager.sh toggle battery"]) }
                    }
                }
            }
        }
    }
}
