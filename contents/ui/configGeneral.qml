import QtQml 
import QtQuick
import QtQuick.Layouts
import QtQuick.Dialogs
import QtQuick.Controls

import org.kde.kcmutils as KCM
import org.kde.kirigami as Kirigami
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.extras as PlasmaExtras


KCM.SimpleKCM 
{
    id: root


    property var intervalRate: JSON.parse(plasmoid.configuration.refreshInterval)
    property var maxArticlesInt: JSON.parse(plasmoid.configuration.maxArticles)


    Component.onCompleted: 
    {
        intervalRate   = JSON.parse(plasmoid.configuration.refreshInterval)
        maxArticlesInt = JSON.parse(plasmoid.configuration.maxArticles)
        checkRate()
    }


    function checkRate() 
    {
        if (intervalRate < 1 || intervalRate > 10080 || isNaN(intervalRate) || intervalRate === null)
            intervalRate = 60

        if (intervalRate >= 1 && intervalRate <= 60)
            minutesField.text = intervalRate.toString()

        else if (intervalRate > 60 && intervalRate <= 1440)
            hoursField.text = Math.floor(intervalRate / 60).toString()

        else if (intervalRate > 1440)
            daysField.text = Math.floor(intervalRate / 1440).toString()
    }

    ColumnLayout
    {
        anchors.fill: parent
        anchors.leftMargin: Kirigami.Units.gridUnit * 2
        anchors.rightMargin: Kirigami.Units.gridUnit * 2

        Button 
        {
            text: qsTr("⟳ Restore Defaults")
            Layout.alignment: Qt.AlignHCenter

            onClicked: 
            {
                plasmoid.configuration.refreshInterval = plasmoid.configuration.refreshIntervalDefault
                intervalRate = JSON.parse(plasmoid.configuration.refreshInterval)
                checkRate()
                plasmoid.configuration.maxArticles = plasmoid.configuration.maxArticlesDefault
                articleSlider.value = plasmoid.configuration.maxArticles
            }
        }

        Button 
        {
            text: qsTr("⟳ Erase All Bookmarks")
            Layout.alignment: Qt.AlignHCenter

            onClicked: 
            {
                plasmoid.configuration.bookmarks = plasmoid.configuration.bookmarksDefault
            }
        }

        
        Kirigami.FormLayout
        {
            Kirigami.Separator 
            {
                Kirigami.FormData.isSection: true
                Kirigami.FormData.label: qsTr("Refresh Interval")
            }

            ColumnLayout
            {
                Layout.preferredWidth: root.width * 0.8
                spacing: 10
                
                RowLayout
                {                    
                    TextField 
                    {
                        id: minutesField
                        placeholderText: qsTr("1-60")
                        inputMethodHints: Qt.ImhDigitsOnly
                        Layout.preferredWidth: 60

                        validator: IntValidator 
                        {
                            bottom: 1
                            top: 60
                        }

                        onTextChanged: 
                        {
                            const val = parseInt(text)

                            if (val === 0) minutesField.text = ""
                            if (val > 60 ) minutesField.text = "60"

                            if (!isNaN(val)) 
                            {
                                hoursField.text = ""
                                daysField.text = ""
                            }
                        }
                    }

                    Label { text: "minutes"}
                }



                RowLayout
                {
                    TextField 
                    {
                        id: hoursField
                        placeholderText: qsTr("1-24")
                        inputMethodHints: Qt.ImhDigitsOnly
                        Layout.preferredWidth: 60

                        validator: IntValidator 
                        {
                            bottom: 1
                            top: 24
                        }

                        onTextChanged: 
                        {
                            const val = parseInt(text)

                            if (val === 0) hoursField.text = ""
                            if (val > 24 ) hoursField.text = "24"

                            if (!isNaN(val)) 
                            {
                                minutesField.text = ""
                                daysField.text = ""
                            }
                        }
                    }

                    Label { text: "hours"}
                }



                RowLayout
                {
                    TextField 
                    {
                        id: daysField
                        placeholderText: qsTr("1-7")
                        inputMethodHints: Qt.ImhDigitsOnly
                        Layout.preferredWidth: 60

                        validator: IntValidator 
                        {
                            bottom: 1
                            top: 7
                        }

                        onTextChanged: 
                        {
                            const val = parseInt(text)

                            if (val === 0 ) daysField.text = ""
                            if (val > 7 ) daysField.text = "7"

                            if (!isNaN(val)) 
                            {
                                minutesField.text = ""
                                hoursField.text = ""
                            }
                        }
                    }

                    Label { text: "days"}
                }


                RowLayout
                {
                    Button 
                    {
                        text: qsTr("Update Interval")

                        onClicked:
                        {
                            if (minutesField.text !== "")
                                intervalRate = parseInt(minutesField.text)

                            else if (hoursField.text !== "")
                                intervalRate = parseInt(hoursField.text) * 60

                            else if (daysField.text !== "")
                                intervalRate = parseInt(daysField.text) * 1440

                            plasmoid.configuration.refreshInterval = JSON.stringify(intervalRate)
                            checkRate()
                        }
                    }
                }
            }
        }

        ColumnLayout
        {
            Layout.fillWidth: true 
            Layout.fillHeight: true

            Kirigami.FormLayout 
            {
                Layout.fillWidth: true

                Kirigami.Separator 
                {
                    Kirigami.FormData.isSection: true
                    Kirigami.FormData.label: qsTr("Max Articles Per Source")
                }

                Slider 
                {
                    id: articleSlider

                    Kirigami.FormData.label: ""
                    from: 10
                    to: 100
                    stepSize: 10
                    value: maxArticlesInt
                    Layout.preferredWidth: root.width * 0.8

                    onValueChanged: plasmoid.configuration.maxArticles = value
                }

                Label 
                {
                    text: qsTr("Selected: %1", articleSlider.value)
                    color: Kirigami.Theme.highlightColor
                    Layout.alignment: Qt.AlignHCenter
                }
            }
        }
    }
}