.pragma library

function loadUsage(raw) {
    if (!raw)
        return {};
    try {
        var parsed = JSON.parse(raw);
        return (parsed && typeof parsed === "object") ? parsed : {};
    } catch (e) {
        return {};
    }
}

function recordLaunch(usage, id) {
    var next = {};
    for (var key in usage) {
        if (Object.prototype.hasOwnProperty.call(usage, key))
            next[key] = usage[key];
    }
    next[id] = (next[id] || 0) + 1;
    return next;
}

function sortApps(apps, usage) {
    return apps.slice().sort(function (a, b) {
        var freqA = usage[a.id] || 0;
        var freqB = usage[b.id] || 0;
        if (freqB !== freqA)
            return freqB - freqA;

        var nameA = (a.name || "").toLowerCase();
        var nameB = (b.name || "").toLowerCase();
        if (nameA < nameB)
            return -1;
        if (nameA > nameB)
            return 1;
        return 0;
    });
}
