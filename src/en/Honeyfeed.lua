-- {"id":95565,"ver":"1.0.0","libVer":"1.0.0","author":"Confident-hate"}

local baseURL = "https://www.honeyfeed.fm"
local HoneyfeedLogo = "https://www.honeyfeed.fm/assets/main/pages/home/logo-honey-bomon-70595250eae88d365db99bd83ecdc51c917f32478fa535a6b3b6cffb9357c1b4.png"

---@param v Element
local text = function(v)
    return v:text()
end


---@param url string
---@param type int
local function shrinkURL(url)
    return url:gsub("https://www.honeyfeed.fm/", "")
end

---@param url string
---@param type int
local function expandURL(url)
    return baseURL .. "/" .. url
end

local GENRE_FILTER = 2
local GENRE_VALUES = { 
    "All",
    "Action",
    "Adventure",
    "Boys Love",
    "Comedy",
    "Crime",
    "Culinary",
    "Cyberpunk",
    "Drama",
    "Ecchi",
    "Fantasy",
    "Game",
    "Girls Love",
    "Gun Action",
    "Harem",
    "Historical",
    "Horror",
    "Isekai",
    "LGBTQ+",
    "LitRPG",
    "Magic",
    "Martial Arts",
    "Mecha",
    "Military / War",
    "Music",
    "Mystery",
    "Paranormal",
    "Philosophical",
    "Post-Apocalyptic",
    "Psychological",
    "Romance",
    "School",
    "Sci-Fi",
    "Seinen",
    "Shoujo",
    "Shounen",
    "Slice of Life",
    "Sports",
    "Supernatural",
    "Survival",
    "Thriller",
    "Time travel",
    "Tragedy",
    "Western",
}
local GENRE_PARAMS = {
    "All",
    "?genre_id=1",
    "?genre_id=2",
    "?genre_id=49",
    "?genre_id=5",
    "?genre_id=14",
    "?genre_id=6",
    "?genre_id=67",
    "?genre_id=9",
    "?genre_id=10",
    "?genre_id=11",
    "?genre_id=13",
    "?genre_id=47",
    "?genre_id=16",
    "?genre_id=17",
    "?genre_id=19",
    "?genre_id=20",
    "?genre_id=63",
    "?genre_id=72",
    "?genre_id=68",
    "?genre_id=26",
    "?genre_id=28",
    "?genre_id=29",
    "?genre_id=30",
    "?genre_id=32",
    "?genre_id=33",
    "?genre_id=70",
    "?genre_id=36",
    "?genre_id=66",
    "?genre_id=38",
    "?genre_id=40",
    "?genre_id=42",
    "?genre_id=43",
    "?genre_id=44",
    "?genre_id=46",
    "?genre_id=48",
    "?genre_id=50",
    "?genre_id=52",
    "?genre_id=53",
    "?genre_id=45",
    "?genre_id=55",
    "?genre_id=69",
    "?genre_id=65",
    "?genre_id=71"
}

local SORT_BY_FILTER = 3
local SORT_BY_VALUES = {"Monthly Ranking", "Weekly Ranking", "New Novels" }
local SORT_BY_PARAMS = {"/ranking/monthly", "/ranking/weekly", "/novels"}

local ADULT_FILTER = 4
local ADULT_VALUES = {"No", "Only"}
local ADULT_PARAMS = {"", "/nsfw"}

local searchFilters = {
    DropdownFilter(GENRE_FILTER, "Genre", GENRE_VALUES),
    DropdownFilter(SORT_BY_FILTER, "Sort By", SORT_BY_VALUES),
    DropdownFilter(ADULT_FILTER, "Adult", ADULT_VALUES)
}

--- @param chapterURL string @url of the chapter
--- @return string @of chapter
local function getPassage(chapterURL)
    local htmlElement = GETDocument(chapterURL)
    local title = htmlElement:selectFirst("h1"):text()
    htmlElement = htmlElement:selectFirst(".wrap-body")
    htmlElement:select("#wrap-button-remove-blur"):remove()
    htmlElement:child(0):before("<h1>" .. title .. "</h1>");
    return pageOfElem(htmlElement, true)
