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

var monthNames = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];

function parseRenewalDate(iso) {
    if (!iso || typeof iso !== "string")
        return null;
    var dateOnly = iso.match(/^(\d{4})-(\d{2})-(\d{2})$/);
    if (dateOnly)
        return new Date(+dateOnly[1], +dateOnly[2] - 1, +dateOnly[3]);
    var end = new Date(iso);
    if (isNaN(end.getTime()))
        return null;
    return end;
}

function renewal(iso) {
    var end = parseRenewalDate(iso);
    if (!end)
        return null;
    var today = new Date();
    var endDay = Date.UTC(end.getFullYear(), end.getMonth(), end.getDate());
    var todayDay = Date.UTC(today.getFullYear(), today.getMonth(), today.getDate());
    return {
        days: Math.round((endDay - todayDay) / 86400000),
        dateLabel: end.getDate() + " " + monthNames[end.getMonth()] + " " + end.getFullYear()
    };
}

function renewalLine(iso) {
    var info = renewal(iso);
    if (!info)
        return "";
    var when = "";
    if (info.days > 1)
        when = info.days + " days left";
    else if (info.days === 1)
        when = "1 day left";
    else if (info.days === 0)
        when = "today";
    var line = "Renews " + info.dateLabel;
    if (when)
        line += " (" + when + ")";
    return line;
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

    var renews = renewalLine(snapshot.renewsAt);
    if (renews)
        lines.push(renews);

    return lines.join("\n");
}
