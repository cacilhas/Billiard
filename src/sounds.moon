signals = assert require "hump.signal"
import bind_methods from assert require "moon"


--------------------------------------------------------------------------------
class Sounds

    load: =>
        with love.audio
            @["cue-hits-ball"] = .newSource "resources/cue-hits-ball.wav", "static"
            @["white-hit"] = .newSource "resources/white-hit.wav", "static"
            @["ball-hits-ball"] = .newSource "resources/ball-hits-ball.wav", "static"
            @["ball-touches-border"] = .newSource "resources/ball-touches-border.wav", "static"
            @["ball-in-hole"] = .newSource "resources/ball-in-hole.wav", "static"

        signals.register "shoot", -> @\shot!
        signals.register "ball-in-hole", -> @\score!
        signals.register "collision", (...) -> @\collision ...

    shot: => @["cue-hits-ball"]\play!
    score: => @["ball-in-hole"]\play!
    collision: (coltype) =>
        sound = @[coltype] or @["ball-hits-ball"]
        sound\play!


--------------------------------------------------------------------------------
bind_methods Sounds!
