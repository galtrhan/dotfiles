.pragma library

var memWarnPct = 35;
var tmpWarnPct = 70;

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

function buildTooltip(data, tmpPct, ramUsed, swapUsed) {
    var tmpLabel = data.tmpTotal ? tmpPct + "%" : "?";
    return "/tmp: " + tmpLabel
        + "\nRAM: " + formatKib(ramUsed) + " / " + formatKib(data.memTotal)
        + "\nSwap: " + formatKib(swapUsed) + " / " + formatKib(data.swapTotal)
        + "\nLeft click: top RAM";
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
    var showRam = ramPct >= memWarnPct;
    var showSwap = swapPct >= memWarnPct;
    var showTmp = tmpPct >= tmpWarnPct;
    var showMem = showRam || showSwap;
    var parts = [];
    if (showRam)
        parts.push(ramPct + "%");
    if (showSwap)
        parts.push(swapPct + "%");
    return {
        tmpPct: tmpPct,
        showMem: showMem,
        showTmp: showTmp,
        text: parts.join("/"),
        fillPct: Math.max(showRam ? ramPct : 0, showSwap ? swapPct : 0),
        tooltip: (showMem || showTmp) ? buildTooltip(data, tmpPct, Math.max(0, ramUsed), Math.max(0, swapUsed)) : ""
    };
}

var topConsumerCount = 10;

// Helpers that inherit the parent's app name when grouping.
var genericComms = {
    "electron": true,
    "chrome_crashpad": true,
    "mainthread": true,
    "node-mainthread": true,
    "isolated web co": true,
    "isolated servic": true,
    "web content": true,
    "webextensions": true,
    "rdd process": true,
    "socket process": true,
    "utility process": true,
    "privileged cont": true,
    "zygote": true,
    "broker": true,
    "gpu process": true,
    "renderer": true,
    "forkserver": true
};

function buildProcessTooltip(exePath, childCount, parentName, processCount) {
    var lines = [];
    if (exePath)
        lines.push("Path: " + exePath);
    if (childCount > 0)
        lines.push("Children: " + childCount);
    else if (processCount > 1)
        lines.push("Processes: " + processCount);
    if (parentName)
        lines.push("Parent: " + parentName);
    return lines.join("\n");
}

function basenamePath(path) {
    if (!path)
        return "";
    var parts = path.split("/");
    return parts[parts.length - 1] || path;
}

function firstArg(args) {
    var text = (args || "").trim();
    if (!text)
        return "";
    var match = text.match(/^(\S+)/);
    return match ? match[1] : "";
}

function exeFromArgs(args) {
    var first = firstArg(args);
    if (!first || first.charAt(0) !== "/")
        return "";
    if (first.indexOf("/proc/") === 0)
        return "";
    return first;
}

function isGenericName(name) {
    return !!(name && genericComms[String(name).toLowerCase()]);
}

function classifyProcess(comm, exeBase, argsLow) {
    if (argsLow.indexOf("cursor") >= 0 || argsLow.indexOf("/usr/share/cursor") >= 0)
        return "cursor";
    if (argsLow.indexOf("zen-bin") >= 0 || argsLow.indexOf("/zen/") >= 0 || exeBase.indexOf("zen") === 0)
        return "zen";
    if (argsLow.indexOf("discord") >= 0)
        return "discord";
    if (argsLow.indexOf("slack") >= 0)
        return "slack";
    if (argsLow.indexOf("spotify") >= 0)
        return "spotify";
    if (argsLow.indexOf("code") >= 0 && argsLow.indexOf("cursor") < 0)
        return "code";
    if (exeBase === "firefox" || exeBase === "firefox-bin")
        return "firefox";

    var base = exeBase;
    if (base.slice(-4) === "-bin")
        base = base.slice(0, -4);
    if (base && base !== "exe" && base.charAt(0) !== "[")
        return base;

    return ((comm || "").split(/\s+/)[0] || "unknown").toLowerCase();
}

function parsePsProcesses(text) {
    var procs = {};
    var lines = (text || "").split("\n");
    for (var i = 0; i < lines.length; i++) {
        var line = lines[i];
        if (!line || !line.trim())
            continue;
        var match = line.match(/^\s*(\d+)\s+(\d+)\s+(\d+)\s+(.*)$/);
        if (!match)
            continue;
        var pid = parseInt(match[1], 10);
        var ppid = parseInt(match[2], 10);
        var rss = parseInt(match[3], 10);
        var args = match[4] || "";
        if (!pid || !rss || rss <= 0)
            continue;

        var exe = exeFromArgs(args);
        var exeBase = basenamePath(exe) || basenamePath(firstArg(args));
        var comm = exeBase || firstArg(args) || "unknown";
        var argsLow = args.toLowerCase();
        var exeLow = (exe || "").toLowerCase();
        var name = classifyProcess(comm, exeBase, argsLow);
        // helper = sandboxed/child workers. Do not use exe basename here:
        // main Cursor is /usr/lib/electron40/electron + cursor.mjs.
        var helper = argsLow.indexOf("cursor-agent") >= 0
            || argsLow.indexOf("crashpad") >= 0
            || argsLow.indexOf("--type=") >= 0
            || argsLow.indexOf("-contentproc") >= 0
            || exeLow.indexOf("cursor-agent") >= 0
            || exeLow.indexOf("crashpad") >= 0;

        procs[pid] = {
            ppid: ppid,
            rss: rss,
            name: name,
            nameLow: String(name).toLowerCase(),
            generic: isGenericName(name),
            helper: helper,
            exe: exe,
            argsLow: argsLow
        };
    }
    return procs;
}

