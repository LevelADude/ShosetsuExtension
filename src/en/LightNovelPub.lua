-- {"id":31,"ver":"1.0.1","libVer":"1.0.0","author":"Gta-Cool"}

local json = Require("dkjson")

--- Identification number of the extension.
--- Should be unique. Should be consistent in all references.
---
--- Required.
---
--- @type int
local id = 31

--- Name of extension to display to the user.
--- Should match index.
---
--- Required.
---
--- @type string
local name = "Light Novel Pub"

--- Base URL of the extension. Used to open web view in Shosetsu.
---
--- Required.
---
--- @type string
local baseURL = "https://www.lightnovelpub.com/"

--- URL of the logo.
---
--- Optional, Default is empty.
---
--- @type string
local imageURL = "https://gitlab.com/shosetsuorg/extensions/-/raw/dev/icons/LightNovelPub.png"

--- Shosetsu tries to handle cloudflare protection if this is set to true.
---
--- Optional, Default is false.
---
--- @type boolean
local hasCloudFlare = true

--- If the website has search.
---
--- Optional, Default is true.
---
--- @type boolean
local hasSearch = true

--- If the websites search increments or not.
---
--- Optional, Default is true.
---
--- @type boolean
local isSearchIncrementing = true

local GENRE_VALUES = {
    [0] = "genre-all-04061342",
    [1] = "genre-action-04061342",
    [2] = "genre-adventure-04061342",
    [3] = "genre-drama-04061342",
    [4] = "genre-fantasy-04061342",
    [5] = "genre-harem-04061342",
    [6] = "genre-martial-arts-10032131",
    [7] = "genre-mature-04061342",
    [8] = "genre-romance-04061342",
    [9] = "genre-tragedy-10032131",
    [10] = "genre-xuanhuan-10032131",
    [11] = "genre-ecchi-04061342",
    [12] = "genre-comedy-10032131",
    [13] = "genre-slice-of-life-04061342",
    [14] = "genre-mystery-10032131",
    [15] = "genre-supernatural-10032131",
    [16] = "genre-psychological-10032131",
    [17] = "genre-sci-fi-04061342",
    [18] = "genre-xianxia-04061342",
    [19] = "genre-school-life-10032131",
    [20] = "genre-josei-04061342",
    [21] = "genre-wuxia-04061342",
    [22] = "genre-shounen-10032131",
    [23] = "genre-horror-04061342",
    [24] = "genre-mecha-10032131",
    [25] = "genre-historical-04061342",
    [26] = "genre-shoujo-10032131",
    [27] = "genre-adult-04061342",
    [28] = "genre-seinen-04061342",
    [29] = "genre-sports-10032131",
    [30] = "genre-lolicon-10032131",
    [31] = "genre-gender-bender-04061342",
    [32] = "genre-shounen-ai-10032131",
    [33] = "genre-yaoi-04061342",
    [34] = "genre-video-games-04061342",
    [35] = "genre-smut-04061342",
    [36] = "genre-magical-realism-10032131",
    [37] = "genre-eastern-fantasy-04061342",
    [38] = "genre-contemporary-romance-10032131",
    [39] = "genre-fantasy-romance-10032131",
    [40] = "genre-shoujo-ai-10032131",
    [41] = "genre-yuri-10032131"
}
local GENRE_KEY = 11

local ORDER_VALUES = {
    [0] = "order-new",
    [1] = "order-popular",
    [2] = "order-updated"
}
local ORDER_KEY = 12

local STATUS_VALUES = {
    [0] = "status-all",
    [1] = "status-completed",
    [2] = "status-ongoing"
}
local STATUS_KEY = 13

--- Filters to display via the filter fab in Shosetsu.
---
--- Optional, Default is none.
---
--- @type Filter[] | Array
local searchFilters = {
    DropdownFilter(GENRE_KEY, "Genre / Category", {
        "All",
        "Action",
        "Adventure",
        "Drama",
        "Fantasy",
        "Harem",
        "Martial Arts",
        "Mature",
        "Romance",
        "Tragedy",
        "Xuanhuan",
        "Ecchi",
        "Comedy",
        "Slice of Life",
        "Mystery",
        "Supernatural",
        "Psychological",
        "Sci-fi",
        "Xianxia",
        "School Life",
        "Josei",
        "Wuxia",
        "Shounen",
        "Horror",
        "Mecha",
        "Historical",
        "Shoujo",
        "Adult",
        "Seinen",
        "Sports",
        "Lolicon",
        "Gender Bender",
        "Shounen Ai",
        "Yaoi",
        "Video Games",
        "Smut",
        "Magical Realism",
        "Eastern Fantasy",
        "Contemporary Romance",
        "Fantasy Romance",
        "Shoujo Ai",
        "Yuri"
    }),
    DropdownFilter(ORDER_KEY, "Order By", { "New", "Popular", "Updates" }),
    DropdownFilter(STATUS_KEY, "Status", { "All", "Completed", "Ongoing" })
}

