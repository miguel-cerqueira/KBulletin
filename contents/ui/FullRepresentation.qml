import QtQml
import QtQuick
import QtQuick.Layouts 
import QtQuick.Controls
    
import org.kde.plasma.plasmoid
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami

import "../app/app.js" as KBulletin
import "../app/rss.js" as RSSFetcher
import "../app/bookmarks.js" as BookmarkManager


Item
{
    id: root
    
    Layout.minimumWidth:    main.inPanel ? 600 : 450
    Layout.minimumHeight:   main.inPanel ? 600 : 450
    implicitWidth:          main.inPanel ? 600 : 450
    implicitHeight:         main.inPanel ? 600 : 450


    property  var activeSources: JSON.parse(plasmoid.configuration.sources).map(entry => entry.url).slice(0, 2)
    property  var allSources: JSON.parse(plasmoid.configuration.sources)
    property bool isCardExpanded: false                                              // card expansion
    property bool bookmarksDisplay: false                                           // bookmarks trigger
    property bool hasRemoved: false                                                // bookmark button management
    property  var sidebarSources: ({})
    property  int imagesLoading: 0
    property  int refreshMinutes: Math.max(1, JSON.parse(plasmoid.configuration.refreshInterval))


    property real cardsWidth: 
    {
        if (isCardExpanded) 
        {
            if (articlesArea.width > 1000) return (articlesArea.width / 5) - Kirigami.Units.largeSpacing
            if (articlesArea.width > 750)  return (articlesArea.width / 4) - Kirigami.Units.largeSpacing
            if (articlesArea.width > 450)  return (articlesArea.width / 3) - Kirigami.Units.mediumSpacing  
            if (articlesArea.width > 250)  return (articlesArea.width / 2) - Kirigami.Units.smallSpacing
            return articlesArea.width - Kirigami.Units.smallSpacing
        } 
        else 
        {
            if (articlesArea.width > 2000) return (articlesArea.width / 7) - Kirigami.Units.largeSpacing
            if (articlesArea.width > 1300) return (articlesArea.width / 6) - Kirigami.Units.largeSpacing
            if (articlesArea.width > 1000) return (articlesArea.width / 5) - Kirigami.Units.largeSpacing
            if (articlesArea.width > 700)  return (articlesArea.width / 4) - Kirigami.Units.largeSpacing
            if (articlesArea.width > 400)  return (articlesArea.width / 3) - Kirigami.Units.largeSpacing
            return (articlesArea.width / 2) - Kirigami.Units.largeSpacing
        }
    }


    QtObject 
    {
        id: expandedCard

        property string title: ""
        property string description: ""
        property string thumbnail: ""
        property string link: ""
        property string pubDate: ""
        property string author: ""
        property string source: ""
    }


    ListModel { id: filteredSourcesModel }
    ListModel { id: articlesModel }
    ListModel { id: bookmarksModel }


    Component.onCompleted: 
    {
        KBulletin.fetchSources(activeSources)
        KBulletin.filterSources()

        // Welcome Card
        expandedCard.title       = "Welcome!"
        expandedCard.description = "<p> KBulletin allows you to customize your feed to your liking through the use of the configuration menu, accessed by right-clicking the widget. </p> \n" 
                                 + "<p> Although it is optimized to work with the default sources, any written broadcast media is supported. Videos, podcasts, and comic strips, are unsupported at this time. </p> \n"
                                 + "<p> You can expand a card by selecting it, and close it by clicking the image or the small button on the bottom right. You can also increase the window's size by dragging the corners. </p>"
                                 + "<p> </p>"
                                 + "<p> Read responsibly! :) </p>"
        expandedCard.thumbnail   = Qt.resolvedUrl("../assets/rss.png")
        expandedCard.link        = "https://github.com/miguel-cerqueira/KBulletin/"
        expandedCard.pubDate     = new Date()
        expandedCard.author      = ""
        expandedCard.source      = "KBulletin"
        isCardExpanded = true

        // Sidebar Setup
        sidebarSources = {}
        for (let i = 0; i < allSources.length; i++) 
            sidebarSources[allSources[i].source] = allSources[i].url
    }


    Connections 
    {
        target: plasmoid.configuration

        onSourcesChanged:
        {
            allSources = JSON.parse(plasmoid.configuration.sources)

            if (activeSources.length === allSources.length)         // accounting for pressing defaults button
            {
                var sources = JSON.parse(plasmoid.configuration.sources).map(entry => entry.url)

                if (sources.length > 3)
                    activeSources = sources.slice(0, 2)
            }

            sidebarSources = {}
            for (let i = 0; i < allSources.length; i++) 
                sidebarSources[allSources[i].source] = allSources[i].url

            KBulletin.filterSources()
        }

        onTopicsChanged: KBulletin.filterSources()

        onRefreshIntervalChanged: refreshMinutes = JSON.parse(plasmoid.configuration.refreshInterval)
    }


    Timer 
    {
        id: refreshTimer

        interval: refreshMinutes * 60 * 1000                 /* So, apparently, interval measures in milliseconds */
        repeat: true                                         /* After racking up 3 digits in bandwitdh charges,   */
        running: true                                        /*   it is now fixed at minutes. Oops.               */
        onTriggered: KBulletin.fetchSources(activeSources) 
    }


// ----------------------------------------------------------------- UI ------------------------------------------------------------------
    RowLayout
    {
        id: window
        anchors.fill: parent

        // Side Area
        ColumnLayout
        {
            Layout.preferredWidth: 75
            Layout.minimumWidth: 75
            Layout.maximumWidth: 200


            // Loading Indicator
            Rectangle 
            {
                anchors.fill: parent
                color: "transparent"
                visible: root.imagesLoading > 0
                z: 9999

                MouseArea 
                {
                    anchors.fill: parent
                    onClicked: {}
                }   

                PlasmaComponents.BusyIndicator 
                {
                    anchors.centerIn: parent
                    running: true
                    visible: true
                }
            }

            ColumnLayout
            {
                id: sideArea    
                
                visible: imagesLoading === 0
                Layout.fillWidth: true
                Layout.fillHeight: true

                property bool bookmarksVisible: false
                property bool topicsVisible: false
                property int selectedTopicIndex: -1
                property int selectedSourceIndex: -1


                // Topics Button
                PlasmaComponents.Button
                {
                    id: topicsButton

                    property var triangle: true

                    text: "Topics ▽"
                    flat: true
                    padding: 3

                    onClicked: 
                    {
                        sideArea.topicsVisible = !sideArea.topicsVisible
                        
                        if (triangle == false)
                            text = "Topics ▽"

                        if (triangle == true)
                            text = "Topics ▼"

                        triangle = !triangle
                    }

                    background: Rectangle
                    {
                        color: sideArea.topicsVisible
                            ? Kirigami.Theme.highlightColor
                            : (topicsButton.hovered ? Kirigami.Theme.highlightColor : "transparent")
                        radius: 4
                    }

                    contentItem: Text
                    {
                        text: topicsButton.text
                        anchors.centerIn: parent
                        color: Kirigami.Theme.textColor
                        wrapMode: Text.Wrap
                        elide: Text.ElideRight
                    }
                }


                ListView
                {
                    id: topicsList

                    implicitHeight: contentHeight
                    Layout.fillWidth: true
                    clip: true
                    visible: sideArea.topicsVisible
                    Layout.maximumWidth: sideArea.width
                    boundsBehavior: Flickable.DragAndOvershootBounds

                    model: JSON.parse(plasmoid.configuration.topics)


                    delegate: Rectangle
                    {
                        id: topicDelegate

                        width: ListView.view.width
                        height: label.implicitHeight + 6
                        color: hovered ? Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.2)
                                       : "transparent"
                        radius: 4

                        property bool hovered: false

                        MouseArea
                        {
                            anchors.fill: parent
                            hoverEnabled: true
                            onEntered: topicDelegate.hovered = true
                            onExited: topicDelegate.hovered = false
                            onClicked:
                            {
                                if (sideArea.selectedTopicIndex === index)
                                    sideArea.selectedTopicIndex = -1
                                else
                                    sideArea.selectedTopicIndex = index
                                KBulletin.filterSources()
                            }
                        }


                        Row
                        {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 6
                            padding: 6

                            // ▶ Indicator
                            Text
                            {
                                visible: index === sideArea.selectedTopicIndex
                                text: "▶"
                                color: Kirigami.Theme.highlightColor
                                font.pointSize: 9
                            }

                            // Topic label
                            PlasmaComponents.Label
                            {
                                id: label

                                text: modelData
                                wrapMode: root.width < 550
                                    ? Text.Wrap
                                    : Text.WrapAnywhere
                                elide: Text.ElideRight
                                font.pointSize: 9
                                color: Kirigami.Theme.textColor
                            }
                        }
                    }
                }

                Item { height: 1 }


                Item { height: 1 }


                PlasmaComponents.Label
                {
                    text: "Sources:"
                    Layout.fillWidth: true
                    padding: 3
                }

                RowLayout 
                {
                    spacing: 3

                    PlasmaComponents.Button
                    {
                        text: "Clear"

                        onClicked: 
                        {
                            search.text = ""
                            activeSources = []
                            sideArea.selectedTopicIndex = -1
                            KBulletin.filterSources()
                        }
                    }

                    PlasmaComponents.Button 
                    {
                        id: refresh

                        icon.name: "view-refresh"
                        enabled: imagesLoading === 0 || bookmarksDisplay === true                        

                        onClicked: 
                        {
                            search.text = ""
                            KBulletin.fetchSources(activeSources)
                        }
                    }
                }

                // Sources Display
                ListView
                {
                    id: sourcesList

                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    clip: true
                    Layout.maximumWidth: sideArea.width
                    boundsBehavior: Flickable.DragAndOvershootBounds
                    topMargin: 5
                    cacheBuffer: 1000

                    model: filteredSourcesModel

                    delegate: Rectangle
                    {
                        id: sourceDelegate

                        width: ListView.view.width
                        height: label.implicitHeight + 6
                        color: hovered ? Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.2)
                                       : "transparent"
                        radius: 4

                        property bool hovered: false

                        MouseArea
                        {
                            anchors.fill: parent
                            hoverEnabled: true
                            onEntered: sourceDelegate.hovered = true
                            onExited: sourceDelegate.hovered = false

                            onClicked:
                            {                                
                                let url = sidebarSources[model.source] || ""
                                if (!url) return

                                let idx = activeSources.indexOf(url)
                                if (idx !== -1)
                                    activeSources.splice(idx, 1)
                                else
                                    activeSources.push(url)

                                KBulletin.filterSources()
                            }
                        }


                        ToolTip 
                        {
                            visible: sourceDelegate.hovered
                            text: model.source
                            delay: 300
                        }


                        Row
                        {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 6
                            padding: 6


                            
                            // Active Indicator
                            Text
                            {
                                text: "➔"
                                color: Kirigami.Theme.highlightColor
                                font.pointSize: 9

                                visible: 
                                {
                                    let url = sidebarSources[model.source] || ""
                                    return activeSources.indexOf(url) !== -1
                                }
                            }

                            // Favicon
                            Image
                            {
                                width: 20
                                height: 20

                                property bool counted: false
                                property string cachedDomain: 
                                {
                                    let url = model.url || ""
                                    if (!/^https?:\/\//i.test(url)) url = "https://" + url
                                    
                                    let domainMatch = url.match(/^https?:\/\/(?:feeds\.|rss\.)?([^\/]+)/i)
                                    return domainMatch ? domainMatch[1] : ""
                                }
                                
                                sourceSize.width: 32
                                sourceSize.height: 32

                                source: cachedDomain.length > 0 
                                        ? "https://icons.duckduckgo.com/ip3/" + cachedDomain + ".ico"
                                        : Qt.resolvedUrl("../assets/newspaper.png")

                                onStatusChanged: 
                                { 
                                    if (status === Image.Error)
                                        source = Qt.resolvedUrl("../assets/newspaper.png")
                                }

                                fillMode: Image.PreserveAspectFit
                                smooth: true
                                asynchronous: true
                                cache: true
                                mipmap: true
                            }

                            // Topic label
                            Text
                            {
                                id: label

                                text: model.source
                                wrapMode: Text.Wrap
                                font.pointSize: 9

                                color: model.topic === (sideArea.selectedTopicIndex >= 0
                                        ? topicsList.model[sideArea.selectedTopicIndex]
                                        : null)
                                    || sideArea.selectedTopicIndex === -1
                                        ? Kirigami.Theme.textColor
                                        : Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.4)
                            }
                        }
                    }
                }
            }


            // Scrolling Helpers for broken mouse wheels
            ColumnLayout
            {
                Layout.fillWidth: true
                anchors.bottom: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter

                Kirigami.Icon 
                {
                    id: scrollArrowUp
                    source: "go-up"
                    width: 20
                    height: 20

                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top
                    anchors.topMargin: 2
                    anchors.bottomMargin: 2

                    visible: scrollArea.contentY > 0 && imagesLoading === 0
                    z: 999

                    MouseArea 
                    {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true

                        onClicked: 
                        {
                            var scrollStep = 300
                            scrollArea.contentY = Math.max(scrollArea.contentY - scrollStep, 0)
                        }
                    }
                }

                Kirigami.Icon 
                {
                    id: scrollArrowDown
                    source: "go-down"
                    width: 20
                    height: 20

                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.topMargin: 2
                    anchors.bottomMargin: 2

                    visible: scrollArea.contentY + scrollArea.height < scrollArea.contentHeight && imagesLoading === 0
                    z: 999

                    MouseArea 
                    {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true

                        onClicked: 
                        {
                            var scrollStep = 300
                            scrollArea.contentY = Math.min(scrollArea.contentY + scrollStep, scrollArea.contentHeight - scrollArea.height)
                        }
                    }
                }

                Item { height: 5 }
            }
        }




        // ------------------------------------------------ Main Content -------------------------------------------------------
        ColumnLayout
        {
            id: mainArea

            Layout.fillHeight: true
            Layout.fillWidth: true


            // Top Bar
            RowLayout
            {
                id: topBar

                width: mainArea.width
                height: Kirigami.Units.gridUnit * 2.2


                PlasmaComponents.TextField
                {
                    id: search

                    placeholderText: "Search feed…"
                    enabled: imagesLoading === 0
                    Layout.fillWidth: true
                    Layout.minimumWidth: 50
                }

                Item { Layout.fillWidth: true }

                PlasmaComponents.Button
                {
                    id: bookmarkButton
                    
                    checkable: true
                    Layout.preferredHeight: 30
                    ToolTip.delay: 500
                    ToolTip.text: "Replaces feed with your bookmarked articles"
                    ToolTip.visible: hovered

                    enabled: imagesLoading === 0 || imagesLoading === 0 && bookmarksDisplay === true

                    contentItem: Row
                    {
                        anchors.centerIn: parent
                        spacing: Kirigami.Units.smallSpacing
                        
                        Image
                        {
                            source: Qt.resolvedUrl("../assets/newspaper.png")
                            width: 19
                            height: 19
                        }

                        Text
                        {
                            text: root.width > 600
                                ? "Bookmarks ★"
                                : "★"
                            color: Kirigami.Theme.textColor
                        }
                    }

                    onClicked:
                    {
                        isCardExpanded = false

                        if (bookmarksDisplay == false)
                        {
                            color: Kirigami.Theme.highlightColor
                            refresh.enabled = false
                            BookmarkManager.loadBookmarks()
                        }
                        if (bookmarksDisplay)
                            refresh.enabled = true

                        bookmarksDisplay = !bookmarksDisplay
                    }
                }


                // ----------------------------- FEED CONFIG -----------------------------------
                PlasmaComponents.Button
                {
                    id: feedDisplay
                    Layout.preferredHeight: 30

                    ToolTip.delay: 500
                    ToolTip.text: "Feed Options"
                    ToolTip.visible: hovered

                    contentItem: Row
                    {
                        anchors.centerIn: parent
                        spacing: Kirigami.Units.smallSpacing
                        
                        Text
                        {
                            text: root.width > 600
                                ? "Feed Options ⇅"
                                : "⇅"
                            color: Kirigami.Theme.textColor
                            Layout.fillWidth: true
                        }
                    }

                    onClicked: configDialog.open()
                }


                Kirigami.Dialog 
                {
                    id: configDialog
                    title: "Feed Options"
                    modal: true
                    standardButtons: Dialog.Ok | Dialog.Cancel
                    parent: root
                    anchors.centerIn: parent
                    padding: 3

                    onAccepted: 
                    {
                        console.log("Settings saved")
                    }

                    ScrollView
                    {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true

                        ColumnLayout
                        {
                            spacing: Kirigami.Units.mediumSpacing

                            Kirigami.Separator
                            {
                                Layout.fillWidth: true
                                height: 1
                            }

                            Label
                            {
                                text: "Word Ban"
                            }

                            Text 
                            {
                                text: " If any inserted word is found, the article will not enter your feed. \n You can remove banned words from the widget menu."
                                color: Kirigami.Theme.textColor
                            }

                            Item { height: 5 }

                            TextField 
                            {
                                id: wordBanField

                                placeholderText: "Ex: NHL, Trump, Bitcoin"
                                Layout.fillWidth: true
                            }

                            Item { height: 5 }

                            Kirigami.Separator
                            {
                                Layout.fillWidth: true
                                height: 1
                            }

                            Item { height: 5 }

                            Label
                            {
                                text: "Max articles per source"
                            }

                            Text 
                            {
                                text: " 0 for no limit."
                                color: Kirigami.Theme.textColor
                            }

                            Slider 
                            {
                                id: maxArticlesSlider

                                from: 0
                                to: 100
                                stepSize: 10
                                value: maxArticlesInt
                                Layout.preferredWidth: root.width * 0.8

                                onValueChanged: indicatorForSlider.text = "Selected: " + value
                            }

                            Text 
                            {
                                id: indicatorForSlider

                                text: ""
                                color: Kirigami.Theme.highlightColor
                            }

                            Item { height: 5 }
                        }
                    }

                    footer: Kirigami.ActionToolBar 
                    {
                        actions: 
                        [
                            Kirigami.Action 
                            {
                                icon.name: "dialog-ok-apply"
                                text: i18n("Apply")

                                onTriggered: 
                                {                                        
                                    var newWord = wordBanField.text.trim()
                                    var existing = plasmoid.configuration.banned ? plasmoid.configuration.banned.trim() : ""

                                    if (newWord.length > 0) 
                                    {
                                        if (existing.length > 0) 
                                            plasmoid.configuration.banned = existing + ", " + newWord
                                        else 
                                            plasmoid.configuration.banned = newWord
                                    }

                                    var newMaxArticles = maxArticlesSlider.value
                                    plasmoid.configuration.maxArticles = JSON.stringify(newMaxArticles) // Key change: stringify the value

                                    wordBanField.text = ""
                                    maxArticlesSlider.value = plasmoid.configuration.maxArticles

                                    configDialog.close()
                                    articlesModel.clear() 
                                }
                            },
                            Kirigami.Action 
                            {
                                icon.name: "dialog-cancel"
                                text: i18n("Cancel")
                                Layout.alignment: Qt.AlignRight
                                onTriggered: configDialog.close()
                            }
                        ]
                    }
                }
            }

            
            // ------------------------------------------------ Articles Area -------------------------------------------------------
            RowLayout
            {
                id: cardsRow
                
                Layout.fillWidth: true
                Layout.fillHeight: true


                // isCardExpanded Card
                ColumnLayout
                {
                    visible: isCardExpanded

                    width: isCardExpanded ? root.width > 1500
                                            ? 500
                                            : root.width >= 750
                                                ? 400
                                                : 300
                                            : 300
                    Layout.preferredWidth: width
                    Layout.maximumWidth: width
                    Layout.minimumWidth: 0
                    Layout.fillHeight: true


                    Kirigami.Card
                    {
                        id: clickedCard

                        onClicked: isCardExpanded = false
                        
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.maximumHeight: cardsRow.height * 0.85

                        actions:
                        [
                            Kirigami.Action
                            {
                                text: qsTr("Bookmark")
                                icon.name: "action-rss_tag"
                                visible: bookmarksDisplay == false && expandedCard.title !== "Welcome!" && expandedCard.title !== "Unsupported Feed"

                                onTriggered: BookmarkManager.saveBookmark(expandedCard)
                            },
                            Kirigami.Action
                            {
                                text: qsTr("Remove Bookmark")
                                icon.name: "albumfolder-user-trash"
                                visible: bookmarksDisplay == true && hasRemoved == false

                                onTriggered: 
                                {
                                    BookmarkManager.removeBookmark(expandedCard)
                                    hasRemoved = true
                                }
                            },
                            Kirigami.Action
                            {
                                text: qsTr("Revert")
                                icon.name: "document-revert-symbolic-rtl"
                                visible: bookmarksDisplay == true && hasRemoved == true

                                onTriggered: 
                                {
                                    BookmarkManager.saveBookmark(expandedCard)
                                    hasRemoved = false
                                }
                            },
                            Kirigami.Action 
                            {
                                text: expandedCard.title !== "Welcome!" ? qsTr("Open Article") : qsTr("Visit our Homepage")
                                icon.name: expandedCard.title !== "Welcome!" ? "plasma-browser-integration" : "computer-fail-symbolic"

                                onTriggered: Qt.openUrlExternally(expandedCard.link)
                            }
                        ]


                        banner
                        {
                            source: expandedCard.thumbnail  || Qt.resolvedUrl("../assets/rss.png")
                            fillMode: Image.PreserveAspectCrop

                            title: expandedCard.author || ""
                            titleAlignment: Qt.AlignLeft | Qt.AlignBottom
                            titleLevel: 2
                                                        
                            implicitHeight: clickedCard.height * 0.35                          
                        }


                        contentItem: ScrollView
                        {
                            id: descriptionScroll
                            contentWidth: availableWidth            // Prevents horizontal scrolling (ugly, eww)

                            ColumnLayout 
                            {
                                spacing: Kirigami.Units.smallSpacing
                                width: descriptionScroll.availableWidth

                                Label
                                {
                                    text: expandedCard.title || "No title"
                                    maximumLineCount: 3
                                    
                                    padding: 4
                                    wrapMode: Text.WordWrap
                                    font.bold: true
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                }

                                Kirigami.Separator
                                {
                                    height: 2
                                    Layout.fillWidth: true
                                }

                                TextEdit 
                                {
                                    text: expandedCard.description + "<p>━━━━━━━━━\n</p>" + Qt.formatDateTime(expandedCard.pubDate, "hh:mm, MMMM d, yyyy") + "<p></p>" + expandedCard.source || "No description available."

                                    wrapMode: TextEdit.Wrap
                                    textFormat: TextEdit.RichText 
                                    color: Kirigami.Theme.textColor
                                    font.pointSize: 10
                                    padding: 1
                                    selectionColor: Kirigami.Theme.highlightColor
                                    selectedTextColor: Kirigami.Theme.highlightedTextColor

                                    readOnly: true
                                    selectByMouse: true
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                }
                            }
                        }
                    }

                    Button
                    {
                        text: ">"
                        onClicked: isCardExpanded = !isCardExpanded

                        Layout.preferredWidth: 30
                        Layout.preferredHeight: 30
                        Layout.alignment: Qt.AlignBottom | Qt.AlignRight
                    }
                }



                // Cards Delegate
                ColumnLayout
                {
                    id: articlesArea

                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    Flickable
                    {
                        id: scrollArea

                        clip: true
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        flickableDirection: Flickable.VerticalFlick

                        contentWidth: cards.width
                        contentHeight: cards.implicitHeight

                        MouseArea 
                        {
                            anchors.fill: parent
                            hoverEnabled: true
                            acceptedButtons: Qt.NoButton

                            onWheel: (wheelEvent) => 
                            {
                                var speed = 0.3
                                var newY = scrollArea.contentY - wheelEvent.angleDelta.y * speed
                                var maxY = scrollArea.contentHeight - scrollArea.height

                                scrollArea.contentY = Math.max(0, Math.min(newY, maxY))

                                wheelEvent.accepted = true
                            }
                        }


                        Flow    
                        {
                            id: cards
                            
                            width: articlesArea.width
                            spacing: Kirigami.Units.largeSpacing

                            Repeater
                            {
                                model: !bookmarksDisplay ? articlesModel : bookmarksModel

                                delegate: Kirigami.Card
                                {
                                    id: card

                                    visible: search.text.length < 3 || model.title.toLowerCase().includes(search.text.toLowerCase()) // Search Bar
                                    width: root.cardsWidth
                                    hoverEnabled: true

                                    ToolTip 
                                    {
                                        text: model.title
                                        delay: 500
                                    }
                                         

                                    contentItem: ColumnLayout
                                    {
                                        spacing: Kirigami.Units.smallSpacing

                                        MouseArea 
                                        {
                                            z: 1
                                            hoverEnabled: true
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor

                                            onClicked: 
                                            {
                                                if (isCardExpanded == false)
                                                     isCardExpanded = !isCardExpanded 

                                                if (hasRemoved)
                                                     hasRemoved = false

                                                expandedCard.title       = model.title
                                                expandedCard.description = model.description
                                                expandedCard.thumbnail   = model.thumbnail
                                                expandedCard.link        = model.link
                                                expandedCard.pubDate     = model.pubDate
                                                expandedCard.author      = model.author
                                                expandedCard.source      = model.source
                                            }
                                        }

                                        Rectangle 
                                        {
                                            Layout.maximumWidth: parent.width
                                            Layout.minimumHeight: 100
                                            Layout.maximumHeight: 100
                                            Layout.fillWidth: true
                                            radius: 4 
                                            clip: true

                                            Image 
                                            {
                                                id: thumbnailCards
                                                source: model.thumbnail !== ""
                                                        ? model.thumbnail
                                                        : Qt.resolvedUrl("../assets/rss.png")

                                                anchors.fill: parent
                                                fillMode: Image.PreserveAspectCrop
                                                cache: true
                                                smooth: false
                                                asynchronous: true

                                                sourceSize.width: 200
                                                sourceSize.height: 200

                                                Timer 
                                                {
                                                    id: loadTimer
                                                    interval: 10000    
                                                    repeat: false
                                                    onTriggered: 
                                                    {
                                                        if (thumbnailCards.counted) 
                                                        {
                                                            root.imagesLoading = Math.max(0, root.imagesLoading - 1)
                                                            thumbnailCards.counted = false
                                                        }
                                                        loadingOverlay.visible = false
                                                        thumbnailCards.source = Qt.resolvedUrl("../assets/rss.png")
                                                    }
                                                }


                                                property bool counted: false

                                                onStatusChanged: 
                                                {
                                                    if (status === Image.Loading && !counted) 
                                                    {
                                                        root.imagesLoading += 1
                                                        counted = true
                                                        loadTimer.start()
                                                    }

                                                    if ((status === Image.Ready || status === Image.Error) && counted) 
                                                    {
                                                        root.imagesLoading = Math.max(0, root.imagesLoading - 1)
                                                        counted = false
                                                        loadTimer.stop()
                                                    }

                                                    if (status === Image.Ready)
                                                        loadingOverlay.visible = false

                                                    else if (status === Image.Error)
                                                    {
                                                        loadingOverlay.visible = false
                                                        source: Qt.resolvedUrl("../assets/rss.png")
                                                    }
                                                        
                                                    else loadingOverlay.visible = true
                                                }


                                                Rectangle 
                                                {
                                                    id: loadingOverlay
                                                    anchors.fill: parent
                                                    color: "black"
                                                    visible: thumbnailCards.status !== Image.Ready
                                                    opacity: 0.9

                                                    Text 
                                                    {
                                                        anchors.centerIn: parent
                                                        text: (thumbnailCards.status === Image.Error)
                                                            ? "Image Error"
                                                            : "Loading..."
                                                        color: Kirigami.Theme.textColor
                                                        z: 3
                                                    }
                                                }
                                            }

                                            // FAVICON
                                            Image 
                                            {
                                                id: faviconImage
                                                width: 20
                                                height: 20
                                                anchors.top: parent.top
                                                anchors.right: parent.right
                                                z: 2

                                                property bool counted: false
                                                property string domainCache: ""
                                                
                                                // Cache domain extraction
                                                Component.onCompleted: 
                                                {
                                                    if (model.source && model.source.length > 0)
                                                        domainCache = model.source.replace(/^https?:\/\//, "").replace(/\/.*$/, "")
                                                }
                                                
                                                source: domainCache.length > 0 
                                                    ? "https://icons.duckduckgo.com/ip3/" + domainCache + ".ico"
                                                    : ""

                                                sourceSize.width: 32
                                                sourceSize.height: 32
                                                
                                                fillMode: Image.PreserveAspectFit
                                                smooth: true
                                                asynchronous: true
                                                cache: true

                                                onStatusChanged: 
                                                {
                                                    if (status === Image.Loading && !counted) 
                                                    {
                                                        root.imagesLoading += 1
                                                        counted = true
                                                    }
                                                    else if ((status === Image.Ready || status === Image.Error) && counted) 
                                                    {
                                                        root.imagesLoading = Math.max(0, root.imagesLoading - 1)
                                                        counted = false
                                                        
                                                        if (status === Image.Error) 
                                                            source = ""
                                                    }
                                                }
                                            }
                                        }

                                        Label
                                        {
                                            property int maxChars: articlesArea.width > 1000
                                                                    ? 120
                                                                    : articlesArea.width > 800
                                                                        ? 100
                                                                        : articlesArea.width > 600
                                                                            ? 100
                                                                            : articlesArea.width > 400
                                                                                ? 60
                                                                                : 60

                                            text: model.title.length > maxChars
                                                    ? model.title.substring(0, maxChars - 1) + "…"
                                                    : model.title
                                            maximumLineCount: articlesArea.width > 600
                                                ? 3
                                                : articlesArea.width > 400
                                                    ? 4
                                                    : 6
                                            Layout.minimumHeight: articlesArea.width > 600
                                                ? 60
                                                : articlesArea.width > 400
                                                    ? 80
                                                    : 100
                                            Layout.maximumHeight: articlesArea.width > 600
                                                ? 60
                                                : articlesArea.width > 400
                                                    ? 80
                                                    : 100

                                            Layout.maximumWidth: parent.width

                                            wrapMode: Text.WordWrap
                                            font.bold: true
                                            Layout.fillWidth: true
                                            Layout.fillHeight: true
                                            horizontalAlignment: Text.AlignLeft
                                            clip: true
                                            elide: Text.ElideRight
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}