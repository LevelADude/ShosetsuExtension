-- {"id":95557,"ver":"1.0.0","libVer":"1.0.0","author":"Confident-hate"}
local json = Require("dkjson")
local baseURL = "https://neovel.io/"

---@param v Element
local text = function(v)
    return v:text()
end


---@param url string
---@param type int
local function shrinkURL(url)
    return url:gsub("https://neovel.io/", "")
end

---@param url string
---@param type int
local function expandURL(url)
    return baseURL .. url
end

local ORDER_BY_FILTER = 3
local ORDER_BY_VALUES = { "Most Read", "Last Update"}
local ORDERPARAMS = {"&sort=6", "&sort=7"}
local GENRE_FILTER = 2
local GENRE_VALUES = { 
  "All Generes",
  "Fantasy",
  "Romance",
  "Action",
  "Adventure",
  "Historical",
  "Horror",
  "Sci-Fi",
  "Thriller",
  "Youth Literature",
  "Diverse Fiction"
}
local GENREPARAMS = {
    "&genreIds=0",
    "&genreIds=35",
    "&genreIds=27",
    "&genreIds=4",
    "&genreIds=23",
    "&genreIds=37",
    "&genreIds=25",
    "&genreIds=9",
    "&genreIds=40",
    "&genreIds=42",
    "&genreIds=43"
}
local STATUS_FILTER_KEY = 4
local STATUS_VALUES = { "All", "Completed", "Ongoing" }
local STATUS_PARAMS = {"&completion=5", "&completion=3", "&completion=1"}

local ADULT_FILTER_KEY = 5
local ADULT_VALUES = {"Yes", "No", "Only"}
local ADULT_PARAMS = {"&blacklistedTagIds=&onlyMature=false", "&blacklistedTagIds=797&onlyMature=false", "&blacklistedTagIds=&onlyMature=true"}

local searchFilters = {
    DropdownFilter(GENRE_FILTER, "Genre", GENRE_VALUES),
    DropdownFilter(ORDER_BY_FILTER, "Order by", ORDER_BY_VALUES),
    DropdownFilter(STATUS_FILTER_KEY, "Status", STATUS_VALUES),
    DropdownFilter(ADULT_FILTER_KEY, "Mature Content", ADULT_VALUES)
}

local genreTable = {
    [35] = "Fantasy",
    [27] = "Romance",
    [4] = "Action",
    [23] = "Adventure",
    [37] = "Historical",
    [25] = "Horror",
    [9] = "Sci-Fi",
    [40] = "Thriller",
    [42] = "Youth Literature",
    [43] = "Diverse Fiction"
}

