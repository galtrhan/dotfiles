.pragma library

function stateLabel(state) {
    if (state === 1)
        return "Charging";
    if (state === 2)
        return "Discharging";
    if (state === 3)
        return "Empty";
    if (state === 4)
        return "Full";
    if (state === 5)
        return "Pending charge";
    if (state === 6)
        return "Pending discharge";
    return "Unknown";
}

function formatWh(value) {
    if (typeof value !== "number" || !isFinite(value))
        return "?";
    return value.toFixed(1) + " Wh";
}

function formatWatts(value) {
    if (typeof value !== "number" || !isFinite(value))
        return "?";
    return Math.abs(value).toFixed(1) + " W";
}

function formatDuration(seconds) {
    if (typeof seconds !== "number" || !isFinite(seconds) || seconds <= 0)
        return "";
    var total = Math.round(seconds);
    var hours = Math.floor(total / 3600);
    var minutes = Math.floor((total % 3600) / 60);
    if (hours > 0)
        return hours + "h " + minutes + "m";
    return minutes + "m";
}

// Poll lines: "BAT0 <cycles> <energy_full_uWh> <energy_full_design_uWh>"
function parsePackStats(text) {
    var map = {};
    var lines = (text || "").trim().split("\n");
    for (var i = 0; i < lines.length; i++) {
        var parts = lines[i].trim().split(/\s+/);
        if (parts.length < 4)
            continue;
        var cycles = parseInt(parts[1], 10);
        var full = parseInt(parts[2], 10);
        var design = parseInt(parts[3], 10);
        if (isNaN(cycles) || isNaN(full) || isNaN(design) || design <= 0)
            continue;
        map[parts[0]] = {
            cycles: cycles,
            fullWh: full / 1000000,
            designWh: design / 1000000,
            health: Math.round((full / design) * 100)
        };
    }
    return map;
}

function packName(device) {
    if (!device || !device.nativePath)
        return "";
    return String(device.nativePath).split("/").pop();
}

function packStats(device, statsMap) {
    if (!statsMap)
        return null;
    var name = packName(device);
    if (name && statsMap[name])
        return statsMap[name];
    // displayDevice often has an empty nativePath — use the only / first pack.
    if (statsMap.BAT0)
        return statsMap.BAT0;
    for (var key in statsMap) {
        if (statsMap.hasOwnProperty(key))
            return statsMap[key];
    }
    return null;
}

function buildTooltip(device, statsMap) {
    if (!device || !device.ready)
        return "";

    var pct = Math.round(device.percentage * 100);
    var lines = [];
    lines.push(pct + "% · " + stateLabel(device.state));

    var pack = packStats(device, statsMap);
    if (pack) {
        lines.push("Health: " + pack.health + "% (" + formatWh(pack.fullWh)
            + " / " + formatWh(pack.designWh) + ")");
        lines.push("Cycles: " + pack.cycles);
    } else if (typeof device.healthPercentage === "number" && device.healthPercentage > 0) {
        var health = device.healthPercentage;
        if (health <= 1.5)
            health *= 100;
        lines.push("Health: " + Math.round(health) + "%");
    }

    if (typeof device.energy === "number" && typeof device.energyCapacity === "number"
            && device.energyCapacity > 0) {
        lines.push("Energy: " + formatWh(device.energy) + " / " + formatWh(device.energyCapacity));
    }

    if (typeof device.changeRate === "number" && Math.abs(device.changeRate) > 0.05)
        lines.push("Rate: " + formatWatts(device.changeRate));

    var eta = "";
    if (device.state === 2 || device.state === 3)
        eta = formatDuration(device.timeToEmpty);
    else if (device.state === 1 || device.state === 5)
        eta = formatDuration(device.timeToFull);
    if (eta !== "") {
        if (device.state === 1 || device.state === 5)
            lines.push("Full in: " + eta);
        else
            lines.push("Empty in: " + eta);
    }

    if (device.model)
        lines.push("Model: " + device.model);

    lines.push("Click to expand");
    return lines.join("\n");
}
