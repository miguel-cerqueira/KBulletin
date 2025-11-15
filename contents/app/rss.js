
// ---------------------------------- ES5 Helpers -----------------------------------------
function getAttributeValue(node, attributeName)
{
    if (node.attributes)
    {
        for (var i = 0; i < node.attributes.length; i++)
        {
            var attr = node.attributes[i]

            if (attr.name === attributeName || attr.localName === attributeName)
                return attr.value
        }
    }

    return ""
}


function getTextContent(node)
{
    if (!node) return ""

    var text = ""
    var children = node.childNodes

    for (var i = 0; i < children.length; i++)
    {
        var child = children[i]

        if (child.nodeType === 3 || child.nodeType === 4)             // TEXT_NODE -> 3
            text += child.nodeValue                                   // CDATA_SECTION -> 4
    }

    return checkHTML(text.trim())
}


function forEachChild(root, fn)
{
    if (!root || !root.childNodes)
        return

    var children = root.childNodes

    for (var i = 0; i < children.length; i++)
    {
        var child = children[i]

        if (child && child.nodeType === 1)
            fn(child)
    }
}


function cleanText(str)
{
    if (!str) return ""
    str = str.replace(/<[^>]+>/g, "")
    str = str.replace(/&[^;]+;/g, " ")
    return str.replace(/\s+/g, " ").trim().toLowerCase()
}


function getElementByName(node, elementName)
{
    var result = null

    forEachChild(node, function(child)
    {
        if (!result)
        {
            var nodeName = child.nodeName.toLowerCase()
            var localName = child.localName ? child.localName.toLowerCase() : ''
            var targetName = elementName.toLowerCase()

            if (nodeName === targetName || localName === targetName || nodeName.indexOf(':' + targetName) !== -1)
                result = child
        }
    })

    return result
}


// ---------------------------------- Main -----------------------------------------
function checkHTML(str)
{
    if (!str || typeof str !== "string")
        return "";

    return str
        .replace(/&#(\d+);/g, function(match, dec) {
            return String.fromCharCode(dec)
        })
        .replace(/&quot;/g, '"')
        .replace(/&apos;/g, "'")
        .replace(/&amp;/g, '&')
        .replace(/&lt;/g, '<')
        .replace(/&gt;/g, '>')
        .replace(/&nbsp;/g, ' ')
        .replace(/&#x([0-9a-fA-F]+);/g, function(match, hex)
        {
            return String.fromCharCode(parseInt(hex, 16))
        });
}


function parseDescriptionRSS(description)
{
    if (description === "" || !description || typeof description !== "string" )
        return ""

    description = description.replace(/<script\b[^>]*>[\s\S]*?<\/script>/gi, "")
    description = description.replace(/<style\b[^>]*>[\s\S]*?<\/style>/gi, "")
    description = description.replace(/<a\b[^>]*>(.*?)<\/a>/gi, "$1")
    description = description.replace(/<img\b[^>]*>/gi, "")
    description = description.replace(/<(ul|ol)\b[^>]*>[\s\S]*?<\/\1>/gi, "")
    description = description.replace(/<table\b[^>]*>[\s\S]*?<\/table>/gi, "")
    description = description.replace(/<(iframe|embed|object)\b[^>]*>[\s\S]*?<\/\1>/gi, "")

    return description
}


