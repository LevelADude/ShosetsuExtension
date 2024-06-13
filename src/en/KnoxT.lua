-- {"id":95571,"ver":"1.0.0","libVer":"1.0.0","author":"Confident-hate"}

local baseURL = "https://knoxt.space"

---@param v Element
local text = function(v)
    return v:text()
end


---@param url string
---@param type int
local function shrinkURL(url)
    return url:gsub("https://knoxt.space", "")
end

---@param url string
---@param type int
local function expandURL(url)
    return baseURL .. url
end

local GENRE_FILTER_KEY = 2
local GENRE_VALUES = { 
"All",
"Action",
"Adult",
"Adventure",
"Ancient Times",
"BL",
"Carefree Protagonist",
"celebrity",
"Chinese novel",
"Comedy",
"Cooking",
"Drama",
"Entertaiment circle",
"Entertainment circle",
"Fantasy",
"Fiction",
"Futuristic Setting",
"Gaming",
"Gender Bender",
"General",
"GL",
"Harem",
"Historical",
"Horror",
"Humor",
"Idol",
"Infrastructure",
"Interstellar",
"Josei",
"Love At First Sight",
"Male Protagonist",
"Martial Arts",
"Mature",
"Mecha",
"Modern",
"Mystery",
"Omegaverse",
"Otherworld fantasy",
"Psychological",
"Quick Transmigration",
"Rebirth",
"Regression",
"Reverse Harem",
"Romance",
"School Life",
"Sci-fi",
"Seinen",
"Shonen Ai",
"Shoujo",
"Shoujo Ai",
"Shounen",
"Shounen Ai",
"Showbi",
"Showbiz",
"Slice of Life",
"Smut",
"Sports",
"Supernatural",
"Tragedy",
"Transmigration",
"Unlimited flow",
"Urban Life",
"Western",
"Wu xia",
"Xianxia",
"Xuanhuan",
"Yaoi",
"Yuri"
}
local GENREPARAMS = {
"?genre=",
"?genre[]=action",
"?genre[]=adult",
"?genre[]=adventure",
"?genre[]=ancient-times",
"?genre[]=bl",
"?genre[]=carefree-protagonist",
"?genre[]=celebrity",
"?genre[]=chinese-novel",
"?genre[]=comedy",
"?genre[]=cooking",
"?genre[]=drama",
"?genre[]=entertaiment-circle",
"?genre[]=entertainment-circle",
"?genre[]=fantasy",
"?genre[]=fiction",
"?genre[]=futuristic-setting",
"?genre[]=gaming",
"?genre[]=gender-bender",
"?genre[]=general",
"?genre[]=gl",
"?genre[]=harem",
"?genre[]=historical",
"?genre[]=horror",
"?genre[]=humor",
"?genre[]=idol",
"?genre[]=infrastructure",
"?genre[]=interstellar",
"?genre[]=josei",
"?genre[]=love-at-first-sight",
"?genre[]=male-protagonist",
"?genre[]=martial-arts",
"?genre[]=mature",
"?genre[]=mecha",
"?genre[]=modern",
"?genre[]=mystery",
"?genre[]=omegaverse",
"?genre[]=otherworld-fantasy",
"?genre[]=psychological",
"?genre[]=quick-transmigration",
"?genre[]=rebirth",
"?genre[]=regression",
"?genre[]=reverse-harem",
"?genre[]=romance",
"?genre[]=school-life",
"?genre[]=sci-fi",
"?genre[]=seinen",
"?genre[]=shonen-ai",
"?genre[]=shoujo",
"?genre[]=shoujo-ai",
"?genre[]=shounen",
"?genre[]=shounen-ai",
"?genre[]=showbi",
"?genre[]=showbiz",
"?genre[]=slice-of-life",
"?genre[]=smut",
"?genre[]=sports",
"?genre[]=supernatural",
"?genre[]=tragedy",
"?genre[]=transmigration",
"?genre[]=unlimited-flow",
"?genre[]=urban-life",
"?genre[]=western",
"?genre[]=wu-xia",
"?genre[]=xianxia",
"?genre[]=xuanhuan",
"?genre[]=yaoi",
"?genre[]=yuri"
}

local STATUS_FILTER_KEY = 3
local STATUS_VALUES = { "All", "Completed", "Ongoing", "Hiatus" }
local STATUS_PARAMS = {"&status=", "&status=completed", "&status=ongoing", "&status=hiatus"}

local TYPE_FILTER_KEY = 4
local TYPE_FILTER_VALUES = {"All", "Chinese Novel", "Japanese Novel", "Kō Randō (藍銅 紅)", "Korean Novel", "Light Novel (CN)", "Original Novel", "Published Novel", "Published Novel (KR)", "Short Story", "Web Novel"}
local TYPE_PARAMS = {"&type=", "&type[]=chinese-novel", "&type[]=japanese-novel", "&type[]=ko-rando-%e8%97%8d%e9%8a%85-%e7%b4%85", "&type[]=korean-novel", "&type[]=light-novel-cn", "&type[]=original-novel", "&type[]=published-novel", "&type[]=published-novel-kr", "&type[]=short-story", "&type[]=web-novel"}

