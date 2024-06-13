-- {"id":4223,"ver":"2.0.0","libVer":"1.0.0","author":"Doomsdayrs"}

local baseURL = "https://reaperscans.com"

local function shrinkURL(url)
	return url:match(baseURL .. "/novels/(.+)")
end

local function expandURL(url)
	return baseURL .. "/novels/" .. url
end

local function getPassage(chapterURL)
	local url = baseURL .. "/" .. chapterURL
	local document = GETDocument(url)
	local htmlElement = document:selectFirst("section.p-2")

	return pageOfElem(htmlElement, true)
end

local function parseNovel(novelURL)
	--- URL of the novel
	local url = baseURL .. "/" .. novelURL
	--- HTML document of the novel
	local document = GETDocument(url)

	--- Novel info to be constructed
	local novelInfo = NovelInfo()

	local headNChaptersSelector = "div.p-2.space-y-4"
	--- Element that contains the header & chapters
	print(document:toString():gsub("\n",""))
	local headerNChapters = document:selectFirst(headNChaptersSelector)

	--- Element that contains the cover art & title
	local headerElement = headerNChapters:selectFirst("div.mx-auto")

	--- Title element
	local titleElement = headerNChapters:selectFirst("h1")
	novelInfo:setTitle(titleElement:text())

	--- Image element
	local imageElement = headerElement:selectFirst("img")
	novelInfo:setImageURL(imageElement:attr("src"))
	
	--- Element that contains the Summary & Other information
	local aboutElement = document:selectFirst("div.lg\:col-span-1")

	--- Summary Element
	local descriptionElement = aboutElement:selectFirst("p")
	novelInfo:setDescription(descriptionElement:text():gsub("<br>","\n"))

	--- Other elements, such as source language and such forth
	local otherElements = document:selectFirst("dl.mt-2"):select("dd")

	--- Language element, listed first
	local languageElement = otherElements[0]
	novelInfo:setLanguage(languageElement:text())

	--- Status of the novel, listed second
	local statusElement = otherElements[1]
	local status = statusElement:text()
	novelInfo:setStatus(NovelStatus(status == "Completed" and 1 or status == "Ongoing" and 0 or 3))

	local chaptersBoxElementQuery = "pb-4"
	--- Element that contains the chapters
	local chaptersBoxElement = headerNChapters:selectFirst(chaptersBoxElementQuery):selectFirst("ul")

	--- pages to iterate over
	local pages = 0
	-- Pages must be determined by the amount of buttons in the navigation try, -2 for back and forward
	pages = chaptersBoxElement:selectFirst("span.relative.z-0.inline-flex"):select("span"):size() - 2

	--- total list of all chapter elements
	local chapterElements = {}

	-- Loop through the pages
	local page = 0;
	while (page < pages)
	do
		-- Only reload the page for subsequent pages, we already have the first page
		if (page ~= 0) then
			document = GETDocument(url .. "?page=" .. page):selectFirst("article.post")
		end
		headerNChapters = document:selectFirst(headNChaptersSelector)
		chaptersBoxElement = headerNChapters:selectFirst(chaptersBoxElementQuery):selectFirst("ul")
		chapterElements.concat(chaptersBoxElement:select("li"))
		page = page + 1;
		delay(100)
	end

	local count = 0
	local chapters = mapNotNil(
		chapterElements,
		function(chapter)
			-- ignore paid chapters
			if chapter:selectFirst("span") == nil then
				return nil
			end
			local c = NovelChapter()
			c:setTitle(chapter:selectFirst("p"):text())
			c:setLink(chapter:selectFirst("a"):attr("href"))

			-- count the chapters
			count = count + 1
			return c
		end
	)

	-- Reverse the chapter order
	chapters = map(
		chapters,
		function(chapter)
			chapter:setOrder(count)
			count = count - 1
			return chapter
		end
	)
	Reverse(chapters)

	novelInfo:setChapters(chapters)

	return novelInfo
end

return {
	id = 4223,
	name = "Reaper Scans",
	baseURL = baseURL,
	imageURL = "https://github.com/shosetsuorg/extensions/raw/dev/icons/ReaperScans.png",
	hasSearch = true,
	chapterType = ChapterType.HTML,

	shrinkURL = shrinkURL,
	expandURL = expandURL,

	listings = {
		Listing("Latest", true, function(data)
			local url = baseURL .. "/latest/novels"

			local d = GETDocument(url)

			return map(d:select("div.relative.flex.space-x-2"), function(v)
				local lis = Novel()
				lis:setImageURL(v:selectFirst("img"):attr("src"))
				local title = v:selectFirst("p.text-sm"):selectFirst("a")
				lis:setLink(shrinkURL(title:attr("href")))
				lis:setTitle(title:text())
				return lis
			end)
		end),
		Listing("All", true, function(data)
			local url = baseURL .. "/novels"

			local d = GETDocument(url)

			return map(d:select("li.col-span-1"), function(v)
				local lis = Novel()
				lis:setImageURL(v:selectFirst("img"):attr("src"))
				local title = v:selectFirst("p.text-sm")
				lis:setLink(shrinkURL(title:attr("href")))
				lis:setTitle(title:text())
				return lis
			end)
		end),
	},
	getPassage = getPassage,
	parseNovel = parseNovel,
	hasSearch = false
	--search = search
}
