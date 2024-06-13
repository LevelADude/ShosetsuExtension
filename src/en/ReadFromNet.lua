-- {"id":95562,"ver":"1.0.0","libVer":"1.0.0","author":"Confident-hate"}

local baseURL = "https://readfrom.net"

---@param v Element
local text = function(v)
    return v:text()
end


---@param url string
---@param type int
local function shrinkURL(url)
    return url:gsub("https://readfrom.net", "")
end

---@param url string
---@param type int
local function expandURL(url)
    return baseURL .. url
end

local GENRE_FILTER = 2
local GENRE_VALUES = {
    "All Books",
    "Romance",
    "Fiction",
    "Fantasy",
    "Young Adult",
    "Contemporary",
    "Mystery & Thrillers",
    "Science Fiction & Fantasy",
    "Paranormal",
    "Historical Fiction",
    "Mystery",
    "Science Fiction",
    "Literature & Fiction",
    "Thriller",
    "Horror",
    "Suspense",
    "Nonfiction",
    "Children's Books",
    "Historical",
    "History",
    "Crime",
    "Ebooks",
    "Children's",
    "Chick Lit",
    "Short Stories",
    "Nonfiction",
    "Humor",
    "Poetry",
    "Erotica",
    "Humor and Comedy",
    "Classics",
    "Gay and Lesbian",
    "Biography",
    "Childrens",
    "Memoir",
    "Adult Fiction",
    "Biographies & Memoirs",
    "New Adult",
    "Gay & Lesbian",
    "Womens Fiction",
    "Science",
    "Historical Romance",
    "Cultural",
    "Vampires",
    "Urban Fantasy",
    "Sports",
    "Religion & Spirituality",
    "Paranormal Romance",
    "Dystopia",
    "Politics",
    "Travel",
    "Christian Fiction",
    "Philosophy",
    "Religion",
    "Autobiography",
    "M M Romance",
    "Cozy Mystery",
    "Adventure",
    "Comics & Graphic Novels",
    "Business",
    "Polyamorous",
    "Reverse Harem",
    "War",
    "Writing",
    "Self Help",
    "Music",
    "Art",
    "Language",
    "Westerns",
    "BDSM",
    "Middle Grade",
    "Western",
    "Psychology",
    "Comics",
    "Romantic Suspense",
    "Shapeshifters",
    "Spirituality",
    "Picture Books",
    "Holiday",
    "Animals",
    "Anthologies",
    "Menage",
    "Zombies",
    "Realistic Fiction",
    "Reference",
    "LGBT",
    "Lesbian Fiction",
    "Food and Drink",
    "Mystery Thriller",
    "Outdoors & Nature",
    "Christmas",
    "Sequential Art",
    "Novels",
    "Military Fiction"
}
local GENREPARAMS = {
    "/allbooks/",
    "/romance/",
    "/fiction/",
    "/fantasy/",
    "/young-adult/",
    "/contemporary/",
    "/mystery-thrillers/",
    "/science-fiction-fantasy/",
    "/paranormal/",
    "/historical-fiction/",
    "/mystery/",
    "/science-fiction/",
    "/literature-fiction/",
    "/thriller/",
    "/horror/",
    "/suspense/",
    "/non-fiction/",
    "/children-s-books/",
    "/historical/",
    "/history/",
    "/crime/",
    "/ebooks/",
    "/children-s/",
    "/chick-lit/",
    "/short-stories/",
    "/nonfiction/",
    "/humor/",
    "/poetry/",
    "/erotica/",
    "/humor-and-comedy/",
    "/classics/",
    "/gay-and-lesbian/",
    "/biography/",
    "/childrens/",
    "/memoir/",
    "/adult-fiction/",
    "/biographies-memoirs/",
    "/new-adult/",
    "/gay-lesbian/",
    "/womens-fiction/",
    "/science/",
    "/historical-romance/",
    "/cultural/",
    "/vampires/",
    "/urban-fantasy/",
    "/sports/",
    "/religion-spirituality/",
    "/paranormal-romance/",
    "/dystopia/",
    "/politics/",
    "/travel/",
    "/christian-fiction/",
    "/philosophy/",
    "/religion/",
    "/autobiography/",
    "/m-m-romance/",
    "/cozy-mystery/",
    "/adventure/",
    "/comics-graphic-novels/",
    "/business/",
    "/polyamorous/",
    "/reverse-harem/",
    "/war/",
    "/writing/",
    "/self-help/",
    "/music/",
    "/art/",
    "/language/",
    "/westerns/",
    "/bdsm/",
    "/middle-grade/",
    "/western/",
    "/psychology/",
    "/comics/",
    "/romantic-suspense/",
    "/shapeshifters/",
    "/spirituality/",
    "/picture-books/",
    "/holiday/",
    "/animals/",
    "/anthologies/",
    "/menage/",
    "/zombies/",
    "/realistic-fiction/",
    "/reference/",
    "/lgbt/",
    "/lesbian-fiction/",
    "/food-and-drink/",
    "/mystery-thriller/",
    "/outdoors-nature/",
    "/christmas/",
    "/sequential-art/",
    "/novels/",
    "/military-fiction/"
}

