local sounds

sounds = {
    load = function()
        sounds["cue-hits-ball"] = love.audio.newSource("resources/cue-hits-ball.wav", "static")
        sounds["white-hit"] = love.audio.newSource("resources/white-hit.wav", "static")
        sounds["ball-hits-ball"] = love.audio.newSource("resources/ball-hits-ball.wav", "static")
        sounds["ball-touches-border"] = love.audio.newSource("resources/ball-touches-border.wav", "static")
        sounds["ball-in-hole"] = love.audio.newSource("resources/ball-in-hole.wav", "static")
    end,

    shot = function()
        sounds["cue-hits-ball"]:play()
    end,

    score = function()
        sounds["ball-in-hole"]:play()
    end,

    collision = function(coltype)
        local sound = sounds[coltype] or sounds["ball-hits-ball"]
        sound:play()
    end,
}


------------------------------------------------------------------------
return sounds
