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
    name = "Sudo Askpass",
    match = { class = "rofi", workspace = "special:sudo" },
    float = true,
    center = true,
    pin = true,
    size = { 420, 60 },
})
