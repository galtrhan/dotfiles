.pragma library

function parseTimes(fields) {
    if (!fields || fields.length < 5)
        return null;
    var nums = [];
    for (var i = 0; i < fields.length; i++) {
        var n = parseInt(fields[i], 10);
        if (isNaN(n))
            return null;
        nums.push(n);
    }
    return nums;
}

function parsePoll(text) {
    var raw = text || "";
    var parts = raw.split("---");
    var statText = parts[0] || "";
    var model = parts.length > 1 ? parts[1].trim() : "";
    var counts = parts.length > 2 ? parts[2].trim().split(/\s+/) : [];
    var cores = parseInt(counts[0], 10) || 0;
    var threads = parseInt(counts[1], 10) || 0;

    var total = null;
    var byCore = [];
    var lines = statText.split("\n");
    for (var i = 0; i < lines.length; i++) {
        var fields = lines[i].trim().split(/\s+/);
        if (fields.length < 5 || fields[0].indexOf("cpu") !== 0)
            continue;
        var times = parseTimes(fields.slice(1));
        if (!times)
            continue;
        if (fields[0] === "cpu") {
            total = times;
            continue;
        }
        var id = parseInt(fields[0].slice(3), 10);
        if (isNaN(id))
            continue;
        byCore.push({ id: id, times: times });
    }
    if (!total)
        return null;
    byCore.sort(function (a, b) {
        return a.id - b.id;
    });
    return {
        total: total,
        cores: byCore,
        model: model,
        coreCount: cores,
        threadCount: threads
    };
}

function usagePct(prevTimes, nextTimes) {
    if (!prevTimes || !nextTimes || prevTimes.length !== nextTimes.length)
        return -1;
    var totalDelta = 0;
    var idleDelta = 0;
    for (var i = 0; i < nextTimes.length; i++) {
        var d = nextTimes[i] - prevTimes[i];
        if (d < 0)
            return -1;
        totalDelta += d;
    }
    // idle + iowait
    idleDelta = (nextTimes[3] - prevTimes[3]) + (nextTimes[4] - prevTimes[4]);
    if (totalDelta <= 0)
        return 0;
    return Math.round(((totalDelta - idleDelta) / totalDelta) * 100);
}

function buildTooltip(prev, next, overallPct) {
    var lines = [];
    if (next.model)
        lines.push(next.model);
    var meta = [];
    if (next.coreCount)
        meta.push(next.coreCount + " cores");
    if (next.threadCount)
        meta.push(next.threadCount + " threads");
    if (meta.length)
        lines.push(meta.join(" / "));
    lines.push("Total: " + overallPct + "%");

    var prevById = {};
    for (var i = 0; i < prev.cores.length; i++)
        prevById[prev.cores[i].id] = prev.cores[i].times;
    for (var j = 0; j < next.cores.length; j++) {
        var core = next.cores[j];
        var before = prevById[core.id];
        if (!before)
            continue;
        var pct = usagePct(before, core.times);
        if (pct < 0)
            continue;
        lines.push("CPU" + core.id + ": " + pct + "%");
    }
    return lines.join("\n");
}

function diff(prev, next) {
    if (!prev || !next)
        return null;
    var pct = usagePct(prev.total, next.total);
    if (pct < 0)
        return null;
    return {
        pct: pct,
        text: pct + "%",
        tooltip: buildTooltip(prev, next, pct)
    };
}