function resolvedProcessName(pid, procs, memo) {
    if (memo[pid])
        return memo[pid];
    var seen = {};
    var cur = pid;
    var fallback = procs[pid].name;
    while (procs[cur] && !seen[cur]) {
        seen[cur] = true;
        if (memo[cur]) {
            memo[pid] = memo[cur];
            return memo[cur];
        }
        var info = procs[cur];
        if (!info.generic) {
            memo[pid] = info.name;
            return info.name;
        }
        cur = info.ppid;
    }
    memo[pid] = fallback;
    return fallback;
}

function pickHeaviest(pool, procs) {
    var best = pool[0];
    var bestMain = 0;
    var foundMain = false;
    for (var i = 0; i < pool.length; i++) {
        var pid = pool[i];
        var info = procs[pid];
        if (!info.helper) {
            if (!foundMain || info.rss > procs[bestMain].rss) {
                bestMain = pid;
                foundMain = true;
            }
        }
        if (info.rss > procs[best].rss)
            best = pid;
    }
    return foundMain ? bestMain : best;
}

function preferExePool(pool, procs) {
    var withExe = [];
    for (var i = 0; i < pool.length; i++) {
        if (procs[pool[i]].exe)
            withExe.push(pool[i]);
    }
    return withExe.length ? withExe : pool;
}

function groupPrimaryPid(pids, procs, groupNameLow, pidSet) {
    var named = [];
    for (var i = 0; i < pids.length; i++) {
        var pid = pids[i];
        var info = procs[pid];
        if (!info || info.nameLow !== groupNameLow || info.generic)
            continue;
        named.push(pid);
    }

    if (named.length) {
        var namedRoots = [];
        for (var n = 0; n < named.length; n++) {
            if (!pidSet[procs[named[n]].ppid])
                namedRoots.push(named[n]);
        }
        return pickHeaviest(preferExePool(namedRoots.length ? namedRoots : named, procs), procs);
    }

    var roots = [];
    for (var k = 0; k < pids.length; k++) {
        if (!pidSet[procs[pids[k]].ppid])
            roots.push(pids[k]);
    }
    return pickHeaviest(preferExePool(roots.length ? roots : pids, procs), procs);
}

function groupExePath(primary, pids, procs, groupNameLow) {
    if (procs[primary].exe && !procs[primary].helper)
        return procs[primary].exe;

    var bestExe = "";
    var bestRss = -1;
    var fallback = procs[primary].exe || "";
    for (var i = 0; i < pids.length; i++) {
        var pid = pids[i];
        var info = procs[pid];
        if (info.nameLow !== groupNameLow || !info.exe)
            continue;
        if (!info.helper && info.rss > bestRss) {
            bestExe = info.exe;
            bestRss = info.rss;
        } else if (!fallback) {
            fallback = info.exe;
        }
    }
    return bestExe || fallback;
}

function descendantCount(primary, pids, procs, pidSet) {
    var children = {};
    for (var j = 0; j < pids.length; j++) {
        var pid = pids[j];
        var ppid = procs[pid].ppid;
        if (pidSet[ppid] && ppid !== pid) {
            if (!children[ppid])
                children[ppid] = [];
            children[ppid].push(pid);
        }
    }

    var count = 0;
    var seen = {};
    var stack = (children[primary] || []).slice();
    while (stack.length) {
        var cur = stack.pop();
        if (seen[cur])
            continue;
        seen[cur] = true;
        count++;
        var kids = children[cur] || [];
        for (var k = 0; k < kids.length; k++)
            stack.push(kids[k]);
    }
    return count;
}

function parentLabel(ppid, procs, groupPidSet) {
    var cur = ppid;
    var seen = {};
    while (cur > 0 && !seen[cur]) {
        seen[cur] = true;
        if (groupPidSet[cur]) {
            if (!procs[cur])
                return "";
            cur = procs[cur].ppid;
            continue;
        }
        if (!procs[cur])
            return "";
        return procs[cur].name;
    }
    return "";
}

function enrichGroup(group, procs) {
    var pids = group.pids;
    var pidSet = {};
    for (var p = 0; p < pids.length; p++)
        pidSet[pids[p]] = true;

    var groupNameLow = String(group.name).toLowerCase();
    var primary = groupPrimaryPid(pids, procs, groupNameLow, pidSet);
    var children = descendantCount(primary, pids, procs, pidSet);
    var parent = parentLabel(procs[primary].ppid, procs, pidSet);
    var exePath = groupExePath(primary, pids, procs, groupNameLow);

    return {
        label: group.name,
        right: formatKib(group.rss),
        pids: pids,
        tooltip: buildProcessTooltip(exePath, children, parent, pids.length)
    };
}

function buildTopConsumers(psText) {
    var procs = parsePsProcesses(psText);
    var groups = {};
    var memo = {};
    for (var pidKey in procs) {
        if (!procs.hasOwnProperty(pidKey))
            continue;
        var pid = parseInt(pidKey, 10);
        var key = resolvedProcessName(pid, procs, memo);
        if (!groups[key])
            groups[key] = { rss: 0, pids: [] };
        groups[key].rss += procs[pid].rss;
        groups[key].pids.push(pid);
    }

    var ranked = [];
    for (var name in groups) {
        if (!groups.hasOwnProperty(name))
            continue;
        ranked.push({ name: name, rss: groups[name].rss, pids: groups[name].pids });
    }
    ranked.sort(function (a, b) {
        return b.rss - a.rss;
    });
    ranked = ranked.slice(0, topConsumerCount);

    var items = [];
    for (var g = 0; g < ranked.length; g++)
        items.push(enrichGroup(ranked[g], procs));
    return items;
}
