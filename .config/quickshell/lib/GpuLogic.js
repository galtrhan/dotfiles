.pragma library

var showPct = 25;

function parsePoll(text) {
    var raw = (text || "").trim();
    if (!raw || raw.indexOf("none") === 0)
        return null;

    var parts = raw.split("---");
    if (parts.length < 5)
        return null;

    var kind = parts[0].trim();
    var stats = parts[1].trim().split(/\s+/);
    var freqs = parts[2].trim().split(/\s+/);
    var name = parts[3].trim();
    var engines = parts[4].trim();
    var vram = parts.length > 5 ? parts[5].trim().split(/\s+/) : ["-", "-"];

    var sample = {
        kind: kind,
        name: name,
        engines: engines,
        actMhz: parseInt(freqs[0], 10) || 0,
        maxMhz: parseInt(freqs[1], 10) || 0,
        busy: -1,
        rc6: 0,
        ts: 0,
        vramUsed: 0,
        vramTotal: 0
    };

    if (kind === "intel") {
        sample.rc6 = parseInt(stats[0], 10) || 0;
        sample.ts = parseInt(stats[1], 10) || 0;
        if (!sample.ts)
            return null;
    } else if (kind === "amd" || kind === "nvidia") {
        sample.busy = parseInt(stats[0], 10);
        if (isNaN(sample.busy))
            return null;
    } else {
        return null;
    }

    if (vram[0] !== "-" && vram[1] !== "-") {
        sample.vramUsed = parseInt(vram[0], 10) || 0;
        sample.vramTotal = parseInt(vram[1], 10) || 0;
    }

    return sample;
}

function intelBusy(prev, next) {
    if (!prev || !next || next.ts <= prev.ts)
        return -1;
    var dt = next.ts - prev.ts;
    var dr = next.rc6 - prev.rc6;
    if (dr < 0)
        return -1;
    var idleFrac = Math.min(1, dr / dt);
    return Math.round((1 - idleFrac) * 100);
}

function formatBytes(bytes) {
    var units = ["B", "K", "M", "G", "T"];
    var value = bytes;
    var unit = 0;
    while (value >= 1024 && unit < units.length - 1) {
        value /= 1024;
        unit++;
    }
    if (unit === 0 || value >= 10)
        return Math.round(value) + units[unit];
    return value.toFixed(1) + units[unit];
}

function vramPct(sample) {
    if (!sample || !sample.vramTotal)
        return -1;
    return Math.round((sample.vramUsed / sample.vramTotal) * 100);
}

function buildTooltip(sample, busyPct) {
    var lines = [];
    if (sample.name)
        lines.push(sample.name);
    lines.push("Busy: " + busyPct + "%");
    if (sample.actMhz || sample.maxMhz)
        lines.push("Freq: " + sample.actMhz + " / " + sample.maxMhz + " MHz");
    if (sample.engines)
        lines.push("Engines: " + sample.engines);
    if (sample.vramTotal)
        lines.push("VRAM: " + formatBytes(sample.vramUsed) + " / " + formatBytes(sample.vramTotal));
    return lines.join("\n");
}

function diff(prev, sample) {
    if (!sample)
        return null;

    var pct = sample.busy;
    if (sample.kind === "intel") {
        if (!prev || prev.kind !== "intel")
            return null;
        pct = intelBusy(prev, sample);
    }
    if (pct < 0)
        return null;

    var show = pct >= showPct;
    var memPct = vramPct(sample);
    return {
        pct: pct,
        text: show ? pct + "%" : "",
        vramPct: memPct,
        showVram: show && memPct >= 0,
        tooltip: show ? buildTooltip(sample, pct) : ""
    };
}
