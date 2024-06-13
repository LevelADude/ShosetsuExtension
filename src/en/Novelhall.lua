-- {"id":95570,"ver":"1.0.0","libVer":"1.0.0","author":"Confident-hate"}

local baseURL = "https://www.novelhall.com"

---@param v Element
local text = function(v)
    return v:text()
end


---@param url string
---@param type int
local function shrinkURL(url)
    return url:gsub("https://www.novelhall.com/", "")
end

---@param url string
---@param type int
local function expandURL(url)
    return baseURL .. url
end

local GENRE_FILTER = 2
local GENRE_VALUES = { 
"Romance",
"Fantasy",
"Romantic",
"Modern Romance",
"CEO",
"Urban",
"Billionaire",
"Action",
"Modern Life",
"Historical Romance",
"Game",
"Xianxia",
"Sci-fi",
"Historical",
"Drama",
"Fantasy Romance",
"Urban Life",
"Adult",
"Comedy",
"Harem",
"Farming",
"Military",
"Adventure",
"Wuxia",
"Games",
"Son-In-Law",
"Ecchi",
"Josei",
"School Life",
"Mystery"
}
local GENREPARAMS = {
"/romance20223/",
"/fantasy20223/",
"/romantic3/",
"/modern_romance/",
"/ceo2022/",
"/urban/",
"/billionaire20223/",
"/action3/",
"/modern_life/",
"/historical_romance2023/",
"/game20233/",
"/xianxia2022/",
"/scifi/",
"/historical2023/",
"/drama20233/",
"/fantasy_romance/",
"/urban_life/",
"/adult/",
"/comedy3/",
"/harem20223/",
"/farming2023/",
"/military2023/",
"/adventure/",
"/wuxia/",
"/games3/",
"/soninlaw2022/",
"/ecchi/",
"/josei/",
"/school_life/",
"/mystery/"
}

local searchFilters = {
    DropdownFilter(GENRE_FILTER, "Genre", GENRE_VALUES)
}

--- @param chapterURL string @url of the chapter
--- @return string @of chapter
local function getPassage(chapterURL)
    local htmlElement = GETDocument(expandURL(chapterURL))
    htmlElement = htmlElement:selectFirst("#htmlContent")
    return pageOfElem(htmlElement, true)
end

--- @param data table
local function search(data)
    local queryContent = data[QUERY]
    local doc = GETDocument(baseURL .. "/index.php?s=so&module=book&keyword=" .. queryContent)
    doc:select(".hidden-xs"):remove()
    doc:select(".w30"):remove()
    return map(doc:select("tbody tr td"), function(v)
        return Novel {
            title = v:selectFirst("a"):text(),
            link = v:selectFirst("a"):attr("href")
        }
    end)
end

--- @param novelURL string @URL of novel
--- @return NovelInfo
local function parseNovel(novelURL)
    local document = GETDocument(expandURL(novelURL))
    return NovelInfo {
        title = document:selectFirst(".book-info h1"):text(),
        description = document:selectFirst(".intro .js-close-wrap"):text(),
        imageURL = document:selectFirst(".book-img img"):attr("src"),
        chapters = AsList(
                map(document:selectFirst("#morelist"):select("li"), function(v)
                    return NovelChapter {
                        order = v,
                        title = v:selectFirst("a"):text(),
                        link = v:select("a"):attr("href")
                    }
                end)
        )
    }
end

local function parseListing(listingURL)
    local document = GETDocument(listingURL)
    return map(document:select(".w70"), function(v)
        return Novel {
            title = v:selectFirst("a"):text(),
            link = shrinkURL(v:selectFirst("a"):attr("href"))
        }
    end)
end

local function getListing(data)
    local genre = data[GENRE_FILTER]
    local page = data[PAGE]
    local genreValue = ""
    if genre ~= nil then
        genreValue = GENREPARAMS[genre+1]
    end
    local url = baseURL .. "/genre" .. genreValue .. page .. "/"
    return parseListing(url)
end

return {
    id = 95570,
    name = "Novelhall",
    baseURL = baseURL,
    imageURL = "https://www.novelhall.com/statics/default/images/logo.b5b4c.png",
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