local searchFilters = {
    DropdownFilter(GENRE_FILTER, "Genre", GENRE_VALUES)
}

--- @param chapterURL string @url of the chapter
--- @return string @of chapter
local function getPassage(chapterURL)
    local htmlElement = GETDocument(chapterURL)
    htmlElement = htmlElement:selectFirst("#textToRead")
    htmlElement:select(".highslide"):remove()
    htmlElement:select(".splitnewsnavigation2.ignore-select"):remove()
    return pageOfElem(htmlElement, true)
end

--- @param data table
local function search(data)
    local queryContent = data[QUERY]
    local doc = GETDocument(baseURL .. "/build_in_search/?q=" .. queryContent)
    doc:select("script"):remove()
    return map(doc:select(".box_in article"), function(v)
        return Novel {
            title = v:selectFirst("h2 b"):text(),
            imageURL = v:selectFirst("a"):attr("href"),
            link = v:selectFirst("h2 a"):attr("href")
        }
    end)
end

--- @param novelURL string @URL of novel
--- @return NovelInfo
local function parseNovel(novelURL)
    local url = baseURL .. novelURL
    local document = GETDocument(url)
    document:select("script"):remove()
    local firstChSelector = document:selectFirst(".splitnewsnavigation2.ignore-select .pages span")
    local firstChModifiedHTML = '<a href="' .. url .. '">' .. firstChSelector:text() .. '</a>'
    document:selectFirst(".splitnewsnavigation2.ignore-select .pages span"):prepend(firstChModifiedHTML)
    return NovelInfo {
        title = document:selectFirst(".title"):text():gsub(", page 1" ,""),
        imageURL = document:selectFirst(".box_in center .highslide"):attr("href"),
        chapters = AsList(
                map(document:select(".splitnewsnavigation2.ignore-select .pages a"), function(v)
                    return NovelChapter {
                        order = v,
                        title = v:selectFirst("a"):text(),
                        link = v:selectFirst('a'):attr("href")
                    }
                end)
        )
    }
end

local function parseListing(listingURL)
    local document = GETDocument(listingURL)
    return map(document:select("#dle-content article.box.story.shortstory"), function(v)
        return Novel {
            title = v:selectFirst(".title a b"):text(),
            link = shrinkURL(v:selectFirst(".title a"):attr("href")),
            imageURL = v:selectFirst(".text img"):attr("src")
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
    local url = ""
    if page~=1 then
        url = baseURL .. genreValue .. "page/" .. page .. "/"
    else
        url = baseURL .. genreValue
    end
    return parseListing(url)
end

return {
    id = 95562,
    name = "Read From Net",
    baseURL = baseURL,
    imageURL = "https://static.readfrom.net//templates/gray_search/images/logo41.png",
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