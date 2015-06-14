love.conf= (t) ->
    t.version = "0.9.1"
    t.identity = "billiard"
    with t.window
        .title = "Billiard"
        .icon = "images/billiard.png"
        .width = 800
        .height = 542
        .fullscreen = false
