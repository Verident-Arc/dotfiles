import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import "../"

Item {
    id: root
    focus: true

    // --- THEME ---
    MatugenColors { id: mocha }
    readonly property string defaultFont: "JetBrainsMono Nerd Font Propo"
    readonly property string scriptsDir: Quickshell.env("HOME") + "/.config/hypr/scripts/quickshell/audio"

    // --- ANIMATION STATES ---
    property real introAlpha: 0
    property real introSlide: 0
    
    ParallelAnimation {
        running: true
        NumberAnimation { target: root; property: "introAlpha"; from: 0; to: 1.0; duration: 800; easing.type: Easing.OutQuart }
        NumberAnimation { target: root; property: "introSlide"; from: 30; to: 0; duration: 800; easing.type: Easing.OutQuart }
    }

    // --- DATA ---
    ListModel { id: sinksModel }
    ListModel { id: sourcesModel }
    ListModel { id: sinkInputsModel }
    ListModel { id: sourceOutputsModel }

    property string defaultSink: ""
    property string defaultSource: ""

    function getVolPercent(volObj) {
        if (!volObj) return 0;
        let firstChan = Object.keys(volObj)[0];
        if (firstChan && volObj[firstChan].value_percent) {
            return parseInt(volObj[firstChan].value_percent.replace("%", ""));
        }
        return 0;
    }

    Process {
        id: audioFetcher
        command: ["bash", scriptsDir + "/audio_info.sh", "--get"]
        stdout: StdioCollector {
            onStreamFinished: {
                let txt = this.text.trim();
                if (txt === "") return;
                try {
                    let data = JSON.parse(txt);
                    updateModel(sinksModel, data.sinks);
                    updateModel(sourcesModel, data.sources);
                    updateModel(sinkInputsModel, data.sink_inputs);
                    updateModel(sourceOutputsModel, data.source_outputs);
                    root.defaultSink = data.default_sink;
                    root.defaultSource = data.default_source;
                } catch(e) { console.log("Error parsing audio data: " + e); }
            }
        }
    }

    function updateModel(model, data) {
        if (!data) { model.clear(); return; }
        model.clear();
        for (let item of data) { model.append(item); }
    }

    Timer {
        interval: 1000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: audioFetcher.running = true
    }

    // --- UI ---
    Rectangle {
        anchors.fill: parent
        radius: 24
        color: mocha.base
        opacity: root.introAlpha
        
        transform: Translate { y: root.introSlide }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 25
            spacing: 20

            // HEADER
            Item {
                Layout.fillWidth: true
                height: 50
                RowLayout {
                    anchors.centerIn: parent
                    spacing: 12
                    Text { 
                        text: "AUDIO CENTER"
                        color: mocha.text
                        font.family: root.defaultFont
                        font.pixelSize: 20
                        font.weight: Font.Black
                    }
                }
                
                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width * 0.6
                    height: 1
                    opacity: 0.3
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: "transparent" }
                        GradientStop { position: 0.5; color: mocha.mauve }
                        GradientStop { position: 1.0; color: "transparent" }
                    }
                }
            }

            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                contentWidth: availableWidth
                ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
                clip: true

                ColumnLayout {
                    width: parent.width - 10
                    spacing: 30

                    // SINK SECTION
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 12
                        SectionHeader { info: ({ "title": "OUTPUT DEVICES", "accent": mocha.blue }) }
                        Repeater {
                            model: sinksModel
                            delegate: deviceDelegate
                        }
                    }

                    // SOURCE SECTION
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 12
                        visible: sourcesModel.count > 0
                        SectionHeader { info: ({ "title": "INPUT DEVICES", "accent": mocha.green }) }
                        Repeater {
                            model: sourcesModel
                            delegate: inputDeviceDelegate
                        }
                    }

                    // MIXER SECTION
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 12
                        visible: sinkInputsModel.count > 0
                        SectionHeader { info: ({ "title": "APPLICATION MIXER", "accent": mocha.mauve }) }
                        Repeater {
                            model: sinkInputsModel
                            delegate: mixerDelegate
                        }
                    }

                    // RECORDING SECTION
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 12
                        visible: sourceOutputsModel.count > 0
                        SectionHeader { info: ({ "title": "RECORDING STREAMS", "accent": mocha.red }) }
                        Repeater {
                            model: sourceOutputsModel
                            delegate: recordingDelegate
                        }
                    }
                }
            }
        }
    }

    // --- HELPER COMPONENT FOR SECTION HEADERS ---
    component SectionHeader: RowLayout {
        property var info: ({})
        Layout.fillWidth: true
        spacing: 10
        Text { 
            text: info.title
            color: info.accent
            font.family: root.defaultFont
            font.pixelSize: 13
            font.weight: Font.Black
        }
        Rectangle { Layout.fillWidth: true; height: 1; color: info.accent; opacity: 0.1 }
    }

    // --- DELEGATES ---

    Component {
        id: deviceDelegate
        Rectangle {
            Layout.fillWidth: true
            height: 75
            radius: 16
            color: model.name === root.defaultSink ? mocha.surface1 : mocha.surface0
            border.color: model.name === root.defaultSink ? mocha.blue : "transparent"
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.margins: 15
                spacing: 15

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    Text { 
                        text: model.description
                        color: mocha.text
                        font.family: root.defaultFont
                        font.pixelSize: 13
                        font.weight: Font.Bold
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                    Text { 
                        text: model.name === root.defaultSink ? "ACTIVE" : "IDLE"
                        color: model.name === root.defaultSink ? mocha.blue : mocha.subtext0
                        font.family: root.defaultFont
                        font.pixelSize: 9
                        font.weight: Font.Black
                    }
                }

                CustomSlider {
                    Layout.preferredWidth: 180
                    accentColor: mocha.blue
                    value: root.getVolPercent(model.volume)
                    onValueChanged: {
                        if (pressed) {
                            Quickshell.execDetached(["bash", scriptsDir + "/audio_info.sh", "--set-volume", "sink", model.index, Math.round(value)])
                        }
                    }
                }

                Switch {
                    checked: model.name === root.defaultSink
                    onToggled: Quickshell.execDetached(["bash", scriptsDir + "/audio_info.sh", "--set-sink", model.name])
                }
            }
        }
    }

    Component {
        id: inputDeviceDelegate
        Rectangle {
            Layout.fillWidth: true
            height: 75
            radius: 16
            color: model.name === root.defaultSource ? mocha.surface1 : mocha.surface0
            border.color: model.name === root.defaultSource ? mocha.green : "transparent"
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.margins: 15
                spacing: 15

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    Text { 
                        text: model.description
                        color: mocha.text
                        font.family: root.defaultFont
                        font.pixelSize: 13
                        font.weight: Font.Bold
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                    Text { 
                        text: model.name === root.defaultSource ? "ACTIVE" : "IDLE"
                        color: model.name === root.defaultSource ? mocha.green : mocha.subtext0
                        font.family: root.defaultFont
                        font.pixelSize: 9
                        font.weight: Font.Black
                    }
                }

                CustomSlider {
                    Layout.preferredWidth: 180
                    accentColor: mocha.green
                    value: root.getVolPercent(model.volume)
                    onValueChanged: {
                        if (pressed) {
                            Quickshell.execDetached(["bash", scriptsDir + "/audio_info.sh", "--set-volume", "source", model.index, Math.round(value)])
                        }
                    }
                }

                Switch {
                    checked: model.name === root.defaultSource
                    onToggled: Quickshell.execDetached(["bash", scriptsDir + "/audio_info.sh", "--set-source", model.name])
                }
            }
        }
    }

    Component {
        id: mixerDelegate
        Rectangle {
            Layout.fillWidth: true
            height: 65
            radius: 14
            color: mocha.surface0

            RowLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 12

                Text {
                    text: model.properties["application.name"] || model.properties["media.name"] || "Application"
                    color: mocha.text
                    font.family: root.defaultFont
                    font.pixelSize: 13
                    font.weight: Font.Bold
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }

                CustomSlider {
                    Layout.preferredWidth: 220
                    accentColor: mocha.mauve
                    value: root.getVolPercent(model.volume)
                    onValueChanged: {
                        if (pressed) {
                            Quickshell.execDetached(["bash", scriptsDir + "/audio_info.sh", "--set-volume", "sink-input", model.index, Math.round(value)])
                        }
                    }
                }

                Text {
                    text: root.getVolPercent(model.volume) + "%"
                    color: mocha.subtext0
                    font.family: root.defaultFont
                    font.pixelSize: 10
                    font.weight: Font.Bold
                    Layout.preferredWidth: 35
                }
            }
        }
    }

    Component {
        id: recordingDelegate
        Rectangle {
            Layout.fillWidth: true
            height: 65
            radius: 14
            color: mocha.surface0

            RowLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 12

                Text {
                    text: model.properties["application.name"] || model.properties["media.name"] || "Recording"
                    color: mocha.text
                    font.family: root.defaultFont
                    font.pixelSize: 13
                    font.weight: Font.Bold
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }

                CustomSlider {
                    Layout.preferredWidth: 220
                    accentColor: mocha.red
                    value: root.getVolPercent(model.volume)
                    onValueChanged: {
                        if (pressed) {
                            Quickshell.execDetached(["bash", scriptsDir + "/audio_info.sh", "--set-volume", "source-output", model.index, Math.round(value)])
                        }
                    }
                }
            }
        }
    }

    // --- CUSTOM COMPONENTS ---

    component CustomSlider: Slider {
        id: control
        property color accentColor: mocha.blue
        from: 0
        to: 100
        stepSize: 1
        
        background: Rectangle {
            x: control.leftPadding
            y: control.topPadding + control.availableHeight / 2 - height / 2
            implicitWidth: 200
            implicitHeight: 6
            width: control.availableWidth
            height: implicitHeight
            radius: 3
            color: mocha.surface1
            
            Rectangle {
                width: control.visualPosition * parent.width
                height: parent.height
                color: control.accentColor
                radius: 3
            }
        }

        handle: Rectangle {
            x: control.leftPadding + control.visualPosition * (control.availableWidth - width)
            y: control.topPadding + control.availableHeight / 2 - height / 2
            implicitWidth: 16
            implicitHeight: 16
            radius: 8
            color: control.pressed ? mocha.text : control.accentColor
            border.color: mocha.base
            border.width: 3
            
            Behavior on scale { NumberAnimation { duration: 100 } }
            scale: control.hovered ? 1.2 : 1.0
        }
    }
}