--- Internal settings store.
---
--- Completely optional.
---  But required if you want to save results from [updateSetting].
---
--- Notice, each key is surrounded by "[]" and the value is on the right side.
--- @type table
local settings = {
    [1] = 0
}

--- Settings model for Shosetsu to render.
---
--- Optional, Default is empty.
---
--- @type Filter[] | Array
local settingsModel = {}

--- ChapterType provided by the extension.
---
--- Optional, Default is STRING. But please do HTML.
---
--- @type ChapterType
local chapterType = ChapterType.HTML

--- Index that pages start with. For example, the first page of search is index 1.
---
--- Optional, Default is 1.
---
--- @type number
local startIndex = 1

--- Shrink the website url down. This is for space saving purposes.
---
--- Required.
---
--- @param url string Full URL to shrink.
--- @param type int Either KEY_CHAPTER_URL or KEY_NOVEL_URL.
--- @return string Shrunk URL.
local function shrinkURL(url, type)
    return url:gsub(".-lightnovelpub%.com/novel/", "")
end

--- Expand a given URL.
---
--- Required.
---
--- @param url string Shrunk URL to expand.
--- @param type int Either KEY_CHAPTER_URL or KEY_NOVEL_URL.
--- @return string Full URL.
local function expandURL(url, type)
    return baseURL .. "novel/" .. url
end

local function getRankingNovels(url)
    local document = GETDocument(url):selectFirst("#ranking .container")

    return map(document:select(".rank-novels .novel-item"), function(ni)
        local n = Novel()
        local te = ni:selectFirst(".item-body .title a");
        n:setTitle(te:attr("title"))
        n:setLink(shrinkURL(baseURL .. te:attr("href"):sub(2), KEY_NOVEL_URL))
        n:setImageURL(ni:selectFirst(".cover img"):attr("data-src"))
        return n
    end)
end

--- Listings that users can navigate in Shosetsu.
---
--- Required, 1 value at minimum.
---
--- @type Listing[] | Array
local listings = {
    Listing("Browse List", true, function(data)
        local document = GETDocument(baseURL .. "browse/" ..
            GENRE_VALUES[data[GENRE_KEY]] .. "/" ..
            ORDER_VALUES[data[ORDER_KEY]] .. "/" ..
            STATUS_VALUES[data[STATUS_KEY]] .. "/" ..
            "?page=" .. data[PAGE]
        ):selectFirst("#explore .container")

        local activePage = document:selectFirst(".pagination .active"):text()
        if activePage == ("" .. data[PAGE]) then
            return map(document:select(".novel-list .novel-item"), function(ni)
                local n = Novel()
                local te = ni:selectFirst(".item-body .novel-title a");
                n:setTitle(te:attr("title"))
                n:setLink(shrinkURL(baseURL .. te:attr("href"):sub(2), KEY_NOVEL_URL))
                n:setImageURL(ni:selectFirst(".novel-cover img"):attr("data-src"))
                return n
            end)
        end
        return {}
    end),
    Listing("Novel Ranking", false, function(data)
        return getRankingNovels(baseURL .. "ranking-04061612")
    end),
    Listing("Top Rated Novels", false, function(data)
        return getRankingNovels(baseURL .. "ranking-04061612/ratings")
    end),
    Listing("Most Read Novels", false, function(data)
        return getRankingNovels(baseURL .. "ranking-04061612/mostread")
    end),
    Listing("The novels with the most reviews", false, function(data)
        return getRankingNovels(baseURL .. "ranking-04061612/mostreview")
    end),
    Listing("The novels with the most commentary activity", false, function(data)
        return getRankingNovels(baseURL .. "ranking-04061612/mostcomment")
    end),
    Listing("The novels most added to the library", false, function(data)
        return getRankingNovels(baseURL .. "ranking-04061612/mostlib")
    end)
}

--- Get a chapter passage based on its chapterURL.
---
--- Required.
---
--- @param chapterURL string The chapters shrunken URL.
--- @return string Strings in lua are byte arrays. If you are not outputting strings/html you can return a binary stream.
local function getPassage(chapterURL)
    local url = expandURL(chapterURL, KEY_CHAPTER_URL)

    --- Chapter page, extract info from it.
    local document = GETDocument(url):selectFirst("#chapter-article")
    local title = document:selectFirst("section .titles .chapter-title"):text()
    local chapter = document:selectFirst("#chapter-container")

    -- Remove unwanted HTML elements (ads)
    chapter:select(".adsbygoogle"):parents():remove()

    -- Chapter title inserted before chapter text
    chapter:child(0):before("<h1>" .. title .. "</h1>");

    return pageOfElem(chapter, true)
end

