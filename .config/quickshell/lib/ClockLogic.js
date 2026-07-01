.pragma library

function daySuffix(day) {
    if (day >= 11 && day <= 13)
        return "th";
    switch (day % 10) {
    case 1:
        return "st";
    case 2:
        return "nd";
    case 3:
        return "rd";
    default:
        return "th";
    }
}

function formatDateTime(date, verbose) {
    if (!verbose)
        return Qt.formatDateTime(date, "HH:mm  yyyy.MM.dd");
    var day = date.getDate();
    return Qt.formatDateTime(date, "HH:mm  dddd MMMM ") + day + daySuffix(day) + Qt.formatDateTime(date, " yyyy");
}
