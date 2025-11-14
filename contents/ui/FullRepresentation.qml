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

    Layout.minimumWidth:  800
    Layout.minimumHeight: 600
    implicitWidth:        800
    implicitHeight:       600


    property  var allSources: JSON.parse(plasmoid.configuration.sources)
    property  var activeSources: JSON.parse(plasmoid.configuration.sources).map(entry => entry.url).slice(0, 2)  // init to 2 sources for faster setup
    property  int refreshMinutes: Math.max(1, JSON.parse(plasmoid.configuration.refreshInterval))
    property  var sidebarSources: ({})
    property bool isCardExpanded: false                                              // for card expansion
    property bool bookmarksDisplay: false                                           // bookmarks trigger
    property bool hasRemoved: false                                                // for bookmark button management
    property  int imagesLoading: 0


    property real cardsWidth:
    {
        var spacing     = isCardExpanded
                                ? Kirigami.Units.mediumSpacing
                                : Kirigami.Units.largeSpacing
        var targetWidth = articlesArea.width < 2000
                                ? 200
                                : 300
        var base    = articlesArea.width
        var columns = Math.max(2, Math.floor(base / targetWidth))

        return (base - columns * spacing) / columns
    }


    QtObject
    {
        id: expandedCard

        property string title:       "Welcome!"
        property string description: "<p>KBulletin allows you to customize your feed to your liking through the use of the configuration menu, accessible by right-clicking the widget.</p> <p>It is optimized to work with the default sources, but most written news media is supported. Videos, podcasts, and comic strips are unsupported at this time.</p> <p>To get started, select your preferred sources and press the ⟳ button. You also can expand a news card by selecting it, and close it by either clicking its thumbnail or the small > button on the bottom right. In panel mode, you can also quickly increase the window's size by dragging its corners.</p> <p>Read Responsibly! :)</p>"
        property string thumbnail:   Qt.resolvedUrl("../assets/rss.png")
        property string link:        "https://github.com/miguel-cerqueira/KBulletin/"
        property string pubDate:     new Date()
        property string author:      ""
        property string source:      ""
    }


    ListModel { id: filteredSourcesModel }
    ListModel { id: articlesModel }
    ListModel { id: bookmarksModel }


    Component.onCompleted:
    {
        isCardExpanded = true

        KBulletin.fetchSources(activeSources)
        KBulletin.filterSources()

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

            if (activeSources.length === allSources.length)         // Accounting for pressing defaults button
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

        interval: refreshMinutes * 60 * 1000
        repeat: true
        running: true

        onTriggered:
        {
            search.text = ""
            articlesModel.clear()
            imagesLoading = 0

            KBulletin.fetchSources(activeSources)
        }
    }


