import QtQuick
import QtQuick.Layouts

import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami


Item 
{
    id: compactRep

    property var logo: Qt.resolvedUrl("../assets/rss.png")

    RowLayout 
    {
        anchors.fill: parent
        
        Kirigami.Icon 
        {
            Layout.fillWidth: true
            Layout.fillHeight: true
            source: logo
            smooth: true

            MouseArea 
            {
                id: mouseArea
                
                anchors.fill: parent
                hoverEnabled: true
                
                onClicked: 
                {
                    main.expanded = !main.expanded
                }
            }
        }
    }
}