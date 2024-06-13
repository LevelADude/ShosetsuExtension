-- {"id":1784,"ver":"1.0.6","libVer":"1.0.0","author":"Xanvial"}

local json = Require("dkjson")

--- Identification number of the extension.
--- Should be unique. Should be consistent in all references.
---
--- Required.
---
--- @type int
local id = 1784

--- Name of extension to display to the user.
--- Should match index.
---
--- Required.
---
--- @type string
local name = "Read Light Novel.app"

--- Base URL of the extension. Used to open web view in Shosetsu.
---
--- Required.
---
--- @type string
local baseURL = "https://readlitenovel.com/"
--
--- URL of the logo.
---
--- Optional, Default is empty.
---
--- @type string
local imageURL = "https://readlightnovel.online/assets/new/images/lnrlogo.png"

--- Shosetsu tries to handle cloudflare protection if this is set to true.
---
--- Optional, Default is false.
---
--- @type boolean
local hasCloudFlare = false

--- If the website has search.
---
--- Optional, Default is true.
---
--- @type boolean
local hasSearch = true

--- If the websites search increments or not.
---
--- Optional, Default is true.
---
--- @type boolean
local isSearchIncrementing = false

--- Filters to display via the filter fab in Shosetsu.
---
--- Optional, Default is none.
---
--- @type Filter[] | Array
local searchFilters = {} -- TODO

--- Internal settings store.
---
--- Completely optional.
---  But required if you want to save results from [updateSetting].
---
--- Notice, each key is surrounded by "[]" and the value is on the right side.
--- @type table
local settings = {} -- TODO

--- Settings model for Shosetsu to render.
---
--- Optional, Default is empty.
---
--- @type Filter[] | Array
local settingsModel = {} -- TODO

--- ChapterType provided by the extension.
---
--- Optional, Default is STRING. But please do HTML.
---
--- @type ChapterType
local chapterType = ChapterType.HTML

--- Index that pages start with. For example, the first page of search is index 1.
---
--- Optional, Default is 1.
---
--- @type number
local startIndex = 1

--- Called to get list of novels from a page.
---
--- @param url string address of the page
--- @return Novel[] | Array
local function parseList(url)
	return map(GETDocument(url):select("div.cm-list > ul > li"), function(v)
		local novel = Novel()

		local categoryData = v:selectFirst("div.category-name")
		local data = categoryData:selectFirst("a")
		novel:setTitle(data:text())
		novel:setLink(data:attr("href"))

		local categoryImage = v:selectFirst("div.category-img")
		novel:setImageURL(categoryImage:selectFirst("img"):attr("src"))
		return novel
	end)
end

--- Listings that users can navigate in Shosetsu.
---
--- Required, 1 value at minimum.
---
--- @type Listing[] | Array
local listings = {
	Listing("Top Rated", true, function(data)
		--- @type int
		local page = data[PAGE]
		local url = baseURL .. "ranking/top-rated/" .. page

		return parseList(url)
	end),
	Listing("New", true, function(data)
		-- Many sites use the baseURL + some path, you can perform the URL construction here.
		-- You can also extract query data from [data]. But do perform a null check, for safety.
		--- @type int
		local page = data[PAGE]
		local url = baseURL .. "ranking/new/" .. page

		return parseList(url)
	end),
	Listing("Most Viewed", true, function(data)
		--- @type int
		local page = data[PAGE]
		local url = baseURL .. "ranking/most-viewed/" .. page

		return parseList(url)
	end)
}

--- Shrink the website url down. This is for space saving purposes.
---
--- Required.
---
--- @param url string Full URL to shrink.
--- @param type int Either KEY_CHAPTER_URL or KEY_NOVEL_URL.
--- @return string Shrunk URL.
local function shrinkURL(url, type)
	return url:gsub(baseURL, "")
end

--- Expand a given URL.
---
--- Required.
---
--- @param url string Shrunk URL to expand.
--- @param type int Either KEY_CHAPTER_URL or KEY_NOVEL_URL.
--- @return string Full URL.
local function expandURL(url, type)
	return baseURL .. url
end