function parseArticleRSS(articleItem)
{
    var article =
    {
        title:       "",
        link:        "",
        description: "",
        pubDate:     "",
        imageUrl:    "",
        author:      "",
        source:      ""
    }

    var articleMap =
    {
        // RSS Elements
        "title": function(node)
        {
            article.title = getTextContent(node)
        },
        "link": function(node)
        {
            if (!article.link)
            {
                var linkText = getTextContent(node)
                if (linkText)
                    article.link = linkText
                else
                {
                    var href = getAttributeValue(node, "href")
                    var rel = getAttributeValue(node, "rel")

                    if (href && (!rel || rel === "alternate"))
                        article.link = href
                }
            }
        },
        "guid": function(node)
        {
            var guid = getTextContent(node)

            if (guid && guid.indexOf('http') === 0 && !article.link)
                article.link = guid
        },
        "description": function(node)
        {
            var text = getTextContent(node)
            article.description = parseDescriptionRSS(text)
        },
        "encoded": function(node)
        {
            var text = getTextContent(node)

            if (text && text.length > article.description.length)
                article.description = parseDescriptionRSS(text)
        },
        "pubdate": function(node)
        {
            article.pubDate = getTextContent(node)
        },
        "date": function(node)
        {
            if (!article.pubDate)
                article.pubDate = getTextContent(node)
        },
        "author": function(node)
        {
            if (!article.author)
                article.author = getTextContent(node)
        },
        "creator": function(node)
        {
            if (!article.author)
                article.author = getTextContent(node)
        },
        "credit": function(node)
        {
            if (!article.author)
                article.author = getTextContent(node)
        },

        // Atom Elements
        "id": function(node)
        {
            var id = getTextContent(node)

            if (id && id.indexOf('http') === 0 && !article.link)
                article.link = id
        },
        "summary": function(node)
        {
            if (!article.description)
            {
                var text = getTextContent(node)
                article.description = parseDescriptionRSS(text)
            }
        },
        "content": function(node)
        {
            var type = getAttributeValue(node, "type")
            var url = getAttributeValue(node, "url")
            var src = getAttributeValue(node, "src")

            // Atom
            if (type && (type === "html" || type === "xhtml" || type === "text"))
            {
                var text = getTextContent(node)
                if (text && text.length > article.description.length)
                    article.description = parseDescriptionRSS(text)
            }
            // media:content
            else if (url && !article.imageUrl)
            {
                if (type && type.indexOf("image") !== -1)
                    article.imageUrl = url
                else if (!type)
                    article.imageUrl = url
            }
            else if (src && !article.imageUrl)
                article.imageUrl = src
        },
        "updated": function(node)
        {
            if (!article.pubDate)
                article.pubDate = getTextContent(node)
        },
        "published": function(node)
        {
            article.pubDate = getTextContent(node)
        },
        "issued": function(node)
        {
            if (!article.pubDate)
                article.pubDate = getTextContent(node)
        },
        "modified": function(node)
        {
            if (!article.pubDate)
                article.pubDate = getTextContent(node)
        },

        // Images
        "thumbnail": function(node)
        {
            var url = getAttributeValue(node, "url")

            if (url && !article.imageUrl)
                article.imageUrl = url
        },
        "enclosure": function(node)
        {
            var type = getAttributeValue(node, "type")
            var url = getAttributeValue(node, "url") || getAttributeValue(node, "resource")

            if (url && !article.imageUrl)
            {
                if (type && (type.indexOf("image") !== -1 || type.indexOf("jpeg") !== -1 || type.indexOf("jpg") !== -1 || type.indexOf("png") !== -1 || type.indexOf("gif") !== -1))
                    article.imageUrl = url
                else if (!type && (url.indexOf('.jpg') !== -1 || url.indexOf('.jpeg') !== -1 || url.indexOf('.png') !== -1 || url.indexOf('.gif') !== -1))
                    article.imageUrl = url
            }
        },
        "image": function(node) {
            var url = getTextContent(node) || getAttributeValue(node, "url")

            if (url && !article.imageUrl)
                article.imageUrl = url
        },


        "group": function(node)
        {
            forEachChild(node, function(child)
            {
                if (child.localName === "content")
                {
                    var type = getAttributeValue(child, "type")

                    if (type && type.indexOf("image") !== -1 && !article.imageUrl)
                        article.imageUrl = getAttributeValue(child, "url")
                }
            })
        }
    }


    forEachChild(articleItem, function(child)
    {
        var nodeName = child.nodeName.toLowerCase()
        var localName = child.localName ? child.localName.toLowerCase() : ''
        var handler = null


        if (localName && articleMap[localName])
            handler = articleMap[localName]
        else if (articleMap[nodeName])
            handler = articleMap[nodeName]
        else
        {
            var nameWithoutPrefix = nodeName.indexOf(':') !== -1 ? nodeName.split(':')[1] : nodeName

            if (articleMap[nameWithoutPrefix])
                handler = articleMap[nameWithoutPrefix]
        }


        if (handler)
        {
            try { handler(child) }
            catch (e) { console.log("Error processing element:", nodeName, e) }
        }
    })


    if (!article.description || article.description.trim() === "")
        article.description = "No description available."


    if (article.link)
    {
        try
        {
            var website = new URL(article.link)
            article.source = website.protocol + "//" + website.hostname + "/"
        }
        catch (e)
        {
            article.source = ""
        }
    }

    return article
}



