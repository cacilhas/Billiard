local signals = assert(require "hump.signal")
local sounds

sounds = {
    load = function()
        sounds["cue-hits-ball"] = love.audio.newSource("resources/cue-hits-ball.wav", "static")
        sounds["white-hit"] = love.audio.newSource("resources/white-hit.wav", "static")
        sounds["ball-hits-ball"] = love.audio.newSource("resources/ball-hits-ball.wav", "static")
        sounds["ball-touches-border"] = love.audio.newSource("resources/ball-touches-border.wav", "static")
        sounds["ball-in-hole"] = love.audio.newSource("resources/ball-in-hole.wav", "static")

        signals.register("shoot", sounds.shot)
        signals.register("ball-in-hole", sounds.score)
        signals.register("collision", sounds.collision)
    end,

    shot = function()
        return sounds["cue-hits-ball"]:play()
    end,

    score = function()
        return sounds["ball-in-hole"]:play()
    end,

    collision = function(coltype)
        local sound = sounds[coltype] or sounds["ball-hits-ball"]
        return sound:play()
    end,
}


------------------------------------------------------------------------
return sounds
