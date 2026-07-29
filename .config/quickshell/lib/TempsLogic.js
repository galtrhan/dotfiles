.pragma library

function parseTemps(data) {
    var temps = [];
    for (var chip in data) {
        var entries = data[chip];
        if (typeof entries !== "object" || entries === null)
            continue;
        for (var label in entries) {
            if (label === "Adapter")
                continue;
            var readings = entries[label];
            if (typeof readings !== "object" || readings === null)
                continue;
            for (var key in readings) {
                var match = key.match(/^temp(\d+)_input$/);
                if (!match)
                    continue;
                var value = readings[key];
                if (typeof value !== "number" || value <= 0 || value >= 200)
                    continue;
                temps.push({
                    chip: chip,
                    label: label,
                    value: value,
                    crit: readings["temp" + match[1] + "_crit"]
                });
            }
        }
    }
    return temps;
}

function findCpuTemp(temps) {
    var relevant = [];
    for (var j = 0; j < temps.length; j++) {
        var chip = temps[j].chip;
        if (chip.indexOf("coretemp") >= 0 || chip.indexOf("k10temp") >= 0 || chip.indexOf("thinkpad") >= 0) {
            var label = temps[j].label;
            if (label.indexOf("Package") >= 0 || label === "Tctl" || label === "Tdie")
                continue;
            relevant.push(temps[j].value);
        }
    }
    if (relevant.length > 0) {
        var sum = 0;
        for (var k = 0; k < relevant.length; k++)
            sum += relevant[k];
        return Math.round(sum / relevant.length);
    }
    if (temps.length === 0)
        return 0;
    var max = temps[0].value;
    for (var k = 1; k < temps.length; k++) {
        if (temps[k].value > max)
            max = temps[k].value;
    }
    return max;
}

function tempClass(temp) {
    if (temp < 40)
        return "cool";
    if (temp >= 75)
        return "critical";
    if (temp >= 60)
        return "warning";
    return "";
}

function buildTooltip(temps) {
    var sorted = temps.slice().sort(function (a, b) {
        return b.value - a.value;
    });
    var lines = [];
    for (var i = 0; i < sorted.length; i++) {
        var entry = sorted[i];
        var crit = entry.crit ? " (crit " + Math.round(entry.crit) + "°C)" : "";
        lines.push(entry.label + ": " + Math.round(entry.value) + "°C" + crit);
    }
    return lines.join("\n");
}

function rollingAverage(history, current, maxSize) {
    var next = history.slice();
    next.push(current);
    if (next.length > maxSize)
        next = next.slice(next.length - maxSize);
    var sum = 0;
    for (var i = 0; i < next.length; i++)
        sum += next[i];
    return {
        average: Math.round(sum / next.length),
        history: next
    };
}

function loadHistory(raw) {
    if (!raw)
        return [];
    try {
        var parsed = JSON.parse(raw);
        return Array.isArray(parsed) ? parsed : [];
    } catch (e) {
        return [];
    }
}
