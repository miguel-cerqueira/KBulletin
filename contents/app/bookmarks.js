function loadBookmarks() 
{
    isCardExpanded = false
    bookmarksModel.clear()

    var raw = plasmoid.configuration.bookmarks

    var bookmarks
        try 
        {
            bookmarks = JSON.parse(raw)
        } 
        catch(e) 
        {
            bookmarks = []
        }

    if (!Array.isArray(bookmarks))
        bookmarks = []

    bookmarks.forEach
        (function(bookmark) 
        {
            bookmarksModel.append(bookmark)
        })
}


function saveBookmark(card) 
{
    var raw = plasmoid.configuration.bookmarks || "[]"

    var bookmarks
        try 
        {
            bookmarks = JSON.parse(raw)
        } 
        catch(e) 
        {
            bookmarks = []
        }

    if (!Array.isArray(bookmarks))
        bookmarks = []


    // Prevent dupes
    var YouWouldntDownloadASheep = bookmarks.findIndex
                                        (function(bookmark) 
                                        {
                                            return bookmark.link === card.link
                                        })

    if (YouWouldntDownloadASheep !== -1)
        return


    var bookmark = 
    {
        title:       card.title       || "",
        description: card.description || "",
        thumbnail:   card.thumbnail   || "",
        link:        card.link        || "",
        pubDate:     card.pubDate     || "",
        author:      card.author      || "",
        source:      card.source      || ""
    }

    bookmarks.push(bookmark)        
    bookmarksModel.append(bookmark)

    plasmoid.configuration.bookmarks = JSON.stringify(bookmarks)
}


function removeBookmark(card)
{
    if (bookmarksDisplay == false)
        return

    var raw = plasmoid.configuration.bookmarks || "[]"

    var bookmarks
        try 
        {
            bookmarks = JSON.parse(raw)
        } 
        catch(e) 
        {
            bookmarks = []
        }

    if (!Array.isArray(bookmarks))
        bookmarks = []

    
    bookmarks = bookmarks.filter
        (function(item) 
        {
            return item.link !== card.link
        })
    
    plasmoid.configuration.bookmarks = JSON.stringify(bookmarks)
    bookmarksModel.clear()

    for (let i = 0; i < bookmarks.length; i++) 
    {
        bookmarksModel.append(bookmarks[i])
    }
}