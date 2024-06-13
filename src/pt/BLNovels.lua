-- {"id":172002,"ver":"1.0.0","libVer":"1.0.0","author":"felipebonfim2006","dep":["Madara=2.9.0"]}

return Require("Madara")("https://blnovels.net", {
    id = 172002,
    name = "BLNovels",
    imageURL = "https://blnovels.net/wp-content/uploads/2022/07/cropped-100-Sem-Ti%CC%81tulo_20220712124716-192x192.png",

    latestNovelSel = "div.col-6.col-md-3.badge-pos-2",
    novelListingURLPath = "novel",
    shrinkURLNovel = "novel",
    hasCloudFlare = true,
    hasSearch = true,
    ajaxUsesFormData = true,
    genres = {}
})