local function intTogenre(itr)
    local t = {}
    for i, v in ipairs(itr) do
        t[#t+1] = genreTable[v]
    end
    return t
end

local function to_base64(data)
    local b = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
    return ((data:gsub('.', function(x) 
        local r,b='',x:byte()
        for i=8,1,-1 do r=r..(b%2^i-b%2^(i-1)>0 and '1' or '0') end
        return r;
    end)..'0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
        if (#x < 6) then return '' end
        local c=0
        for i=1,6 do c=c+(x:sub(i,i)=='1' and 2^(6-i) or 0) end
        return b:sub(c+1,c+1)
    end)..({ '', '==', '=' })[#data%3+1])
end

local encode = Require("url").encode


--- @param chapterURL string @url of the chapter
--- @return string @of chapter
local function getPassage(url)
    local response = RequestDocument(GET(url, nil, nil))
    response = json.decode(response:text())
    local title = response['chapterName']
    local htmlElement = Document(response['chapterContent'])
    htmlElement:child(0):before("<h1>" .. title .. "</h1>");
    return pageOfElem(htmlElement, true)
end

--- @param data table
local function search(data)
    local genre = data[GENRE_FILTER]
    local orderBy = data[ORDER_BY_FILTER]
    local status = data[STATUS_FILTER_KEY]
    local page = data[PAGE] - 1
    local adult = data[ADULT_FILTER_KEY]

    local genreValue = ""
    local orderByValue = ""
    local statusValue = ""
    local adultValue = ""

    if genre ~= nil then
        genreValue = GENREPARAMS[genre+1]
    end
    if orderBy ~= nil then
        orderByValue = ORDERPARAMS[orderBy+1]
    end
    if status ~= nil then
        statusValue = STATUS_PARAMS[status+1]
    end
    if adult ~= nil then
        adultValue = ADULT_PARAMS[adult+1]
    end
    local query = "https://neovel.io/V2/books/search?language=EN&filter=0&onlyOffline=true&genreCombining=0&tagIds=0&tagCombining=0&minChapterCount=0&maxChapterCount=9999&onlyPremium=false&name=" .. to_base64(data[QUERY]) .. "&page=" .. page .. genreValue .. orderByValue ..statusValue .. adultValue
    local response = RequestDocument(GET(query, nil, nil))
    response = json.decode(response:text())

    return map(response, function(v)
        return Novel {
            title = v.name,
            link = shrinkURL("https://neovel.io/V1/page/book?bookId=" .. v.id .. "&language=" .. v.languages[1]),
            imageURL = "https://neovel.io/V2/book/image?bookId=".. v.id .."&oldApp=false&imageExtension=2"
        }
    end)

end

--- @param novelURL string @URL of novel
--- @return NovelInfo
local function parseNovel(novelURL)
    local url = baseURL .. novelURL
    local response = RequestDocument(GET(url, nil, nil))
    response = json.decode(response:text())
    local churl = "https://neovel.io/V5/chapters?bookId=" .. response["bookDto"].id .. "&language=EN"
    local chResponse = RequestDocument(GET(churl, nil, nil))
    chResponse = json.decode(chResponse:text())
    return NovelInfo {
        title = response["bookDto"].name,
        description = response["bookDto"].bookDescription,
        imageURL = "https://neovel.io/V2/book/image?bookId=".. response["bookDto"].id .."&oldApp=false&imageExtension=2",
        status = ({
            [1] = NovelStatus.PUBLISHING,
            [3] = NovelStatus.COMPLETED,
            [2] = NovelStatus.PAUSED,
        })[response["bookDto"].completion],
        authors = { response["bookDto"].authors[1] },
        genres = intTogenre(response["bookDto"].genreIds),
        chapters = AsList(
                map(chResponse, function(v)
                    return NovelChapter {
                        order = v,
                        title = "Vol. " .. v.chapterVolume .. " Ch. " .. v.chapterNumber .. " " .. v.chapterName,
                        link = "https://neovel.io/V2/chapter/content?chapterId=" .. v.chapterId
                    }
                end)
        )
    }
end


local function parseListing(listingURL)
    local response = RequestDocument(GET(listingURL, nil, nil))
    response = json.decode(response:text())
    return map(response, function(v)
        return Novel {
            title = v.name,
            link = shrinkURL("https://neovel.io/V1/page/book?bookId=" .. v.id .. "&language=" .. v.languages[1]),
            imageURL = "https://neovel.io/V2/book/image?bookId=".. v.id .."&oldApp=false&imageExtension=2"
        }
    end)
end


local function getListing(data)
    local genre = data[GENRE_FILTER]
    local orderBy = data[ORDER_BY_FILTER]
    local status = data[STATUS_FILTER_KEY]
    local page = data[PAGE] - 1
    local adult = data[ADULT_FILTER_KEY]

    local genreValue = ""
    local orderByValue = ""
    local statusValue = ""
    local adultValue = ""

    if genre ~= nil then
        genreValue = GENREPARAMS[genre+1]
    end
    if orderBy ~= nil then
        orderByValue = ORDERPARAMS[orderBy+1]
    end
    if status ~= nil then
        statusValue = STATUS_PARAMS[status+1]
    end
    if adult ~= nil then
        adultValue = ADULT_PARAMS[adult+1]
    end
    local url = "https://neovel.io/V2/books/search?language=EN&filter=0&name=&onlyOffline=true&genreCombining=0&tagIds=0&tagCombining=0&minChapterCount=0&maxChapterCount=9999&onlyPremium=false&page=" .. page .. genreValue .. orderByValue ..statusValue .. adultValue
    return parseListing(url)
end



return {
    id = 95557,
    name = "Neovel",
    baseURL = baseURL,
    imageURL = "https://neovel.io/apple-touch-icon.png",
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