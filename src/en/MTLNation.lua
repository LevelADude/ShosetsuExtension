-- {"id":95568,"ver":"1.0.0","libVer":"1.0.0","author":"Confident-hate"}
local json = Require("dkjson")
local baseURL = "https://mtlnation.com"

---@param v Element
local text = function(v)
    return v:text()
end

local responseToText = function(v)
    return v.name
end

---@param url string
---@param type int
local function shrinkURL(url)
    return url:gsub("https://api.mtlnation.com", "")
end

---@param url string
---@param type int
local function expandURL(url)
    return "https://api.mtlnation.com" .. url
end

local ORDER_BY_FILTER = 2
local ORDER_BY_VALUES = { "Rating", "Newly Added", "Latest Update", "Bookmark Count", "All Time Ranking", "Daily Ranking", "Weekly Ranking", "Monthly Ranking", "Best Match"}
local ORDER_BY_PARAMS = { "&sort=rating", "&sort=novel_new", "&sort=chapter_new", "&sort=bookmark_count", "&sort=views_all", "&sort=views_day", "&sort=views_week", "&sort=views_month", "&sort=best"}

local GENRE_FILTER = 3
local GENRE_VALUES = { 
"All",
"Fantasy",
"Fan-Fiction",
"Sci-Fi",
"Virual Reality",
"Romance",
"Urban"
}

local GENREPARAMS = {
"",
"&include_genres=1",
"&include_genres=3",
"&include_genres=6",
"&include_genres=7",
"&include_genres=8",
"&include_genres=2"
}

local STATUS_FILTER = 4
local STATUS_VALUES = {"All", "Completed", "Ongoing", "Suspended"}
local STATUS_PARAMS = {"", "&statuses=2", "&statuses=1", "&statuses=3"}

local searchFilters = {
    DropdownFilter(GENRE_FILTER, "Genre", GENRE_VALUES),
    DropdownFilter(ORDER_BY_FILTER, "Order by", ORDER_BY_VALUES),
    DropdownFilter(STATUS_FILTER, "Status", STATUS_VALUES)
}

local encode = Require("url").encode

--- @param chapterURL string @url of the chapter
--- @return string @of chapter
local function getPassage(chapterURL)
    local response = GETDocument(chapterURL)
    response = json.decode(response:text()).data
    local ht = "<h1>" .. response.title .. "</h1>"
    local pTagList = ""
    pTagList = map(Document(response.content):select("p"), text)
    for k,v in pairs(pTagList) do ht = ht .. "<br><br>" .. v end
    return pageOfElem(Document(ht), true)
end

--- @param data table
local function search(data)
    local orderBy = data[ORDER_BY_FILTER]
    local genre = data[GENRE_FILTER]
    local status = data[STATUS_FILTER]
    local page = "&page=" .. data[PAGE]
    local orderValue = ""
    local genreValue = ""
    local statusValue = ""
    if orderBy ~= nil then
        orderValue = ORDER_BY_PARAMS[orderBy+1]
    end
    if genre ~= nil then
        genreValue = GENREPARAMS[genre+1]
    end
    if status ~= nil then
        statusValue = STATUS_PARAMS[status+1]
    end
    local url = "https://api.mtlnation.com/api/v2/novels/?faloo=NaN&max_word_count=0&min_word_count=0" .. page .. "&query=" .. data[QUERY] .. orderValue ..statusValue .. genreValue
    local response = GETDocument(url)
    response = json.decode(response:text())
    return map(response["data"], function(v)
        return Novel {
            title = v.title,
            link = "/api/v2/novels/" .. v.slug,
            imageURL = "https://api.mtlnation.com/media/" .. v.cover
        }
    end)
end

--- @param novelURL string @URL of novel
--- @return NovelInfo
local function parseNovel(novelURL)
    local response = GETDocument(expandURL(novelURL))
    response = json.decode(response:text()).data
    local chURL = "https://api.mtlnation.com/api/v2/novels/" .. response.id .. "/chapters/"
    local chResponse = GETDocument(chURL)
    chResponse = json.decode(chResponse:text()).data
    return NovelInfo {
        title = response.title,
        description = "Bookmarked By: " .. response.bookmark_count .. "People\n\n" .. table.concat(map(Document(response.synopsis):select("p"), text), "\n"),
        imageURL = "https://api.mtlnation.com/media/" .. response.cover,
        status = ({
            [1] = NovelStatus.PUBLISHING,
            [2] = NovelStatus.COMPLETED,
            [3] = NovelStatus.PAUSED,
        })[response.status],
        authors = { response.author },
        genres = map(response.genres, responseToText),
        tags = map(response.tags, responseToText),
        chapters = AsList(
            map(chResponse, function(v)
                return NovelChapter {
                    order = v,
                    title = v.title,
                    link = "https://api.mtlnation.com/api/v2/chapters/" .. response.slug .. "/" .. v.slug
                }
            end)
        )
    }
end

local function parseListing(listingURL)
    local response = GETDocument(listingURL)
    response = json.decode(response:text())
    return map(response["data"], function(v)
        return Novel {
            title = v.title,
            link = "/api/v2/novels/" .. v.slug,
            imageURL = "https://api.mtlnation.com/media/" .. v.cover
        }
    end)
end


local function getListing(data)
    local orderBy = data[ORDER_BY_FILTER]
    local genre = data[GENRE_FILTER]
    local status = data[STATUS_FILTER]
    local page = "&page=" .. data[PAGE]
    local orderValue = ""
    local genreValue = ""
    local statusValue = ""

    if orderBy ~= nil then
        orderValue = ORDER_BY_PARAMS[orderBy+1]
    end
    if genre ~= nil then
        genreValue = GENREPARAMS[genre+1]
    end
    if status ~= nil then
        statusValue = STATUS_PARAMS[status+1]
    end
    local url = "https://api.mtlnation.com/api/v2/novels/?faloo=NaN&max_word_count=0&min_word_count=0" .. page .. "&query=" .. orderValue ..statusValue .. genreValue
    return parseListing(url)
end



return {
    id = 95568,
    name = "MTLNation",
    baseURL = baseURL,
    imageURL = "https://i.imgur.com/jmwgTRw.png",
    hasSearch = true,
    listings = {
        Listing("Default", true, getListing)
    },
    parseNovel = parseNovel,
    getPassage = getPassage,
    chapterType = ChapterType.HTML,
    search = search,
    hasCloudFlare = true,
    shrinkURL = shrinkURL,
    expandURL = expandURL,
    searchFilters = searchFilters
}   