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

    property var bannedWords: 
    {
        try 
        {
            return plasmoid.configuration.banned && plasmoid.configuration.banned.length > 0
                ? JSON.parse(plasmoid.configuration.banned)
                : []
        } 
        catch (e) 
        {
            return []
        }
    }


    function refresh() 
    {
        try 
        {
            bannedWords = plasmoid.configuration.banned && plasmoid.configuration.banned.length > 0
                ? JSON.parse(plasmoid.configuration.banned)
                : []
        } 
        catch (e) 
        {
            bannedWords = []
        }
        bannedView.currentIndex = -1
    }


    header: ColumnLayout 
    {
        Kirigami.FormLayout 
        {
            RowLayout 
            {
                TextField 
                {
                    id: banField
                    placeholderText: qsTr("Ban articles that include a word, ex: NFL")
                }

                Button 
                {
                    text: qsTr("Insert")

                    onClicked: 
                    {
                        var input = banField.text.trim()
                        if (input === "")
                            return

                        input = input.replace(/[^\w\s]|_/g, "")
                        input = input.replace(/\s+/g, " ")
                        input = input.split(' ').map(
                            word => 
                            {
                                return word.charAt(0).toUpperCase() + word.slice(1).toLowerCase()
                            }
                        ).join(' ')

                        var updated = bannedWords.slice()
                        updated.push(input)
                        plasmoid.configuration.banned = JSON.stringify(updated)

                        banField.text = ""
                        refresh()
                    }
                }
            }

            Kirigami.Separator 
            {
                height: 1
                Kirigami.FormData.isSection: true
            }

            RowLayout 
            {
                Button 
                {
                    text: qsTr("X Unban Word")
                    Layout.fillHeight: true
                    enabled: bannedView.currentIndex >= 0

                    onClicked: 
                    {
                        var updated = bannedWords.slice()
                        if (bannedView.currentIndex >= 0) 
                        {
                            updated.splice(bannedView.currentIndex, 1)
                            plasmoid.configuration.banned = JSON.stringify(updated)
                            refresh()
                        }
                    }
                }

                Button 
                {
                    text: qsTr("⟳ Revert to Defaults")
                    Layout.fillHeight: true

                    onClicked: 
                    {
                        plasmoid.configuration.banned = plasmoid.configuration.bannedDefault
                        refresh()
                    }
                }
            }
        }
    }


    view: ListView 
    {
        id: bannedView

        model: bannedWords
        focus: true
        activeFocusOnTab: true
        currentIndex: -1

        delegate: ItemDelegate 
        {
            text: modelData
            width: bannedView.width

            onClicked: 
            {
                bannedView.forceActiveFocus();
                bannedView.currentIndex = index;
            }
        }
    }
}