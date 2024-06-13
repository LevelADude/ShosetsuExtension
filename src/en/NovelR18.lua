-- {"id":95561,"ver":"1.0.1","libVer":"1.0.0","author":"Confident-hate"}

local baseURL = "https://novelr18.com"

---@param v Element
local text = function(v)
    return v:text()
end


---@param url string
---@param type int
local function shrinkURL(url)
    return url:gsub("https://novelr18.com/", "")
end

---@param url string
---@param type int
local function expandURL(url)
    return baseURL .. "/" .. url
end

local SORT_BY_FILTER_KEY = 5
local SORT_BY_VALUES = {"Relevance", "Latest Update", "A-Z", "Rating", "Most Viewes", "Newly Added" }
local SORT_BY_PARAMS = {"m_orderby", "m_orderby=latest", "m_orderby=alphabet", "m_orderby=rating", "m_orderby=views", "m_orderby=new-manga"}

local TYPE_FILTER_KEY = 4
local TYPE_FILTER_VALUES = {"Default", "Fanfiction", "Original", "Japan", "Korea", "China", "MTL" }
local TYPE_PARAMS = {"Default", "manga-genre/fanfiction/", "manga-genre/original/", "manga-genre/japan/", "manga-genre/korea/", "manga-genre/china/", "manga-genre/mtl/"}

local searchFilters = {
    DropdownFilter(SORT_BY_FILTER_KEY, "Sort By", SORT_BY_VALUES),
    DropdownFilter(TYPE_FILTER_KEY, "Type", TYPE_FILTER_VALUES)
}

--- @param chapterURL string @url of the chapter
--- @return string @of chapter
local function getPassage(chapterURL)
    local htmlElement = GETDocument(chapterURL)
    local title = htmlElement:selectFirst("h1"):text()
    htmlElement = htmlElement:selectFirst(".read-container")
    htmlElement:select(".ai-rotate"):remove()
    local toRemove = {}
    htmlElement:traverse(NodeVisitor(function(v)
        if v:tagName() == "p" and v:text() == "" then
            toRemove[#toRemove+1] = v
        end
    end, nil, true))
    for _,v in pairs(toRemove) do
        v:remove()
    end
    local ht = "<h1>" .. title .. "</h1>"
    local pTagList = ""
    pTagList = map(htmlElement:select("p"), text)
    for k,v in pairs(pTagList) do ht = ht .. "<br><br>" .. v end
    return pageOfElem(Document(ht), true)
end

--- @param data table
local function search(data)
    local queryContent = data[QUERY]
    local page = data[PAGE]
    local pageParam = ""
    if page ~= 1 then
        pageParam = "page/" .. page .. "/"
    end
    local sortBy = data[SORT_BY_FILTER_KEY]
    local sortValue = ""
    if sortBy ~= nil then
        sortValue = "&" .. SORT_BY_PARAMS[sortBy+1]
    end
    local doc = GETDocument("https://novelr18.com/" .. pageParam .. "?s=" .. queryContent .. "&post_type=wp-manga".. sortValue)

    return map(doc:select(".tab-content-wrap .c-tabs-item .row.c-tabs-item__content"), function(v)
        return Novel {
            title = v:selectFirst(".col-8.col-md-10 .post-title"):text(),
            imageURL = v:selectFirst(".col-4.col-md-2 img"):attr("data-src"),
            link = v:selectFirst(".col-8.col-md-10 .post-title a"):attr("href")
        }
    end)
end

local function parseNovelDescription(document)
    local summaryContent = document:selectFirst("div.summary__content")
    if summaryContent then
		return table.concat(map(document:selectFirst("div.summary__content"):select("p"), text), "\n\n")
    end
    return ""
end

--- @param novelURL string @URL of novel
--- @return NovelInfo
local function parseNovel(novelURL)
    local url = baseURL .. "/" .. novelURL
    local document = GETDocument(url)
    document:select(".ai-rotate"):remove()
    local chapterURL = url .. "ajax/chapters/"
    local chapterDoc = RequestDocument(POST(chapterURL, nil, nil))
    local chapterOrder = chapterDoc:select(".wp-manga-chapter"):size()
    return NovelInfo {
        title = document:selectFirst("h1"):text(),
        description = parseNovelDescription(document),
        imageURL = document:selectFirst(".summary_image a img"):attr("data-src"),
        status = ({
            OnGoing = NovelStatus.PUBLISHING,
            Completed = NovelStatus.COMPLETED,
            Canceled = NovelStatus.PAUSED,
            ["On Hold"] = NovelStatus.PAUSED
        })[document:selectFirst(".post-status .summary-content"):text()],
        authors = { document:selectFirst(".author-content"):text()},
        genres = map(document:select(".genres-content a"), text ),
        chapters = AsList(
                map(chapterDoc:select(".wp-manga-chapter"), function(v)
                    chapterOrder = chapterOrder - 1
                    return NovelChapter {
                        order = chapterOrder,
                        title = v:selectFirst("a"):text(),
                        link = v:selectFirst("a"):attr("href")
                    }
                end)
        )
    }
end

local function parseListing(listingURL)
    local document = GETDocument(listingURL)
    return map(document:select(".page-listing-item .page-item-detail"), function(v)
        return Novel {
            title = v:selectFirst("a"):attr("title"),
            link = shrinkURL(v:selectFirst("a"):attr("href")),
            imageURL = v:selectFirst("a img"):attr("data-src")
        }
    end)
end

local function getListing(data)
    local typee = data[TYPE_FILTER_KEY]
    local sortBy = data[SORT_BY_FILTER_KEY]
    local page = data[PAGE]
    local sortValue = ""
    local typeValue = ""
    local pageParam = ""
    if sortBy ~= nil then
        sortValue = "?" .. SORT_BY_PARAMS[sortBy+1]
    end
    if typee ~= nil then
        typeValue = TYPE_PARAMS[typee+1]
    end
    if page ~= 1 then
        pageParam = "page/" .. page .. "/"
    end
    local url = ""
    if typeValue == "Default" then
        url = baseURL .. "/novel/" .. pageParam .. sortValue
    else
        url = baseURL .. "/" .. typeValue .. pageParam .. sortValue
    end
    return parseListing(url)
end

return {
    id = 95561,
    name = "Novelr18",
    baseURL = baseURL,
    imageURL = "https://novelr18.com/wp-content/uploads/2017/10/logo_-1.png",
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