--- Get a chapter passage based on its chapterURL.
---
--- Required.
---
--- @param chapterURL string The chapters shrunken URL.
--- @return string Strings in lua are byte arrays. If you are not outputting strings/html you can return a binary stream.
local function getPassage(chapterURL)
	local url = expandURL(chapterURL, KEY_CHAPTER_URL)

	--- Chapter page, extract info from it.
	local doc = GETDocument(url)
	local htmlElement = doc:selectFirst("#chapterText")
	local title = doc:selectFirst(".section-header-title > span"):text()

	htmlElement:child(0):before("<h1>" ..title .. "</h1>")

	-- Remove/modify unwanted HTML elements to get a clean webpage.
	htmlElement:select("center"):remove()
	htmlElement:select(".hidden"):remove()

	return pageOfElem(htmlElement)
end

--- Load info on a novel.
---
--- Required.
---
--- @param novelURL string shrunken novel url.
--- @return NovelInfo
local function parseNovel(novelURL)
	local doc = GETDocument(expandURL(novelURL, KEY_NOVEL_URL))
	local info = NovelInfo()
	info:setTitle(doc:selectFirst(".novel-title"):text())
	info:setImageURL(doc:selectFirst(".novels-detail-left img"):attr("src"))

	local elem = doc:select(".novels-detail-right > ul > li")
	local function meta_links(i)
		return elem:get(i):selectFirst(".novels-detail-right-in-right")
	end

	local authorList = meta_links(5):select("a")
	if (authorList:size() > 0) then
		info:setAuthors(map(authorList, function(v)
			return v:text()
		end))
	end

	local genreList = meta_links(2):select("a")
	if (genreList:size() > 0) then
		info:setGenres(map(genreList, function(v)
			return v:text()
		end))
	end
	info:setStatus( ({
		Ongoing = NovelStatus.PUBLISHING,
		Completed = NovelStatus.COMPLETED
	})[meta_links(1):text()] )

	info:setDescription(doc:selectFirst(".empty-box.gray-bg-color"):text())

	local chapters = doc:select(".novels-detail-chapters > ul > li")
	local idx = chapters:size() - 1
	local chapterTable = map(
			chapters,
			function(v)
				local chap = NovelChapter()
				chap:setLink(shrinkURL(v:selectFirst("a"):attr("href"), KEY_CHAPTER_URL))
				chap:setTitle(v:selectFirst("a"):text())
				chap:setOrder(idx)
				idx = idx - 1
				return chap
			end)

	info:setChapters(AsList(chapterTable))
	return info
end

--- Called to search for novels off a website.
---
--- Optional, But required if [hasSearch] is true.
---
--- @param data table @of applied filter values [QUERY] is the search query, may be empty.
--- @return Novel[] | Array
local function search(data)
	local query = baseURL .. "/search/autocomplete?dataType=json&query=" .. data[QUERY]
	local response = RequestDocument(GET(query, nil, nil))
	response = json.decode(response:selectFirst('body'):text())

	return map(response["results"], function(v)
		return Novel {
			title = v.original_title,
			link = shrinkURL(v.link),
			imageURL = v.image
		}
	end)
end

--- Called when a user changes a setting and when the extension is being initialized.
---
--- Optional, But required if [settingsModel] is not empty.
---
--- @param id int Setting key as stated in [settingsModel].
--- @param value any Value pertaining to the type of setting. Int/Boolean/String.
--- @return void
local function updateSetting(id, value)
	settings[id] = value
end

-- Return all properties in a lua table.
return {
	-- Required
	id = id,
	name = name,
	baseURL = baseURL,
	listings = listings, -- Must have at least one listing
	getPassage = getPassage,
	parseNovel = parseNovel,
	shrinkURL = shrinkURL,
	expandURL = expandURL,

	-- Optional values to change
	imageURL = imageURL,
	hasCloudFlare = hasCloudFlare,
	hasSearch = hasSearch,
	isSearchIncrementing = isSearchIncrementing,
	searchFilters = searchFilters,
	settings = settingsModel,
	chapterType = chapterType,
	startIndex = startIndex,

	-- Required if [hasSearch] is true.
	search = search,

	-- Required if [settings] is not empty
	-- updateSetting = updateSetting, -- TODO
}