end

--- @param data table
local function search(data)
    local queryContent = data[QUERY]
    local page = data[PAGE]
    local doc = GETDocument(baseURL .. "/search/novel_title?k=" .. queryContent .. "&page=" .. page)
    return map(doc:selectFirst(".list-unit-novel"):select(".white.novel-unit-type-h.row"), function(v)
        local imgURL = HoneyfeedLogo
        local imgElement = v:selectFirst("img")
        if imgElement then
            imgURL = imgElement:attr("src")
        end
        return Novel {
            title = v:selectFirst("h3"):text(),
            imageURL = imgURL,
            link = v:selectFirst(".wrap-novel-links a"):attr("href")
        }
    end)
end

--- @param novelURL string @URL of novel
--- @return NovelInfo
local function parseNovel(novelURL)
    local url = baseURL .. novelURL
    local document = GETDocument(url)
    document:select("#wrap-button-remove-blur"):remove()
    local imgURL = HoneyfeedLogo
    local imgElement = document:selectFirst(".wrap-img-novel-mask img")
    if imgElement then
        imgURL = imgElement:attr("src")
    end
    return NovelInfo {
        title = document:selectFirst("h1"):text(),
        description = document:selectFirst(".wrap-novel-body"):text(),
        imageURL = imgURL,
        status = ({
            Ongoing = NovelStatus.PUBLISHING,
            Finished = NovelStatus.COMPLETED,
        })[document:selectFirst(".table > tbody:nth-child(1) > tr:nth-child(5) > td:nth-child(2)"):text()],
        authors = { document:selectFirst("span.text-underline > a:nth-child(1)"):text()},
        genres = map(document:select(".table > tbody:nth-child(1) > tr:nth-child(2) > td:nth-child(2) a"), text ),
        chapters = AsList(
                map(document:select("#wrap-chapter .list-chapter .list-group-item"), function(v)
                    return NovelChapter {
                        order = v,
                        title = v:selectFirst(".mr5"):text() .. v:selectFirst(".chapter-name"):text(),
                        link = baseURL .. v:attr("href")
                    }
                end)
        )
    }
end

local function parseListing(listingURL)
    local document = GETDocument(listingURL)
    return map(document:selectFirst(".list-unit-novel"):select(".white.novel-unit-type-h.row"), function(v)
        local imgURL = HoneyfeedLogo
        local imgElement = v:selectFirst("img")
        if imgElement then
            imgURL = imgElement:attr("src")
        end
        return Novel {
            title = v:selectFirst("h3"):text(),
            imageURL = imgURL,
            link = v:selectFirst(".wrap-novel-links a"):attr("href")
        }
    end)
end

local function getListing(data)
    local page = data[PAGE]
    local genre = data[GENRE_FILTER]
    local genreValue = ""
    local sortby = data[SORT_BY_FILTER]
    local sortByValue = ""
    local adult = data[ADULT_FILTER]
    local adultValue = ""
    if adult ~= nil then
        adultValue = ADULT_PARAMS[adult+1]
    end
    if genre ~= nil then
        genreValue = GENRE_PARAMS[genre+1]
    end
    if sortby ~= nil then
        sortByValue = SORT_BY_PARAMS[sortby+1]
    end
    
    local url = baseURL .. sortByValue .. genreValue .. "?page=" .. page
    if genreValue == "All" then
        url = baseURL .. sortByValue .. "?page=" .. page
    end
    if adultValue == "/nsfw" then
        url = baseURL .. adultValue .. sortByValue .. "?page=" .. page
    end
    return parseListing(url)
end

return {
    id = 95565,
    name = "Honeyfeed",
    baseURL = baseURL,
    imageURL = HoneyfeedLogo,
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