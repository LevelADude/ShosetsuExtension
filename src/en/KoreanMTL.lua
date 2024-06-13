-- {"id":95569,"ver":"1.0.0","libVer":"1.0.0","author":"Confident-hate"}

local baseURL = "https://www.koreanmtl.online"

---@param v Element
local text = function(v)
    return v:text()
end

---@param url string
---@param type int
local function shrinkURL(url)
    return url:gsub("https://www.koreanmtl.online", ""):gsub("https://koreannovelmtl.blogspot.com", "")
end

---@param url string
---@param type int
local function expandURL(url)
    return baseURL .. url
end

--- @param chapterURL string @url of the chapter
--- @return string @of chapter
local function getPassage(chapterURL)
    local htmlElement = GETDocument(expandURL(chapterURL))
    local title = htmlElement:selectFirst(".post h3"):text()
    local htmlElement = htmlElement:selectFirst(".post-body")
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

--- @param novelURL string @URL of novel
--- @return NovelInfo
local function parseNovel(novelURL)
    local document = GETDocument(expandURL(novelURL))
    return NovelInfo {
        title = document:selectFirst(".post-title.entry-title"):text(),
        description = table.concat(map(document:selectFirst(".post-body"):select("p"), text), "\n"),
        chapters = AsList(
            map(document:select(".a li"), function(v)
                return NovelChapter {
                order = v,
                title = v:selectFirst("a"):text(),
                link = shrinkURL(v:selectFirst("a"):attr("href"))
                }
            end)
        )
    }
end

return {
    id = 95569,
    name = "KoreanMTL",
    baseURL = baseURL,
    imageURL = "https://i.imgur.com/Zsvoiom.png",
    hasSearch = false,
    listings = {
        Listing("Listing", false, function()
            local document = GETDocument(baseURL .. "/p/novels-listing.html")
            return map(document:select(".a li"), function(v)
                return Novel {
                    title = v:selectFirst("a"):text(),
                    link = shrinkURL(v:selectFirst("a"):attr("href"))
                }
            end)
        end)
    },
    parseNovel = parseNovel,
    getPassage = getPassage,
    chapterType = ChapterType.HTML,
    shrinkURL = shrinkURL,
    expandURL = expandURL
}