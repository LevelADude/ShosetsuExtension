-- {"id":95560,"ver":"1.0.1","libVer":"1.0.0","author":"Confident-hate"}

local baseURL = "https://m.pawread.com"

---@param v Element
local text = function(v)
    return v:text()
end


---@param url string
---@param type int
local function shrinkURL(url)
    return url:gsub("https://m.pawread.com/", "")
end

---@param url string
---@param type int
local function expandURL(url)
    return baseURL .. url
end

local GENRE_FILTER = 2
local GENRE_VALUES = { 
"All",
"Fantasy",
"Action",
"Xuanhuan",
"Romance",
"Comedy",
"Mystery",
"Mature",
"Harem",
"Wuxia",
"Xianxia",
"Tragedy",
"Sci-fi",
"Historical",
"Ecchi",
"Adventure",
"Adult",
"Supernatural",
"Psychological",
"Drama",
"Horror",
"Josei",
"Mecha",
"Seinen",
"Shoujo",
"Shounen",
"Smut",
"Yaoi",
"Yuri",
"Martial Arts",
"School Life",
"Shoujo Ai",
"Shounen Ai",
"Slice of Life",
"Gender Bender",
"Sports",
"Urban",
"Adventurer"
}
local GENREPARAMS = {
"All",
"Fantasy",
"Action",
"Xuanhuan",
"Romance",
"Comedy",
"Mystery",
"Mature",
"Harem",
"Wuxia",
"Xianxia",
"Tragedy",
"Scifi",
"Historical",
"Ecchi",
"Adventure",
"Adult",
"Supernatural",
"Psychological",
"Drama",
"Horror",
"Josei",
"Mecha",
"Seinen",
"Shoujo",
"Shounen",
"Smut",
"Yaoi",
"Yuri",
"MartialArts",
"SchoolLife",
"ShoujoAi",
"Shounen Ai",
"SliceofLife",
"GenderBender",
"Sports",
"Urban",
"Adventurer"
}

local STATUS_FILTER_KEY = 3
local STATUS_VALUES = { "All", "Completed", "Ongoing" }
local STATUS_PARAMS = {"All", "wanjie", "lianzai"}

local LANG_FILTER_KEY = 4
local LANG_FILTER_VALUES = { "All", "Chinese", "Korean", "Japanese" }
local LANG_PARAMS = {"All", "chinese", "korean", "japanese"}

local searchFilters = {
    DropdownFilter(GENRE_FILTER, "Genre", GENRE_VALUES),
    DropdownFilter(STATUS_FILTER_KEY, "Status", STATUS_VALUES),
    DropdownFilter(LANG_FILTER_KEY, "Language", LANG_FILTER_VALUES)
}

--- @param chapterURL string @url of the chapter
--- @return string @of chapter
local function getPassage(chapterURL)
    local htmlElement = GETDocument(chapterURL)
    local title = htmlElement:selectFirst(".chapter_name"):text()
    htmlElement = htmlElement:selectFirst(".content")
    htmlElement:child(0):before("<h1>" .. title .. "</h1>");
    local toRemove = {}
    htmlElement:traverse(NodeVisitor(function(v)
        if v:tagName() == "p" and v:text() == "" then
            toRemove[#toRemove+1] = v
        end
    end, nil, true))
    for _,v in pairs(toRemove) do
        v:remove()
    end
    return pageOfElem(htmlElement, true)
end

--- @param data table
local function search(data)
    local function getSearchResult(queryContent)
        return GETDocument(baseURL .. "/search/?keywords=" .. queryContent)
    end


    local queryContent = data[QUERY]
    local doc = getSearchResult(queryContent)

    return map(doc:select(".UpdateList .clearfix.itemBox"), function(v)
        return Novel {
            title = v:selectFirst(".itemTxt .title"):text(),
            imageURL = v:selectFirst(".itemImg a img"):attr("src"),
            link = v:selectFirst("a"):attr("href")
        }
    end)
end

--- @param novelURL string @URL of novel
--- @return NovelInfo
local function parseNovel(novelURL)
    local url = baseURL .. novelURL
    local document = GETDocument(url)

    return NovelInfo {
        title = document:selectFirst("h1"):text(),
        description = document:selectFirst("#full-des"):text(),
        imageURL = document:selectFirst("#Cover>img"):attr("src"),
        status = ({
            Ongoing = NovelStatus.PUBLISHING,
            Completed = NovelStatus.COMPLETED,
        })[document:selectFirst(".txtItme a"):text()],
        authors = { document:selectFirst("p.txtItme:nth-child(2)"):text()},
        genres = map(document:select(".genre_list a"), text ),
        tags = map(document:select(".tag_list a"), text ),
        chapters = AsList(
                map(document:select(".comic-chapters .chapter-warp li"), function(v)
                    return NovelChapter {
                        order = v,
                        title = v:selectFirst(".item-box > div > span"):text(),
                        link = baseURL .. string.match(v:selectFirst('.item-box'):attr("onclick"), ".*'(/novel.*.html)'")
                    }
                end)
        )
    }
end

local function parseListing(listingURL)
    local document = GETDocument(listingURL)
    return map(document:select("#comic-items li"), function(v)
        return Novel {
            title = v:selectFirst(".txtA"):text(),
            link = shrinkURL(v:selectFirst("a"):attr("href")),
            imageURL = v:selectFirst("a img"):attr("src")
        }
    end)
end

local function getListing(data)
    local genre = data[GENRE_FILTER]
    local status = data[STATUS_FILTER_KEY]
    local lang = data[LANG_FILTER_KEY]
    local page = data[PAGE]
    local genreValue = ""
    local LangValue = ""
    local statusValue = ""
    if genre ~= nil then
        genreValue = GENREPARAMS[genre+1]
    end
    if lang ~= nil then
        LangValue = LANG_PARAMS[lang+1]
    end
    if status ~= nil then
        statusValue = STATUS_PARAMS[status+1]
    end
    local url = baseURL .. "/list/" .. genreValue  .. "-" .. statusValue .. "-" .. LangValue .. "/" .. page .. "/"
    return parseListing(url)
end

return {
    id = 95560,
    name = "PawRead",
    baseURL = baseURL,
    imageURL = "https://res.pawread.com/images/logo/dmzj-phone.png",
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