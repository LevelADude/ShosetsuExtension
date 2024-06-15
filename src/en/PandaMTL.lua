-- {"id":401266,"ver":"1.0.0","libVer":"1.0.0","author":"Me"}

--- Identification number of the extension.
--- Should be unique. Should be consistent in all references.
---
--- Required.
---
--- @type int
local id = 401266

--- Name of extension to display to the user.
--- Should match index.
---
--- Required.
---
--- @type string
local name = "PandaMTL"

--- Base URL of the extension. Used to open web view in Shosetsu.
---
--- Required.
---
--- @type string
local baseURL = "https://pandamtl.com/series/"

--- URL of the logo.
---
--- Optional, Default is empty.
---
--- @type string
local imageURL = "https://raw.githubusercontent.com/LevelADude/ShosetsuExtension/main/icons/panda-mascot-vector-icon.jpg"

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

--- Filters to display via the filter fab in Shosetsu.
---

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

--- Listings that users can navigate in Shosetsu.
---
--- Required, 1 value at minimum.
---
--- @type Listing[] | Array
local listings = {
    Listing("Something", false, function(data)
        -- Many sites use the baseURL + some path, you can perform the URL construction here.
        -- You can also extract query data from [data]. But do perform a null check, for safety.
        local url = baseURL

        local document = GETDocument(url)

        return {}
    end),
    Listing("Something (with incrementing pages!)", true, function(data)
        --- @type int
        local page = data[PAGE]
        -- Previous documentation, + appending page
        local url = baseURL .. "?page=" .. page

        local document = GETDocument(url)

        return {}
    end),
    Listing("Something without any input", false, function()
        -- Previous documentation, except no data or appending.
        local url = baseURL

        local document = GETDocument(url)

        return {}
    end)
}

--- Shrink the website url down. This is for space saving purposes.
---
--- Required.
---
--- @param url string Full URL to shrink.
--- @param type int Either KEY_CHAPTER_URL or KEY_NOVEL_URL.
--- @return string Shrunk URL.
local function shrinkURL(url, type)
    -- Currently the two branches are the same.
    -- You can simplify this to just a return with a single substitution.
    -- But some websites separate novels & chapters.
    --  So a novel is URL/novel/12345,
    --  And a chapter is URL/chapter/12345.
    -- Thus you would then program two substitutions, one to remove URL/novel/,
    --  and one to remove URL/chapter/

        return url:gsub("https://pandamtl.com/series/", "")
end

--- Expand a given URL.
---
--- Required.
---
--- @param url string Shrunk URL to expand.
--- @param type int Either KEY_CHAPTER_URL or KEY_NOVEL_URL.
--- @return string Full URL.
local function expandURL(url, type)
    -- Currently the two branches are the same.
    -- Read [shrinkURL] documentation in regards to what you should do.

        return baseURL .. url

end

--- Get a chapter passage based on its chapterURL.
---
--- Required.
---
--- @param chapterURL string The chapters shrunken URL.
--- @return string Strings in lua are byte arrays. If you are not outputting strings/html you can return a binary stream.
local function getPassage(chapterURL)
    local url = expandURL(chapterURL, KEY_CHAPTER_URL)

    --- Chapter page, extract info from it.
    local document = GETDocument(url)
    local title = document:selectFirst("h1"):text()
    document = docement.selectFirst(".wrap-body")
    document:child(0):before("<h1>"..title.."</h1>");
    return pageOfElem(document, true)""
end

--- Load info on a novel.
---
--- Required.
---
--- @param novelURL string shrunken novel url.
--- @return NovelInfo
local function parseNovel(novelURL)
    local url = baseURL .. novelURL
    --- Novel page, extract info from it.
    local document = GETDocument(url)

    return NovelInfo(){
        title = document:selectFirst("h1"):text(),
        description = document:selectFirst(".sersys entry-content-body")
    }
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

    --- Get the user text query to pass through.
    --- @type string
    local queryContent = data[QUERY]
    local doc = getDocument("https://pandamtl.com/page/".. page .."/?s=queryContent")

    return NovelInfo(){
        title = document:selectFirst("h1"):text(),
        description = document:selectFirst(".sersys entry-content-body")
    }
end

-- Return all properties in a lua table.
return {
    -- Required
    id = 401266,
    name = "PandaMTL",
    baseURL = baseURL,
    listings = listings, -- Must have at least one listing
    getPassage = getPassage,
    parseNovel = parseNovel,
    shrinkURL = shrinkURL,
    expandURL = expandURL,

    -- Optional values to change
    imageURL = imageURL,
    hasCloudFlare = true,
    hasSearch = true,
    isSearchIncrementing = true,
    searchFilters = searchFilters,
    settings = settingsModel,
    chapterType = chapterType,
    startIndex = startIndex,

    -- Required if [hasSearch] is true.
    search = search,

    -- Required if [settings] is not empty
    updateSetting = updateSetting,
}
