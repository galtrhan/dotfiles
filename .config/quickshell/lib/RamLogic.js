.pragma library

var warnPct = 70;

function parsePoll(text) {
    var raw = text || "";
    var sep = raw.indexOf("---");
    if (sep < 0)
        return null;

    var memTotal = 0;
    var memAvailable = 0;
    var swapTotal = 0;
    var swapFree = 0;
    var memLines = raw.slice(0, sep).split("\n");
    for (var i = 0; i < memLines.length; i++) {
        var parts = memLines[i].trim().split(/\s+/);
        if (parts.length < 2)
            continue;
        var key = parts[0].replace(":", "");
        var val = parseInt(parts[1], 10);
        if (isNaN(val))
            continue;
        if (key === "MemTotal")
            memTotal = val;
        else if (key === "MemAvailable")
            memAvailable = val;
        else if (key === "SwapTotal")
            swapTotal = val;
        else if (key === "SwapFree")
            swapFree = val;
    }
    if (!memTotal)
        return null;

    var tmpTotal = 0;
    var tmpUsed = 0;
    var dfLines = raw.slice(sep + 3).trim().split("\n");
    for (var j = 0; j < dfLines.length; j++) {
        if (dfLines[j].indexOf("Filesystem") === 0)
            continue;
        var fields = dfLines[j].trim().split(/\s+/);
        if (fields.length < 3)
            continue;
        tmpTotal = parseInt(fields[1], 10) || 0;
        tmpUsed = parseInt(fields[2], 10) || 0;
        break;
    }

    return {
        memTotal: memTotal,
        memAvailable: memAvailable,
        swapTotal: swapTotal,
        swapFree: swapFree,
        tmpTotal: tmpTotal,
        tmpUsed: tmpUsed
    };
}

function formatKib(kib) {
    var units = ["B", "K", "M", "G", "T"];
    var value = kib * 1024;
    var unit = 0;
    while (value >= 1024 && unit < units.length - 1) {
        value /= 1024;
        unit++;
    }
    if (unit === 0 || value >= 10)
        return Math.round(value) + units[unit];
    return value.toFixed(1) + units[unit];
}

function usedPct(used, total) {
    if (!total)
        return 0;
    return Math.round((Math.max(0, used) / total) * 100);
}

function buildTooltip(data, tmpPct, swapUsed) {
    var tmpLabel = data.tmpTotal ? tmpPct + "%" : "?";
    return "/tmp: " + tmpLabel + "\nSwap: " + formatKib(swapUsed) + " / " + formatKib(data.swapTotal);
}

function snapshot(text) {
    var data = parsePoll(text);
    if (!data)
        return null;
    var ramUsed = data.memTotal - data.memAvailable;
    var swapUsed = data.swapTotal - data.swapFree;
    var ramPct = usedPct(ramUsed, data.memTotal);
    var swapPct = usedPct(swapUsed, data.swapTotal);
    var tmpPct = usedPct(data.tmpUsed, data.tmpTotal);
    return {
        ramPct: ramPct,
        swapPct: swapPct,
        tmpPct: tmpPct,
        showSwap: swapPct >= warnPct,
        showTmp: tmpPct >= warnPct,
        tooltip: buildTooltip(data, tmpPct, Math.max(0, swapUsed))
    };
}
