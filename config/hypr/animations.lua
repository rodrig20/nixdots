-- Animation Switch
hl.config({
    animations = {
        enabled = true,
    }
})

-- Animation Curves (Bezier)
hl.curve("overshot", { type = "bezier", points = { {0.05, 0.9}, {0.1, 1.05} } })
hl.curve("easeOutExpo", { type = "bezier", points = { {0.16, 1}, {0.3, 1} } })
hl.curve("easeOutBack", { type = "bezier", points = { {0.34, 1.2}, {0.64, 1} } })

-- Animation Rules
hl.animation({ leaf = "windows", enabled = true, speed = 3, bezier = "easeOutBack", style = "slide" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 2, bezier = "easeOutBack" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 5, bezier = "easeOutBack" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 6, bezier = "overshot", style = "slide" })

hl.animation({ leaf = "border", enabled = true, speed = 5, bezier = "easeOutBack" })
hl.animation({ leaf = "fade", enabled = true, speed = 5, bezier = "easeOutBack" })
hl.animation({ leaf = "fadeDim", enabled = true, speed = 5, bezier = "easeOutBack" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 5, bezier = "easeOutExpo" })