function parseFeed(url, callback)
{
    var xhr = new XMLHttpRequest()
    xhr.responseType = "document"
    xhr.open("GET", url)
    xhr.setRequestHeader('User-Agent', 'RSS Reader')

    xhr.onreadystatechange = function()
    {
        if (xhr.readyState !== XMLHttpRequest.DONE)
            return

        if (xhr.status === 200)
        {
            var xml = xhr.responseXML

            if (!xml || !xml.documentElement)
            {
                callback([], "XML parse error")
                return
            }

            var root = xml.documentElement
            var items = []
            var container = null
            var itemElementName = "item"

            var rootName = root.nodeName.toLowerCase()
            var isRDF = rootName === "rdf:rdf" || rootName === "rdf"
            var isAtom = rootName === "feed" || rootName === "atom:feed"

            if (isRDF)
            {
                // Science uses rdf:RDF, where items are siblings of the <channel>
                container = root
                itemElementName = "item"
            }
            else if (isAtom)
            {
                // Atom feeds have <entry> elements directly under <feed>
                container = root
                itemElementName = "entry"
            }
            else
            {
                // For regular RSS feeds
                forEachChild(root, function(child)
                {
                    if (child.nodeName.toLowerCase() === "channel")
                    {
                        container = child
                        return
                    }
                })

                if (!container)
                {
                    callback([], "Error: No <channel> element found in the feed.")
                    return
                }
                itemElementName = "item"
            }


            // Plasmoid Config Variables
            var bannedWords = []
            try
            {
                var raw = plasmoid.configuration.banned || "[]"
                bannedWords = JSON.parse(raw)
                    .map(word => (word + "").trim().toLowerCase())
                    .filter(word => word.length > 0)
            }
            catch (e)
            {
                bannedWords = []
            }


            var maxArticles = 100 // Default value
            try
            {
                maxArticles = JSON.parse(plasmoid.configuration.maxArticles || "100")

                if (isNaN(maxArticles) || maxArticles < 0)
                    maxArticles = 100
            }
            catch(e)
            {
                maxArticles = 100
            }


            var node = container.firstChild

            while (node)
            {
                var nodeName = node.nodeName ? node.nodeName.toLowerCase() : ""
                var localName = node.localName ? node.localName.toLowerCase() : ""

                if (nodeName === itemElementName || localName === itemElementName || (itemElementName === "entry" && (nodeName === "entry" || localName === "entry")))
                {
                    // --- Skip articles with banned terms
                    var article  = parseArticleRSS(node)
                    var combined = cleanText(article.title + " " + article.description)
                    var isBanned = bannedWords.some(
                        word =>
                        {
                            var pattern = new RegExp("\\b" + word.replace(/[.*+?^${}()|[\]\\]/g, "\\$&") + "\\b", "i")
                            return pattern.test(combined)
                        }
                    )


                    // --- Skip articles older than 31 days
                    var pubDate = article.pubDate
                                    ? new Date(article.pubDate)
                                    : ""
                    var isOld = false

                    if (pubDate !== "")
                    {
                        var cutoff = new Date()
                        isOld = pubDate < cutoff.setDate(cutoff.getDate() - 31)
                    }



                    if (!isBanned && !isOld)
                        items.push(article)

                    if (items.length >= maxArticles)
                        break
                }

                node = node.nextSibling
            }

            if (items.length === 0) callback([], "No articles found")
            else callback({ items: items }, "")
        }
        else callback([], "HTTP error: " + xhr.status)
    }

    xhr.send()
}