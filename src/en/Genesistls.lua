-- {"id":95555,"ver":"1.0.3","libVer":"1.0.0","author":"Confident-hate"}

local baseURL = "https://genesistls.com"

local css = [[
    .bigcontent .infox .desc {
        display: none
    }
    
    .bigcontent .infox .mindesc {
        display: none
    }
    
    .game-prompt-info {
        min-width: 230px;
        box-sizing: content-box;
        width: fit-content;
        margin: 15px auto;
        box-shadow: 0 0 10px 1px #00219b;
        border-radius: 5px;
        font-family: 'Oswald', sans-serif;
        background-color: #000000;
        padding: 20px 20px 10px;
        line-height: 2;
        font-size: 25px;
    }
    
    .game-prompt-info-title {
        letter-spacing: 2px;
        color: #ffffff;
        font-weight: bold;
        text-shadow: -1px 5px 13px #004fff, -1px 0px 10px #002775;
        border-bottom: 3px solid #fff;
        padding-bottom: 5px;
    }
    
    .game-prompt-info-title span {
        position: relative;
        top: -4px;
    }
    
    .game-prompt-info-title span:before {
        content: " ";
    }
    
    
    .game-prompt-info-content {
        text-shadow: -1px 5px 13px #004fff, -1px 0px 10px #002775;
        color: white;
        padding-top: 10px;
    }
    
    
    .game-prompt-info-small {
        min-width: 230px;
        max-width: fit-content;
        margin: 15px auto;
        box-shadow: 0 0 10px 1px #00219b;
        border-radius: 5px;
        font-family: 'Oswald', sans-serif;
        background-color: #000000;
        padding: 10px 30px 10px 30px;
        line-height: 2;
        font-size: 25px;
    }
    
    .game-prompt-info-small-content {
        text-shadow: -1px 5px 13px #004fff, -1px 0px 10px #002775;
        color: white;
    }
    
    
    .ta-center {
        text-align: center;
    }
    
    .game-prompt-warning {
        min-width: 230px;
        padding: 20px;
        margin-top: 15px;
        margin-bottom: 15px;
        box-sizing: content-box;
        width: fit-content;
        margin-left: auto;
        margin-right: auto;
        border: solid #750b00e3;
        box-shadow: 0 0 20px 3px #750b0070;
        border-radius: 5px;
        font-family: 'Oswald', sans-serif;
        background-color: #000000;
        line-height: 2;
        font-size: 25px;
    }
    
    .game-prompt-warning-title {
        letter-spacing: 2px;
        color: #ff4348;
        font-weight: bold;
        text-shadow: -1px 5px 13px #ff230c, -1px 0px 10px #750b00;
        border-bottom: 3px solid #fff;
        padding-bottom: 5px;
    }
    
    .game-prompt-warning-title span {
        position: relative;
        top: -4px;
    }
    
    .game-prompt-warning-title span:before {
        content: " ";
    }
    
    .game-prompt-warning-content {
        text-shadow: -1px 5px 13px #ff230c, -1px 0px 10px #750b00;
        color: white;
        padding-top: 10px;
    }
    
    .genesistls-watermark {
        position: fixed;
        opacity: 0;
    }
    
    .game-prompt-gold-info {
        min-width: 230px;
        padding: 20px;
        margin-top: 15px;
        margin-bottom: 15px;
        box-sizing: content-box;
        width: fit-content;
        margin-left: auto;
        margin-right: auto;
        border: solid #e0cc00;
        box-shadow: 0 0 10px 1px #e0cc00;
        border-radius: 5px;
        font-family: 'Oswald', sans-serif;
        background-color: #000000;
        line-height: 2;
        font-size: 21px;
    }
    
    .game-prompt-gold-info-title {
        letter-spacing: 2px;
        color: white;
        font-weight: bold;
        text-shadow: -1px 5px 13px #e0cc00, -1px 0px 10px #544d00;
        border-bottom: 3px solid #fff;
        padding-bottom: 5px;
    }
    
    .game-prompt-gold-info-content {
        text-shadow: -1px 5px 13px #e0cc00, -1px 0px 10px #e0cc00;
        color: white;
        padding-top: 10px;
    }
    
    .game-prompt-silver-info {
        min-width: 230px;
        padding: 20px;
        margin-top: 15px;
        margin-bottom: 15px;
        box-sizing: content-box;
        width: fit-content;
        margin-left: auto;
        margin-right: auto;
        border: solid #c2c2c2;
        box-shadow: 0 0 10px 1px #737373;
        border-radius: 5px;
        font-family: 'Oswald', sans-serif;
        background-color: #000000;
        line-height: 2;
        font-size: 25px;
    }
    
    .game-prompt-silver-info-title {
        letter-spacing: 2px;
        color: white;
        font-weight: bold;
        text-shadow: -1px 5px 13px #b4b4b4, -1px 0px 10px #737373;
        border-bottom: 3px solid #fff;
        padding-bottom: 5px;
    }
    
    .game-prompt-silver-info-content {
        text-shadow: -1px 5px 13px #b4b4b4, -1px 0px 10px #737373;
        color: white;
        padding-top: 10px;
    }
]]

