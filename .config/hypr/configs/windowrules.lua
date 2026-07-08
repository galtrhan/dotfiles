hl.window_rule({
    name = "Bluetooth Manager",
    match = { class = "blueman-manager" },
    float = true,
    pin = true,
    center = true,
    size = { 500, 500 },
})

hl.window_rule({
    name = "Network Manager",
    match = { class = "nm-connection-editor" },
    float = true,
    pin = true,
    center = true,
    size = { 500, 500 },
})

hl.window_rule({
    name = "Enpass",
    match = { class = "Enpass" },
    float = true,
    center = true,
    size = { 768, 480 },
})

hl.window_rule({
    name = "Zed",
    match = { class = "dev.zed.Zed" },
    monitor = "1",
})
