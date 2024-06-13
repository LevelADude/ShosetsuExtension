-- {"id":4303,"ver":"2.0.0","libVer":"1.0.0","author":"MechTechnology"}

local baseURL = "https://www.novelhold.com"

-- Filter Keys & Values
local STATUS_FILTER = 2
local STATUS_VALUES = { "All", "Ongoing", "Completed" }
local STATUS_TERMS = { "", "active", "completed" }
local ORDER_BY_FILTER = 3
local ORDER_BY_VALUES = { "Latest Update", "Most Views", "Month Views", "Week Views", "New" }
local ORDER_BY_TERMS = { "updatetime", "hits", "month_hits", "rating", "inputtime" }
local GENRE_FILTER = 4
local GENRE_VALUES = { 
  "All",
  "Romance",
  "Fantasy",
  "Action",
  "Modern",
  "CEO",
  "Romantic",
  "Adult",
  "Drama",
  "Urban",
  "Historical",
  "Harem",
  "Game",
  "Xianxia",
  "Josei",
  "Adventure",
  "Mature"
}

local searchFilters = {
	DropdownFilter(ORDER_BY_FILTER, "Order by", ORDER_BY_VALUES),
	DropdownFilter(STATUS_FILTER, "Status", STATUS_VALUES),
	DropdownFilter(GENRE_FILTER, "Genre", GENRE_VALUES)
}

local encode = Require("url").encode

local text = function(v)
	return v:text()
end

local function shrinkURL(url)
	return url:gsub("^.-novelhold%.com", "")
end

local function expandURL(url)
	return baseURL .. url
end

local function paragraphSplit(content)
	-- This is for the sake of consistant styling
	content:select("br:nth-child(even)"):remove()
	content = tostring(content):gsub("<div", "<p"):gsub("</div", "</p"):gsub("<br>", "</p><p>")
	content = Document(content):selectFirst("body")
	return content
end

local function getPassage(chapterURL)
	local chap = GETDocument(expandURL(chapterURL)):selectFirst(".container .mybox .txtnav")
	local title = chap:selectFirst("h1"):text()
	chap = paragraphSplit(chap:selectFirst(".content"))
	-- Adds Chapter Title
	chap:child(0):before("<h1>" .. title .. "</h1>")
	return pageOfElem(chap, true)
end

local function parseNovel(novelURL, loadChapters)
	local content = GETDocument(expandURL(shrinkURL(novelURL))):selectFirst(".container .row")
	local details = content:selectFirst(".booknav2")
	local description = paragraphSplit(content:selectFirst(".mybox:nth-child(2) .tabsnav .navtxt"))
	-- Note: "：" the colon space character is a special unicode for some reason. 
	local info = NovelInfo {
		title = details:selectFirst("h1"):text(),
		imageURL = content:selectFirst(".bookbox"):selectFirst("img"):attr("src"),
		status = ({
			completed = NovelStatus.COMPLETED,
			Active = NovelStatus.PUBLISHING
		})[details:child(4):text():gsub("^.-Status%：", "")],
		description = table.concat(map(description:select("p"), text), "\n"),
		authors = { tostring(details:child(1):text():gsub("^.-Author%：", "")) },
		genres = { tostring(details:child(3):text():gsub("^.-Genre%：", "")) },
	}

	if loadChapters then
		local chapters = (map(content:selectFirst(".mybox:nth-child(3) .tabsnav .qustime:nth-child(2)"):select("li"), function(v, i)
			local a = v:selectFirst("a")
			return NovelChapter {
				order = i,
				title = a:text(),
				link = shrinkURL(a:attr("href")),
			}
		end))
		info:setChapters(AsList(chapters))
	end
	return info
end

local function parseListing(listingURL)
	local content = GETDocument(listingURL):selectFirst("#article_list_content")
	return map(content:select("li"), function(v)
		local a = v:selectFirst("h3"):selectFirst("a")
		return Novel {
			title = a:text(),
			link = shrinkURL(a:attr("href")),
			imageURL = v:selectFirst("img"):attr("data-src")
		}
	end)
end

local function getSearch(data)
	local query = data[QUERY]
	local page = data[PAGE]
	local url = "/index.php?s=so&module=book&keyword=" .. query .. "&page=" .. page
	return parseListing(expandURL(url))
end

local function getListing(data)
	-- Filters only work with the listing, their search does not support them.
	local page = data[PAGE] 
	local genre = data[GENRE_FILTER]
	local status = data[STATUS_FILTER]
	local orderBy = data[ORDER_BY_FILTER]

	local genreValue = ""
	if genre ~= nil and genre ~= 0 then
		genreValue = GENRE_VALUES[genre+1]:lower()
	end
	local statusValue = ""
	if status ~= nil then
		statusValue = STATUS_TERMS[status+1]
	end
	local orderByValue = ""
	if orderBy ~= nil then
		orderByValue = ORDER_BY_TERMS[orderBy+1]
	end

	local url = "/search-" .. genreValue .. "-" .. statusValue .. "-" .. orderByValue .. "-" .. page .. ".html"
	return parseListing(expandURL(url))
end

return {
	id = 4303,
	name = "Mylovenovel",
	baseURL = baseURL,
	imageURL = "https://github.com/shosetsuorg/extensions/raw/dev/icons/Mylovenovel.png",
	chapterType = ChapterType.HTML,

	listings = {
		Listing("Latest", true, getListing)
	},
	getPassage = getPassage,
	parseNovel = parseNovel,
	
	hasSearch = true,
	isSearchIncrementing = true,
	search = getSearch,
	searchFilters = searchFilters,

	shrinkURL = shrinkURL,
	expandURL = expandURL
}
