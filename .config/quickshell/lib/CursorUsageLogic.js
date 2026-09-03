.pragma library

function loadSnapshot(raw) {
    if (!raw)
        return null;
    try {
        var parsed = JSON.parse(raw.trim());
        return (parsed && typeof parsed === "object") ? parsed : null;
    } catch (e) {
        return null;
    }
}

function usedPercent(meter) {
    if (!meter || meter.percent === undefined || meter.percent === null)
        return 0;
    return Math.round(meter.percent * 100);
}

function meterPercentById(meters, poolId) {
    if (!meters)
        return null;
    for (var i = 0; i < meters.length; i++) {
        if (meters[i].id === poolId)
            return usedPercent(meters[i]);
    }
    return null;
}

function usageClass(usedPct) {
    if (usedPct >= 85)
        return "critical";
    if (usedPct >= 60)
        return "warning";
    return "cool";
}

function buildTooltip(snapshot) {
    if (!snapshot)
        return "";
    if (snapshot.status !== "ok")
        return snapshot.error || "Cursor usage unavailable";

    var lines = [];
    var plan = snapshot.plan || "";
    var account = snapshot.account || "";
    if (plan)
        lines.push("Plan: " + plan);
    if (account)
        lines.push(account);

    var meters = snapshot.meters || [];
    for (var i = 0; i < meters.length; i++) {
        var m = meters[i];
        var used = usedPercent(m);
        var left = 100 - used;
        lines.push(m.title + ": " + used + "% used, " + left + "% left");
    }

    return lines.join("\n");
}
