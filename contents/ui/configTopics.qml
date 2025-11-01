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

    property var topicsList: JSON.parse(plasmoid.configuration.topics)


    function refreshTopics() 
    { 
        topicsList = JSON.parse(plasmoid.configuration.topics) 
        topicsView.currentIndex = -1
    }


    header: ColumnLayout
    {
        Kirigami.FormLayout
        {
            RowLayout
            {
                TextField
                {
                    id: newTopicField
                    placeholderText: qsTr("Enter a topic, ex: Health, NVIDIA, ...")
                }

                Button
                {
                    text: qsTr("Add New Topic")

                    onClicked: 
                    {
                        if (newTopicField.text.trim() === "")
                            return

                        var updated = topicsList.slice()
                        updated.push(newTopicField.text)
                        plasmoid.configuration.topics = JSON.stringify(updated)
                        refreshTopics()
                    }
                }
            }



            Kirigami.Separator
            {
                Kirigami.FormData.isSection: true
            }

            Kirigami.Separator
            {
            }

            RowLayout
            {
                Button 
                {
                    text: qsTr("X Remove Topic")
                    Layout.fillHeight: true
                    enabled: topicsView.currentIndex >= 0

                    onClicked: 
                    {
                        var updated = topicsList.slice()
                        updated.splice(topicsView.currentIndex, 1)
                        plasmoid.configuration.topics = JSON.stringify(updated)
                        refreshTopics()
                    }
                }

                Item { Layout.fillWidth: true }

                Button 
                {
                    text: qsTr("⟳ Default Topics")
                    Layout.fillHeight: true   

                    onClicked: 
                    {
                        plasmoid.configuration.topics = plasmoid.configuration.topicsDefault
                        refreshTopics()
                    }
                }
            }
        }
    }

    view: ListView
    {
        id: topicsView

        model: topicsList
        focus: true
        activeFocusOnTab: true
        currentIndex: -1

        delegate: ItemDelegate
        {
            text: modelData
            width: topicsView.width

            onClicked: 
            {
                topicsView.forceActiveFocus()
                topicsView.currentIndex = index
            }
        }
    }
}