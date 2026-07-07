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

function sortEmojis(emojis, usage) {
    return emojis.slice().sort(function (a, b) {
        var freqA = usage[a.emoji] || 0;
        var freqB = usage[b.emoji] || 0;
        if (freqB !== freqA)
            return freqB - freqA;

        var nameA = (a.description || "").toLowerCase();
        var nameB = (b.description || "").toLowerCase();
        if (nameA < nameB)
            return -1;
        if (nameA > nameB)
            return 1;
        return 0;
    });
}