local ORDER_BY_FILTER_KEY = 5
local ORDER_BY_VALUES = { "Default", "Popular", "Latest Added", "Latest Update", "A-Z", "Z-A"}
local ORDER_BY_PARAMS = { "&order=", "&order=popular", "&order=latest", "&order=update", "&order=title", "&order=titlereverse"}

local searchFilters = {
    DropdownFilter(GENRE_FILTER_KEY, "Genre", GENRE_VALUES),
    DropdownFilter(STATUS_FILTER_KEY, "Status", STATUS_VALUES),
    DropdownFilter(TYPE_FILTER_KEY, "Type", TYPE_FILTER_VALUES),
    DropdownFilter(ORDER_BY_FILTER_KEY, "Order By", ORDER_BY_VALUES)
}

--- @param chapterURL string @url of the chapter
--- @return string @of chapter
local function getPassage(chapterURL)
    local htmlElement = GETDocument(chapterURL)
    local title = ""
    local elem_series = htmlElement:selectFirst(".cat-series")
    local elem_title = htmlElement:selectFirst(".entry-title")
    if elem_series then
        title = title .. elem_series:text() .. "<br>"
    end
    if elem_title then
        title = title .. elem_title:text()
    end
    htmlElement = htmlElement:selectFirst(".epcontent.entry-content")
    htmlElement:child(0):before("<h1>" .. title .. "</h1>");
    htmlElement:select(".code-block"):remove()
    htmlElement:select("blockquote"):remove()
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
    local page = data[PAGE]
    local url = baseURL .. "/page/" .. page .. "/?s=" .. data[QUERY]
    local document = GETDocument(url)
    return map(document:select(".listupd article"), function(v)
        return Novel {
            title = v:selectFirst(".ntitle"):text(),
            link = shrinkURL(v:selectFirst("a"):attr("href")),
            imageURL = v:selectFirst("a img"):attr("src")
        }
    end)
end

--- @param novelURL string @URL of novel
--- @return NovelInfo
local function parseNovel(novelURL)
    local url = expandURL(novelURL)
    local document = GETDocument(url)
    local chapterOrder = document:select(".eplister.eplisterfull li"):size()
    return NovelInfo {
        title = document:selectFirst(".entry-title"):text(),
        description = table.concat(map(document:select(".entry-content p"), text), "\n"),
        imageURL = document:selectFirst(".thumb img"):attr("src"),
        status = ({
            ["Status: Ongoing"] = NovelStatus.PUBLISHING,
            ["Status: Completed"] = NovelStatus.COMPLETED,
            ["Status: Hiatus"] = NovelStatus.PAUSED,
        })[document:selectFirst(".spe > span:nth-child(1)"):text()],
        authors = map(document:select(".spe > span:nth-child(3) a"), text ),--{ document:selectFirst("p.txtItme:nth-child(2)"):text()},
        genres = map(document:select(".genxed a"), text ),
        tags = map(document:select(".tags a"), text ),
        chapters = AsList(
                map(document:select(".eplister.eplisterfull li"), function(v)
                    chapterOrder = chapterOrder - 1
                    return NovelChapter {
                        order = chapterOrder,
                        title = "[" .. v:selectFirst("a .epl-num"):text() .. "] " .. v:selectFirst("a .epl-title"):text(),
                        link = v:selectFirst("a"):attr("href")
                    }
                end)
        )
    }
end

local function parseListing(listingURL)
    local document = GETDocument(listingURL)
    return map(document:select(".listupd article"), function(v)
        return Novel {
            title = v:selectFirst(".ntitle"):text(),
            link = shrinkURL(v:selectFirst("a"):attr("href")),
            imageURL = v:selectFirst("a img"):attr("src")
        }
    end)
end

local function getListing(data)
    local genre = data[GENRE_FILTER_KEY]
    local status = data[STATUS_FILTER_KEY]
    local typee = data[TYPE_FILTER_KEY]
    local order = data[ORDER_BY_FILTER_KEY]
    local page = "&page=" .. data[PAGE]
    local genreValue = ""
    local typeValue = ""
    local statusValue = ""
    local orderValue = ""
    if genre ~= nil then
        genreValue = GENREPARAMS[genre+1]
    end
    if status ~= nil then
        statusValue = STATUS_PARAMS[status+1]
    end
    if typee ~= nil then
        typeValue = TYPE_PARAMS[typee+1]
    end
    if order ~= nil then
        orderValue = ORDER_BY_PARAMS[order+1]
    end
    local url = baseURL .. "/series/" .. genreValue .. typeValue .. statusValue .. orderValue .. page
    return parseListing(url)
end

return {
    id = 95571,
    name = "KnoxT",
    baseURL = baseURL,
    imageURL = "https://knoxt.space/wp-content/uploads/2021/06/knoxtlight.jpg",
    hasSearch = true,
    listings = {
        Listing("Series", true, getListing)
    },
    parseNovel = parseNovel,
    getPassage = getPassage,
    chapterType = ChapterType.HTML,
    search = search,
    shrinkURL = shrinkURL,
    expandURL = expandURL,
    searchFilters = searchFilters
}