--- Load info on a novel.
---
--- Required.
---
--- @param novelURL string shrunken novel url.
--- @return NovelInfo
local function parseNovel(novelURL)
    local url = expandURL(novelURL, KEY_NOVEL_URL)

    local ni = NovelInfo()

    local document = GETDocument(url):selectFirst("#novel")
    ni:setTitle(document:selectFirst(".novel-info .novel-title"):text())
    ni:setAlternativeTitles(map(
        document:select(".novel-info .alternative-title"),
        function(nat)
            return nat:text()
        end
    ))
    ni:setImageURL(document:selectFirst(".cover img"):attr("data-src"))
    ni:setDescription(table.concat(
        map(
            document:select(".summary .content p"),
            function(np)
                return np:text()
            end
        ),
        "\n\n"
    ))
    ni:setGenres(map(
        document:select(".novel-info .categories a"),
        function(ng)
            return ng:text()
        end
    ))
    ni:setAuthors(map(
        document:select(".novel-info .author a span[itemprop=\"author\"]"),
        function(na)
            return na:text()
        end
    ))

    local status = document:selectFirst(".novel-info .header-stats span:nth-child(4) strong"):text()
    ni:setStatus(NovelStatus(status == "Ongoing" and 0 or status == "Completed" and 1 or 3))

    ni:setTags(map(
        document:select(".tags .content a"),
        function(nt)
            return nt:text()
        end
    ))

    local nextLinkNode = nil
    local chaptersTable = {}
    repeat
        local chaptersPageUrl = nextLinkNode ~= nil and (baseURL .. nextLinkNode:attr("href"):sub(2)) or (url .. "/chapters/")
        local chaptersDocument = GETDocument(chaptersPageUrl):selectFirst("#chpagedlist")
        nextLinkNode = chaptersDocument:selectFirst(".pagination .PagedList-skipToNext a")
        local pageChaptersTable = map(chaptersDocument:select(".chapter-list a"), function(ni)
            local nc = NovelChapter()
            local chapterNumber = ni:selectFirst(".chapter-no"):text()
            nc:setTitle(chapterNumber .. " - " .. ni:selectFirst(".chapter-title"):text())
            nc:setLink(shrinkURL(baseURL .. ni:attr("href"):sub(2), KEY_CHAPTER_URL))
            nc:setOrder(chapterNumber)
            nc:setRelease(ni:selectFirst(".chapter-update"):text())
            return nc
        end)
        for _,nc in ipairs(pageChaptersTable) do
            table.insert(chaptersTable, nc)
        end
    until (nextLinkNode == nil)

    ni:setChapters(chaptersTable)

    return ni
end

--- Called to search for novels off a website.
---
--- Optional, But required if [hasSearch] is true.
---
--- @param data table @of applied filter values [QUERY] is the search query, may be empty.
--- @return Novel[] | Array
local function search(data)
    --- Not required if search is not incrementing.
    --- @type int
    local page = data[PAGE]

    -- There is always only one page for the search results
    if page > 1 then
        return {}
    end

    --- Get the user text query to pass through.
    --- @type string
    local query = data[QUERY]

    local function getSearchResultDocument(queryContent)
        local searchDocument = GETDocument(baseURL .. "search"):selectFirst("#search-section")
        local lnRequestVerifyToken = searchDocument:selectFirst("#novelSearchForm input[name=__LNRequestVerifyToken]"):attr("value")

        local searchResponse = RequestDocument(
            POST(
                baseURL .. "lnsearchlive",
                HeadersBuilder():add("LNRequestVerifyToken", lnRequestVerifyToken):build(),
                FormBodyBuilder():add("inputContent", queryContent):build()
            )
        )
        searchResponse = json.decode(searchResponse:selectFirst('body'):text())

        return Document(searchResponse["resultview"])
    end

    local srDocument = getSearchResultDocument(query)

    return map(
        srDocument:select(".novel-list .novel-item a"),
        function(nia)
            local n = Novel()
            n:setTitle(nia:selectFirst(".item-body .novel-title"):text())
            n:setLink(shrinkURL(baseURL .. nia:attr("href"):sub(2), KEY_NOVEL_URL))
            n:setImageURL(nia:selectFirst(".novel-cover img"):attr("src"))
            return n
        end
    )
end

--- Called when a user changes a setting and when the extension is being initialized.
---
--- Optional, But required if [settingsModel] is not empty.
---
--- @param id int Setting key as stated in [settingsModel].
--- @param value any Value pertaining to the type of setting. Int/Boolean/String.
--- @return void
local function updateSetting(id, value)
    settings[id] = value
end

-- Return all properties in a lua table.
return {
    -- Required
    id = id,
    name = name,
    baseURL = baseURL,
    listings = listings, -- Must have at least one listing
    getPassage = getPassage,
    parseNovel = parseNovel,
    shrinkURL = shrinkURL,
    expandURL = expandURL,

    -- Optional values to change
    imageURL = imageURL,
    hasCloudFlare = hasCloudFlare,
    hasSearch = hasSearch,
    isSearchIncrementing = isSearchIncrementing,
    searchFilters = searchFilters,
    settings = settingsModel,
    chapterType = chapterType,
    startIndex = startIndex,

    -- Required if [hasSearch] is true.
    search = search,

    -- Required if [settings] is not empty
    updateSetting = updateSetting,
}