---@param v Element
local text = function(v)
    return v:text()
end


---@param url string
---@param type int
local function shrinkURL(url)
    return url:gsub("https://genesistls.com", "")
end

---@param url string
---@param type int
local function expandURL(url)
    return baseURL .. url
end

--- @param chapterURL string @url of the chapter
--- @return string @of chapter
local function getPassage(chapterURL)
    local htmlElement = GETDocument(chapterURL):selectFirst(".bixbox.episodedl")
    local title = htmlElement:selectFirst(".epheader h1"):text()
    local htmlElement = htmlElement:selectFirst(".epcontent.entry-content")
    htmlElement:child(0):before("<h1>" .. title .. "</h1>");
    htmlElement:select(".genesistls-watermark"):remove()
    htmlElement:select("br"):remove()
    local toRemove = {}
    htmlElement:traverse(NodeVisitor(function(v)
        if v:tagName() == "p" and v:text() == "" then
            toRemove[#toRemove+1] = v
        end
    end, nil, true))
    for _,v in pairs(toRemove) do
        v:remove()
    end
    return pageOfElem(htmlElement, true, css)
end

--- @param data table
local function search(data)
    local function getSearchResult(queryContent)
        return GETDocument(baseURL .. "/?s=" .. queryContent)
    end


    local queryContent = data[QUERY]
    local doc = getSearchResult(queryContent)

    return map(doc:select(".listupd .bs"), function(v)
        return Novel {
            title = v:selectFirst("a"):attr("title"),
            imageURL = v:selectFirst("a img"):attr("src"),
            link = shrinkURL(v:selectFirst("a"):attr("href"))
        }
    end)
end

--- @param novelURL string @URL of novel
--- @return NovelInfo
local function parseNovel(novelURL)
    local url = expandURL(novelURL)
    local document = RequestDocument(
            RequestBuilder()
                    :get()
                    :url(url)
                    :addHeader("Referer", "https://genesistls.com/series/")
                    :build()
    )

    return NovelInfo {
        title = document:selectFirst(".entry-title"):text(),
        description = document:select(".bixbox.synp .entry-content"):text(),
        imageURL = document:selectFirst(".thumb img"):attr("src"),
        --authors = { document:select(".spe span")[2]:text() },
        genres = map(document:select(".info-content .genxed a"), text ),
        chapters = AsList(
                map(document:select(".eplister.eplisterfull ul li"), function(v)
                    local isFree = v:selectFirst(".epl-price"):text()
                    local title = v:selectFirst(".epl-num"):text() .. " " .. v:selectFirst(".epl-title"):text()
                    if isFree == "Free" then
                        return NovelChapter {
                        order = v,
                        title = title,
                        link = v:selectFirst("a"):attr("href")
                        }
                    end
                end)
        )
    }
end


return {
    id = 95555,
    name = "Genesis Translations",
    baseURL = baseURL,
    imageURL = "https://genesistls.com/wp-content/uploads/2022/04/logo.png",
    hasSearch = true,
    listings = {
        Listing("Series Lists", false, function()
            local document = GETDocument(baseURL .. "/series/")
            return map(document:select(".listupd .bsx"), function(v)
                return Novel {
                    title = v:select("a"):attr("title"),
                    imageURL = v:select("a img"):attr("src"),
                    link = shrinkURL(v:select("a"):attr("href"))
                }
            end)
        end)
    },
    parseNovel = parseNovel,
    getPassage = getPassage,
    chapterType = ChapterType.HTML,
    search = search,
    shrinkURL = shrinkURL,
    expandURL = expandURL
}
