
// ---------------------------------------------------- Feed Management ---------------------------------------------
function filterSources()
{
    filteredSourcesModel.clear()

    const topic = sideArea.selectedTopicIndex >= 0
        ? topicsList.model[sideArea.selectedTopicIndex]
        : null

    const activeSourcesSet = new Set()

    const activeForTopic = []
    const nonActiveForTopic = []
    const activeNonTopic = []
    const nonActiveNonTopic = []

    for (const source of allSources)
    {
        const matchesTopic = !topic || source.topic === topic

        if (topic && source.topic === topic)
            activeSourcesSet.add(source.url)

        const isActive = activeSourcesSet.has(source.url) ||
                        activeSources.indexOf(source.url) !== -1

        if (topic)
        {
            if (isActive && matchesTopic) activeForTopic.push(source)
            else if (!isActive && matchesTopic) nonActiveForTopic.push(source)
            else if (isActive) activeNonTopic.push(source)
            else nonActiveNonTopic.push(source)
        }
        else
        {
            if (isActive) activeForTopic.push(source)
            else nonActiveForTopic.push(source)
        }
    }

    if (topic)
    {
        activeSources.length = 0
        activeSources.push(...activeSourcesSet)
    }

    const finalList = topic
        ? [...activeForTopic, ...nonActiveForTopic, ...activeNonTopic, ...nonActiveNonTopic]
        : [...activeForTopic, ...nonActiveForTopic]

    finalList.forEach(entry => filteredSourcesModel.append(entry))
}



function loadArticles(source)
{
    RSSFetcher.parseFeed(source, function(article)
    {
        // if (!article.items || !Array.isArray(article.items))
        // {
        //     articlesModel.append
        //     ({
        //         title: "Unsupported Feed",
        //         link: "",
        //         description: "<p>Could not parse provided URL.</p>",
        //         pubDate: "",
        //         thumbnail: Qt.resolvedUrl("../assets/rss.png"),
        //         author: "",
        //         source: source || ""
        //     })
        //     return
        // }

        var items = article.items
        var index = 0

        function stream()
        {
            if (index >= items.length)
                return

            var scan = items[index]

            articlesModel.append
            ({
                title:       scan.title,
                link:        scan.link,
                description: scan.description,
                pubDate:     scan.pubDate,
                thumbnail:   scan.imageUrl,
                author:      scan.author,
                source:      scan.source
            })

            index++
            Qt.callLater(stream)
        }

        stream()
    })
}



function fetchSources(list)
{
    if (!list || list.length === 0)
        return

    articlesModel.clear()

    for (var i = 0; i < list.length; i++)
        loadArticles(list[i])
}