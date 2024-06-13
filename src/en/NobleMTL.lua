-- {"id":95567,"ver":"1.0.0","libVer":"1.0.0","author":"Confident-hate"}

local baseURL = "https://noblemtl.com/series/"

---@param v Element
local text = function(v)
    return v:text()
end

---@param url string
---@param type int
local function shrinkURL(url)
    return url:gsub("https://noblemtl.com", "")
end

---@param url string
---@param type int
local function expandURL(url)
    return "https://noblemtl.com" .. url
end

local STATUS_FILTER_KEY = 2
local STATUS_FILTER_VALUES = {"All", "Ongoing", "Completed", "Hiatus"}
local STATUS_PARAMS = {"", "ongoing", "completed", "hiatus"}

local ORDER_BY_FILTER_KEY = 3
local ORDER_BY_FILTER_VALUES = {"Default", "Latest Update", "Latest Added", "Popular", "A-Z", "Z-A"}
local ORDER_BY_PARAMS = {"", "update", "latest", "popular", "title", "titlereverse"}

local searchFilters = {
    DropdownFilter(STATUS_FILTER_KEY, "Status", STATUS_FILTER_VALUES),
    DropdownFilter(ORDER_BY_FILTER_KEY, "Order By", ORDER_BY_FILTER_VALUES)
}

--- @param chapterURL string @url of the chapter
--- @return string @of chapter
local function getPassage(chapterURL)
    local htmlElement = GETDocument(chapterURL):selectFirst(".bixbox.episodedl")
    local title = htmlElement:selectFirst(".cat-series"):text()
    local htmlElement = htmlElement:selectFirst(".epcontent.entry-content")
    htmlElement:child(0):before("<h1>" .. title .. "</h1>");
    htmlElement:select("p.a"):remove()
    htmlElement:select("br"):remove()
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
    local queryContent = data[QUERY]
    local page = data[PAGE]
    local doc = GETDocument("https://noblemtl.com/page/" .. page .. "/?s=" .. queryContent)
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
    local document = GETDocument(expandURL(novelURL))
    local chapterOrder = document:select(".eplister.eplisterfull ul li"):size()
    return NovelInfo {
        title = document:selectFirst(".entry-title"):text(),
        description = document:select(".bixbox.synp .entry-content"):text(),
        imageURL = document:selectFirst(".thumb img"):attr("data-src"),
        authors = map(document:select(".spe > span:nth-child(3) a"), text ),
        genres = map(document:select(".info-content .genxed a"), text ),
        tags = map(document:select(".bottom.tags a"), text ),
        status = ({
            Ongoing = NovelStatus.PUBLISHING,
            Completed = NovelStatus.COMPLETED,
            Hiatus = NovelStatus.PAUSED
        })[document:selectFirst(".spe > span:nth-child(1)"):text():gsub("Status: ", "")],
        chapters = AsList(
            map(document:select(".eplister.eplisterfull ul li"), function(v)
                chapterOrder = chapterOrder - 1
                local title = "[".. v:selectFirst(".epl-num"):text() .. "] " .. v:selectFirst(".epl-title"):text()
                return NovelChapter {
                order = chapterOrder,
                title = title,
                link = v:selectFirst("a"):attr("href"),
                release = v:selectFirst(".epl-date"):text()
                }
            end)
        )
    }
end

local function parseListing(listingURL)
    local document = GETDocument(listingURL)
    return map(document:select(".listupd .bsx"), function(v)
        return Novel {
            title = v:select("a"):attr("title"),
            imageURL = v:select("a img"):attr("data-src"),
            link = shrinkURL(v:select("a"):attr("href"))
        }
    end)
end

local function getListing(data)
    local orderBy = data[ORDER_BY_FILTER_KEY]
    local status = data[STATUS_FILTER_KEY]
    local page = data[PAGE]
    local orderValue = ""
    local statusValue = ""
    if orderBy ~= nil then
        orderValue = ORDER_BY_PARAMS[orderBy+1]
    end
    if status ~= nil then
        statusValue = STATUS_PARAMS[status+1]
    end
    local url = baseURL .. "?page=" .. page .. "&status=" .. statusValue .. "&order=" .. orderValue
    return parseListing(url)
end

return {
    id = 95567,
    name = "NobleMTL",
    baseURL = baseURL,
    imageURL = "https://i1.wp.com/noblemtl.com/wp-content/uploads/2022/07/cropped-Noble-270x270.png",
    hasSearch = true,
    listings = {
        Listing("Series", true, getListing)
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
