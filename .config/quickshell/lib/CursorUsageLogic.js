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

function maxUsedPercent(meters) {
    var max = 0;
    if (!meters)
        return 0;
    for (var i = 0; i < meters.length; i++)
        max = Math.max(max, usedPercent(meters[i]));
    return max;
}

function buildDisplayText(meters) {
    var included = meterPercentById(meters, "included");
    var api = meterPercentById(meters, "api");
    if (included === null && api === null)
        return "";
    if (included === null)
        included = 0;
    if (api === null)
        api = 0;
    return included + "%/" + api + "%";
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
