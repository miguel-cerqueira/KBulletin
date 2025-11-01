import QtQml 
import QtQuick
import QtQuick.Layouts
import QtQuick.Dialogs
import QtQuick.Controls

import org.kde.kcmutils as KCM
import org.kde.kirigami as Kirigami
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.extras as PlasmaExtras


KCM.ScrollViewKCM
{
    id: root    
    

    property var sourcesList: JSON.parse(plasmoid.configuration.sources)


    function refreshSources() 
    { 
        sourcesList = JSON.parse(plasmoid.configuration.sources) 
        feedList.currentIndex = -1
    }



    header: ColumnLayout
    {
        id: feedConfig


        Kirigami.InlineMessage 
        {
            id: errorMessage

            Layout.fillWidth: true
            visible: false
            type: Kirigami.MessageType.Error
            
            function showError(message) 
            {
                text = message
                visible = true
                hideTimer.restart()
            }
            
            Timer 
            {
                id: hideTimer
                interval: 3000
                onTriggered: errorMessage.visible = false
            }
        }


        Kirigami.FormLayout
        {
            Kirigami.Separator 
            {
                Kirigami.FormData.isSection: true
                Kirigami.FormData.label: qsTr("Add Feed")
            }

            RowLayout
            {
                TextField
                {
                    id: newName
                    placeholderText: qsTr("Name (Optional)")
                }

                TextField
                {
                    id: urlNewFeed
                    placeholderText: qsTr("Enter a valid RSS URL…")
                }

                ComboBox 
                {
                    id: topicNewFeed
                    model: JSON.parse(plasmoid.configuration.topics)
                    Layout.fillHeight: true
                }
            }
            
            Button 
            {
                text: qsTr("Insert")
                Layout.fillHeight: true

                onClicked: 
                {
                    var topic = topicNewFeed.currentText
                    var url   = urlNewFeed.text.trim()
                    var name  = newName.text.trim()
                    if (!url) return

                    var sources = JSON.parse(plasmoid.configuration.sources || "[]")


                    var urlExists = sources.some(function(source) 
                    {
                        return source.url.toLowerCase() === url.toLowerCase()
                    })

                    if (urlExists) 
                    {
                        errorMessage.showError(qsTr("The URL is already present in the feed."))
                        return
                    }

                    var nameExists = sources.some(function(source) 
                    {
                        return source.source.toLowerCase() === name.toLowerCase()
                    })

                    if (nameExists) 
                    {
                        errorMessage.showError(qsTr("Name is already taken by another source."))
                        return
                    }


                    if (!url.startsWith("http://") && !url.startsWith("https://"))
                        url = "https://" + url
                    
                    if (name === "") 
                    {
                        var host = url.replace(/^https?:\/\//, '').split('/')[0]
                        name = host.replace(/^www\./, '')
                    }


                    var newSource = 
                    {
                        source: name,
                        url: url,
                        topic: topic
                    }

                    sources.push(newSource)
                    plasmoid.configuration.sources = JSON.stringify(sources)

                    urlNewFeed.text = ""
                    newName.text    = ""
                    successMessage.showSuccess(qsTr("Source '%1' added successfully.").arg(name))
                }
            }

            
            Kirigami.InlineMessage 
            {
                id: successMessage

                Layout.fillWidth: true
                visible: false
                type: Kirigami.MessageType.Positive
                
                function showSuccess(message) 
                {
                    text = message
                    visible = true
                    successHideTimer.restart()
                }
                
                Timer 
                {
                    id: successHideTimer
                    interval: 3000
                    onTriggered: successMessage.visible = false
                }
            }

            
            Kirigami.Separator 
            {
                Kirigami.FormData.isSection: true
                Kirigami.FormData.label: qsTr("Feed Management")
            }


            RowLayout
            {
                Layout.alignment: Qt.AlignVCenter
                Layout.fillWidth: true
                spacing: 10

                Button 
                {
                    text: qsTr("X Remove Feed")
                    Layout.fillHeight: true
                    enabled: feedList.currentIndex >= 0

                    onClicked: 
                    {
                        var updated = sourcesList.slice()
                        updated.splice(feedList.currentIndex, 1)
                        plasmoid.configuration.sources = JSON.stringify(updated)
                    }
                }

                Button 
                {
                    text: qsTr("Change Name")
                    Layout.fillHeight: true
                    enabled: feedList.currentIndex >= 0

                    onClicked: changeNameDialog.openDialog(feedList.currentIndex)
                }

                Button 
                {
                    text: qsTr("Change Topic")
                    Layout.fillHeight: true
                    enabled: feedList.currentIndex >= 0

                    onClicked: changeTopicDialog.openDialog(feedList.currentIndex)
                }
                

                Item { Layout.fillWidth: true }

                Button 
                {
                    text: qsTr("⟳ Default Settings")
                    Layout.fillHeight: true   

                    onClicked: 
                    {
                        plasmoid.configuration.sources = plasmoid.configuration.sourcesDefault
                        var sources = JSON.parse(plasmoid.configuration.sources).map(entry => entry.url)

                        if (sources.length > 3)
                            root.activeSources = sources.slice(0, 2)
                    }
                }
            }
        }
    }

    view: ListView
    {
        id: feedList

        model: sourcesList
        focus: true
        activeFocusOnTab: true
        currentIndex: -1

        delegate: ItemDelegate
        {
            text: "Source: " + modelData.source + "\nTopic: " + modelData.topic + "\n" + modelData.url
            width: feedList.width

            onClicked: 
            {
                feedList.forceActiveFocus()
                feedList.currentIndex = index
            }
        }
    }

    
    // ---------- Something went wrong ----------
    MessageDialog 
    {
        id: error

        title: qsTr("Error")
        
        function showCriticalError(message) 
        {
            text = message
            open()
        }
    }


    // ---------- Alter Name ----------
    Dialog 
    {
        id: changeNameDialog

        title: qsTr("Change Source Name")
        modal: true
        anchors.centerIn: parent
        
        property int selectedIndex: -1
        property string currentName: ""
        
        function openDialog(index) 
        {
            selectedIndex = index
            currentName = sourcesList[index].source
            newNameField.text = currentName
            newNameField.selectAll()
            open()
        }
        
        contentItem: ColumnLayout 
        {
            spacing: Kirigami.Units.largeSpacing
            
            Label 
            {
                text: qsTr("Current name: %1").arg(changeNameDialog.currentName)
                font.weight: Font.Bold
            }
            
            TextField 
            {
                id: newNameField
                Layout.fillWidth: true
                placeholderText: qsTr("Enter new name...")
                
                onAccepted: 
                {
                    if (acceptButton.enabled)
                        changeNameDialog.accept()
                }
            }
            
            Label 
            {
                id: dialogErrorLabel

                Layout.fillWidth: true
                color: Kirigami.Theme.negativeTextColor
                visible: false
                wrapMode: Text.WordWrap
            }
        }
        
        standardButtons: Dialog.Ok | Dialog.Cancel
        
        onAccepted: 
        {
            var newName = newNameField.text.trim()
            
            if (!newName) 
            {
                errorMessage.showError(qsTr("Name field is empty."))
                return
            }
            
            var sources = JSON.parse(plasmoid.configuration.sources || "[]")

            var nameExists = sources.some(function(source, index) 
            {
                return index !== selectedIndex && source.source.toLowerCase() === newName.toLowerCase()
            })
            
            if (nameExists) 
            {
                errorMessage.showError(qsTr("The name is already in use."))
                return
            }
            
            var updated = sources.slice()
            updated[selectedIndex].source = newName
            plasmoid.configuration.sources = JSON.stringify(updated)
            
            successMessage.showSuccess(qsTr("Name altered successfully.").arg(name))
            
            close()
        }
        
        onOpened: 
        {
            dialogErrorLabel.visible = false
            newNameField.forceActiveFocus()
        }
    }

    
    // ---------- Alter Topic ----------
    Dialog 
    {
        id: changeTopicDialog

        title: qsTr("Change Source Topic")
        modal: true
        anchors.centerIn: parent
        
        property int selectedIndex: -1
        property string currentTopic: ""
        
        function openDialog(index) 
        {
            selectedIndex = index
            currentTopic = sourcesList[index].topic
            topicComboBox.currentIndex = topicComboBox.find(currentTopic)
            open()
        }

        
        contentItem: ColumnLayout 
        {
            spacing: Kirigami.Units.largeSpacing
            
            Label 
            {
                text: qsTr("Current topic: %1").arg(changeTopicDialog.currentTopic)
                font.weight: Font.Bold
            }
            
            ComboBox 
            {
                id: topicComboBox
                Layout.fillWidth: true
                model: JSON.parse(plasmoid.configuration.topics)
            }
        }
        
        
        standardButtons: Dialog.Ok | Dialog.Cancel
        
        onAccepted: 
        {
            var newTopic = topicComboBox.currentText
            
            if (newTopic === currentTopic) 
            {
                close()
                return
            }
            
            var sources = JSON.parse(plasmoid.configuration.sources || "[]")
            var updated = sources.slice()
            updated[selectedIndex].topic = newTopic
            plasmoid.configuration.sources = JSON.stringify(updated)
            
            successMessage.showSuccess(qsTr("Topic changed successfully from '%1' to '%2'.").arg(currentTopic).arg(newTopic))
            
            close()
        }
        
        onOpened: 
        {
            topicComboBox.forceActiveFocus()
        }
    }
}