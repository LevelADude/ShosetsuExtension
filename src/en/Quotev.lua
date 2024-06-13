-- {"id":95552,"ver":"1.0.0","libVer":"1.0.0","author":"Confident-hate"}

local baseURL = "https://www.quotev.com"

---@param v Element
local function text(v)
	return v:text()
end

---@param url string
---@param type int
local function shrinkURL(url)
	return url:gsub("https://www.quotev.com", "")
end

---@param url string
---@param type int
local function expandURL(url)
	return baseURL .. url
end

local SORT_BY_FILTER_KEY = 3
local SORT_BY_VALUES = {"Default", "New Stories", "Newly Published", "Popular", "Top"}
local SORT_BY_PARAMS = {"Default", "?v=created", "?v=new", "?v=users", "?v=top"}
local CATEGORY_FILTER_KEY = 4
local CATEGORY_VALUES = {
    "Action",
    "Adventure",
    "Biography",
    "Fanfiction",
    "Fiction > Romance",
    "Fiction > Adventure",
    "Fiction > Fantasy",
    "Fiction > Mystery",
    "Fiction > Science",
    "Fiction > Action",
    "Fiction > Supernatural",
    "Fiction > Horror",
    "Fiction > Realistic",
    "Fiction > Humor",
    "Fantasy",
    "Historical",
    "Horror",
    "Humor",
    "Mystery",
    "Nonfiction",
    "Poetry",
    "Realistic",
    "Romance",
    "Science Fiction",
    "Short Stories",
    "Supernatural",
    "Thriller",
    "Other"
}

local CATEGORY_PARAMS = {
    "/stories/c/Action",
    "/stories/c/Adventure",
    "/stories/c/Biography",
    "/stories/c/Fanfiction",
    "/stories/c/Fiction/c/Romance",
    "/stories/c/Fiction/c/Adventure",
    "/stories/c/Fiction/c/Fantasy",
    "/stories/c/Fiction/c/Mystery",
    "/stories/c/Fiction/c/Science-Fiction",
    "/stories/c/Fiction/c/Action",
    "/stories/c/Fiction/c/Supernatural",
    "/stories/c/Fiction/c/Horror",
    "/stories/c/Fiction/c/Realistic",
    "/stories/c/Fiction/c/Humor",
    "/stories/c/Fantasy",
    "/stories/c/Historical",
    "/stories/c/Horror",
    "/stories/c/Humor",
    "/stories/c/Mystery",
    "/stories/c/Nonfiction",
    "/stories/c/Poetry",
    "/stories/c/Realistic",
    "/stories/c/Romance",
    "/stories/c/Science-Fiction",
    "/stories/c/Short-Stories",
    "/stories/c/Supernatural",
    "/stories/c/Thriller",
    "/stories/c/Other"
}

local searchFilters = {
    DropdownFilter(SORT_BY_FILTER_KEY, "Sort By", SORT_BY_VALUES),
    DropdownFilter(CATEGORY_FILTER_KEY, "Category", CATEGORY_VALUES)
}

--- @param chapterURL string @url of the chapter
--- @return string @of chapter
local function getPassage(chapterURL)
	local htmlElement = GETDocument(chapterURL)
    local title = htmlElement:selectFirst("title"):text():gsub(" | Quotev", "")
    htmlElement = htmlElement:selectFirst("#quizResArea .story_text")
    htmlElement:child(0):before("<h1>" .. title .. "</h1>")
    return pageOfElem(htmlElement, true)
end

local function img_src(image_element)
	local srcset = image_element:attr("data-lsrc")
	if srcset ~= "" or srcset ~= nil then
		return srcset
	end
	srcset = image_element:attr("src")
	if srcset ~= "" or srcset ~= nil then
		return srcset
	end
	return "https://i.quotev.com/q/qmz192.png"
end

--- @param data table
local function search(data)
	local queryContent = data[QUERY]
    local page = data[PAGE]
	local document = GETDocument(baseURL .. "/stories/" .. queryContent .. "?lid=0&page=" .. page)
	return map(document:select(".main_content div#main_content .cardBox .quiz"), function(v)
        local isImage = v:selectFirst("img")
        local imageLink = "https://i.quotev.com/q/qmz192.png"
        if isImage then
            imageLink = img_src(isImage)
        end
        return Novel {
            title = v:selectFirst("h2 a"):text(),
            imageURL = imageLink,
            link = shrinkURL(v:selectFirst("h2 a"):attr("href"))
        }
    end)
end

--- @param novelURL string @URL of novel
--- @return NovelInfo
local function parseNovel(novelURL)
    local url = expandURL(novelURL)
	local document = GETDocument(url)
    local isImage = document:selectFirst("img.logo")
    local imageLink = "https://i.quotev.com/q/qmz192.png"
    if isImage then
        imageLink = isImage:attr("src")
    end
	return NovelInfo {
		title = document:selectFirst("#quizHeaderTitle h1"):text(),
		description = document:selectFirst("#qdesct"):text(),
		authors = map(document:select("#quizHeaderTitle>div>a"), text ),
		imageURL = imageLink,
        genres = map(document:select("#quizHeaderTitle .quizBoxTags a"), text),
		chapters = AsList(
				map(document:select(".select select option"), function(v)
					return NovelChapter {
						order = v,
						title = v:text(),
						link = url .. "/" .. v:attr("value")
					}
				end)
		)
	}
end

local function parseListing(listingURL)
    local document = GETDocument(listingURL)
    return map(document:select(".main_content div#main_content .cardBox .quiz"), function(v)
        local isImage = v:selectFirst("img")
        local imageLink = "https://i.quotev.com/q/qmz192.png"
        if isImage then
            imageLink = img_src(isImage)
        end
        return Novel {
            title = v:selectFirst("h2 a"):text(),
            imageURL = imageLink,
            link = shrinkURL(v:selectFirst("h2 a"):attr("href"))
        }
    end)
end

local function getListing(data)
    local category = data[CATEGORY_FILTER_KEY]
    local sortBy = data[SORT_BY_FILTER_KEY]
    local page = data[PAGE]
    local sortValue = ""
    local categoryValue = ""
    if sortBy ~= nil then
        sortValue = SORT_BY_PARAMS[sortBy+1]
    end
    if category ~= nil then
        categoryValue = CATEGORY_PARAMS[category+1]
    end
    local url = ""
    if sortValue == "Default" then
        url = baseURL .. categoryValue .. "?lid=0&page=" .. page
    else
        url = baseURL .. categoryValue .. sortValue .. "&lid=0&page=" .. page
    end
    return parseListing(url)
end

return {
	id = 95552,
	name = "Quotev",
	baseURL = baseURL,
	imageURL = "https://i.quotev.com/q/qmz192.png",
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