// ----------------------------------------------------------------- UI ------------------------------------------------------------------
    RowLayout
    {
        id: window
        anchors.fill: parent

        // Side Area
        ColumnLayout
        {
            Layout.preferredWidth: 150
            Layout.minimumWidth: 150
            Layout.maximumWidth: 185


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
                property int  selectedTopicIndex: -1
                property int  selectedSourceIndex: -1


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
                        text: "Clear List"

                        onClicked:
                        {
                            search.text = ""
                            activeSources = []
                            sideArea.selectedTopicIndex = -1
                            KBulletin.filterSources()
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

                    MouseArea
                    {
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.NoButton

                        onWheel: (wheelEvent) =>
                        {
                            var speed = 0.3
                            var newY = sourcesList.contentY - wheelEvent.angleDelta.y * speed
                            var maxY = sourcesList.contentHeight - sourcesList.height

                            sourcesList.contentY = Math.max(0, Math.min(newY, maxY))

                            wheelEvent.accepted = true
                        }
                    }


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

                                if (!url)
                                        return

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

                                property bool   counted: false
                                property string cachedDomain:
                                {
                                    //  <3  ->  https://duckduckgo.com/duckduckgo-help-pages/company/donations

                                    let url = model.url || ""

                                    if (!/^https?:\/\//i.test(url))
                                        url = "https://" + url

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
                                    if (status == Image.Error || status == Image.Null)
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

                    visible: scrollArea.contentY > 0 && imagesLoading == 0
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

                    visible: scrollArea.contentY + scrollArea.height < scrollArea.contentHeight && imagesLoading == 0
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
            Layout.alignment: Qt.AlignLeft


            // Top Bar
            RowLayout
            {
                id: topBar

                width: mainArea.width
                height: Kirigami.Units.gridUnit * 4

                property bool processing: false

                PlasmaComponents.Button
                {
                    id: refresh

                    icon.name: "view-refresh"
                    // enabled: imagesLoading == 0 ? true : false

                    Timer
                    {
                        // Preventing click spam breaking UI

                        id: buttonLock
                        interval: 2500
                        repeat: false

                        onTriggered: refresh.enabled = true
                    }

                    Timer
                    {
                        // Might be necessary if user decides to use every source at once, or due to race condition

                        id: failsafeTimer
                        interval: 15000
                        repeat: false

                        onTriggered:
                        {
                                if (imagesLoading == 0)
                                  return

                                failsafe.enabled = true
                                failsafe.visible = true
                        }
                    }

                    onClicked:
                    {
                        refresh.enabled = false
                        search.text = ""
                        root.imagesLoading = 0

                        articlesModel.clear()
                        KBulletin.fetchSources(activeSources)
                        buttonLock.start()
                        failsafeTimer.start()
                    }
                }


                PlasmaComponents.Button
                {
                    id: failsafe

                    ToolTip.delay: 500
                    ToolTip.text: "Restore app if its stuck loading"
                    ToolTip.visible: hovered
                    Layout.preferredHeight: 30

                    enabled: false
                    visible: false

                    contentItem: Row
                    {
                        anchors.centerIn: parent
                        spacing: Kirigami.Units.smallSpacing

                        Text
                        {
                            text: "Reset App"
                            color: Kirigami.Theme.textColor
                        }
                    }

                    onClicked:
                    {
                        articlesModel.clear()
                        root.imagesLoading = 0
                        refresh.enabled = true
                        activeSources = JSON.parse(plasmoid.configuration.sources).map(entry => entry.url).slice(0, 2)

                        failsafe.enabled = false
                        failsafe.visible = false
                    }
                }


                PlasmaComponents.TextField
                {
                    id: search

                    placeholderText: "Search feed…"
                    enabled: imagesLoading == 0
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

                    enabled: imagesLoading == 0 || imagesLoading == 0 && bookmarksDisplay == true

                    contentItem: Row
                    {
                        anchors.centerIn: parent
                        spacing: Kirigami.Units.smallSpacing

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

                    width: articlesArea.width > 2000
                              ? cardsRow.width * 0.3
                              : cardsRow.width * 0.4
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
                                visible: bookmarksDisplay == false && expandedCard.title !== "Welcome!"

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
                                text: expandedCard.title !== "Welcome!"
                                        ? qsTr("Open Article")
                                        : qsTr("Visit our Homepage")
                                icon.name: expandedCard.title !== "Welcome!"
                                        ? "plasma-browser-integration"
                                        : "computer-fail-symbolic"

                                onTriggered: Qt.openUrlExternally(expandedCard.link)
                            }
                        ]


                        banner
                        {
                            source: expandedCard.thumbnail  || Qt.resolvedUrl("../assets/rss.png")
                            fillMode: Image.PreserveAspectFit

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
                                    width:   root.cardsWidth
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
                                                expandedCard.title       = ""
                                                expandedCard.description = ""
                                                expandedCard.thumbnail   = ""
                                                expandedCard.link        = ""
                                                expandedCard.pubDate     = ""
                                                expandedCard.author      = ""
                                                expandedCard.source      = ""


                                                if (isCardExpanded == false)
                                                     isCardExpanded = true

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
                                            Layout.maximumWidth:  parent.width
                                            Layout.minimumHeight: cardsRow.height * 0.22
                                            Layout.maximumHeight: 400

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
                                                cache: false
                                                smooth: false
                                                asynchronous: true

                                                sourceSize.width: 200
                                                sourceSize.height: 200

                                                Timer
                                                {
                                                    id: imgTimer
                                                    interval: 10000
                                                    repeat: false

                                                    onTriggered:
                                                    {
                                                        if (status !== Image.Ready)
                                                        {
                                                            source = ""
                                                            source = "../assets/rss.png"
                                                            root.imagesLoading -= 1
                                                        }
                                                    }
                                                }

                                                onStatusChanged:
                                                {
                                                    imgTimer.start()

                                                    if (status !== Image.Ready)
                                                    {
                                                        root.imagesLoading += 1
                                                        loadingOverlay.visible = true
                                                    }
                                                    else
                                                    {
                                                        root.imagesLoading -= 1
                                                        loadingOverlay.visible = false
                                                        imgTimer.stop()
                                                    }
                                                }

                                                Rectangle
                                                {
                                                    id: loadingOverlay
                                                    anchors.fill: parent
                                                    color: "black"
                                                    visible: false
                                                    opacity: 0.9

                                                    Text
                                                    {
                                                        anchors.centerIn: parent
                                                        text: (thumbnailCards.status === Image.Null)
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

                                                property string domainCache: ""

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
                                                smooth: false
                                                cache: false
                                                asynchronous: true
                                            }
                                        }

                                        Label
                                        {
                                            maximumLineCount: articlesArea.width > 1000
                                                    ? 4
                                                    : 3

                                            Layout.minimumHeight: 60
                                            Layout.maximumHeight: 80
                                            Layout.preferredHeight: 20 * maximumLineCount
                                            Layout.fillWidth: true

                                            property int maxChars: (width - 5) * maximumLineCount

                                            text: model.title.length > maxChars
                                                    ? model.title.substring(0, maxChars - 1) + "…"
                                                    : model.title

                                            wrapMode: Text.WordWrap
                                            font.bold: true
                                            clip: true
                                            elide: Text.ElideRight
                                            horizontalAlignment: Text.AlignLeft
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