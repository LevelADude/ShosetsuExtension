-- {"id":95563,"ver":"1.0.0","libVer":"1.0.0","author":"Confident-hate"}

local baseURL = "https://comrademao.com"

---@param v Element
local text = function(v)
    return v:text()
end


---@param url string
---@param type int
local function shrinkURL(url)
    return url:gsub("https://comrademao.com", "")
end

---@param url string
---@param type int
local function expandURL(url)
    return baseURL .. url
end

local TYPE_FILTER = 2
local TYPE_VALUES = {
    "All",
    "Chinese",
    "Japanese",
    "Korean"
}
local TYPEPARAMS = {
    "/novel/",
    "/mtype/chinese/",
    "/mtype/japanese/",
    "/mtype/korean/"
}

local searchFilters = {
    DropdownFilter(TYPE_FILTER, "Type", TYPE_VALUES)
}

--- @param chapterURL string @url of the chapter
--- @return string @of chapter
local function getPassage(chapterURL)
    local htmlElement = GETDocument(chapterURL)
    htmlElement = htmlElement:selectFirst(".chaptercontent")
    return pageOfElem(htmlElement, true)
end

--- @param data table
local function search(data)
    local queryContent = data[QUERY]
    local page = data[PAGE]
    local url = ""
    if page~=1 then
        url = baseURL .. "/page/" .. page .. "/?s=" .. queryContent
    else
        url = baseURL .. "/?s=" .. queryContent
    end
    local doc = GETDocument(url)
    return map(doc:select(".listupd .bs"), function(v)
        return Novel {
            title = v:selectFirst("a"):attr("title"),
            imageURL = v:selectFirst("a img"):attr("src"),
            link = shrinkURL(v:selectFirst("a"):attr("href"))
        }
    end)
end

--- @param novelURL string @URL of novel
--- @return NovelInfo
local function parseNovel(novelURL)
    local url = baseURL .. novelURL
    local document = GETDocument(url)
    local chSelector = document:select("#chapterlist li a")
    local chapterOrder = chSelector:size()
    return NovelInfo {
        title = document:selectFirst(".infox h1"):text(),
        imageURL = document:selectFirst(".thumb img"):attr("src"),
        genres = map(document:select("div.wd-full:nth-child(4) a"), text ),
        description = document:select("div.wd-full:nth-child(6) p"):text(),
        status = ({
            ["On-going"] = NovelStatus.PUBLISHING,
            Complete = NovelStatus.COMPLETED,
            Completed = NovelStatus.COMPLETED,
            Hiatus = NovelStatus.PAUSED
        })[document:selectFirst("div.wd-full:nth-child(3) a"):text()],
        chapters = AsList(
                map(chSelector, function(v)
                    chapterOrder = chapterOrder - 1
                    return NovelChapter {
                        order = chapterOrder,
                        title = v:selectFirst("span"):text(),
                        link = v:attr("href")
                    }
                end)
        )
    }
end

local function parseListing(listingURL)
    local document = GETDocument(listingURL)
    return map(document:select("#releases .listupd .bs"), function(v)
        return Novel {
            title = v:selectFirst("a"):attr("title"),
            link = shrinkURL(v:selectFirst("a"):attr("href")),
            imageURL = v:selectFirst("a img"):attr("src")
        }
    end)
end

local function getListing(data)
    local typ = data[TYPE_FILTER]
    local page = data[PAGE]
    local typeValue = ""
    if typ ~= nil then
        typeValue = TYPEPARAMS[typ+1]
    end
    local url = ""
    if page~=1 then
        url = baseURL .. typeValue .. "/page/" .. page .. "/"
    else
        url = baseURL .. typeValue
    end
    return parseListing(url)
end

return {
    id = 95563,
    name = "Comrademao",
    baseURL = baseURL,
    imageURL = "https://i.imgur.com/N6KcMJ4.png",
    hasSearch = true,
    listings = {
        Listing("Default", true, getListing)
    },
    parseNovel = parseNovel,
    getPassage = getPassage,
    chapterType = ChapterType.HTML,
    search = search,
    shrinkURL = shrinkURL,
    expandURL = expandURL,
    searchFilters = searchFilters
}
