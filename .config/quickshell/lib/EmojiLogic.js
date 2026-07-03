.pragma library

function buildSearchText(entry) {
    var parts = [entry.emoji, entry.description || ""];
    if (entry.aliases)
        parts = parts.concat(entry.aliases);
    if (entry.tags)
        parts = parts.concat(entry.tags);
    return parts.join(" ").toLowerCase();
}

function normalizeEntry(entry) {
    return {
        emoji: entry.emoji,
        description: entry.description || "",
        searchText: buildSearchText(entry)
    };
}

function parseEmojiFile(text) {
    var raw = JSON.parse(text);
    return raw.map(normalizeEntry);
}

function filterEmojis(emojis, query) {
    var q = query.trim().toLowerCase();
    if (q === "")
        return emojis;

    return emojis.filter(function (entry) {
        return entry.searchText.indexOf(q) !== -1;
    });
}
