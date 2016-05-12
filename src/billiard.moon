signals = assert require "hump.signal"
vector = assert require "hump.vector-light"

import ceil, max, min, cos, sin, rad, pi from math
import maxn from table

local Billiard, internals


--------------------------------------------------------------------------------
internals =
    borders: {}
    startpos: {x: 622, y: 211}
    max_force: 120
    friction: 200
    minvelocity: 600
    deltaforce: 50

    ishole: (x, y) ->
        if (x <= 22 or x >= 778) and (y <= 22 or y >= 398)
            true
        elseif (x >= 392 and x <= 406) and (y <= 22 or y >= 398)
            true
        else
            false

    getfriction: (x, y, f) ->
        x, y = (internals.nantozero x), (internals.nantozero y)
        force = vector.len x, y
        angle = pi + vector.angleTo x, y
        f = min f, force
        f * (cos angle), f * (sin angle)

    nantozero: (value) ->
        if value == value then value else 0

    calculaterotation: ->
        mx, my = love.mouse.getPosition!
        bx, by = Billiard.instance.balls.white.body\getPosition!
        angle = vector.angleTo bx - mx, by - my
        angle * 180 / pi


--------------------------------------------------------------------------------
class Billiard
    @_VERSION: "1.0"
    @_DESCRIPTION: "Billiard"
    @_AUTHOR: "ℜodrigo ℭacilhας <batalema@cacilhas.info>"
    @_URL: "https://bitbucket.org/cacilhas/billiard/"
    @_LICENSE: "BSD-3 Clausule"

    balls: {}
    score: 0
    rotation: 0
    rolling: false
    firsthit: false
    force: 100

    new: =>
        @@instance = @
        @world = love.physics.newWorld 0, 0
        @world\setCallbacks (...) -> @\collision ...
        @handlers =
            shot: signals.register "shoot", (...) -> @\shot ...
            increase_force: signals.register "increase-force", (...) -> @\increaseforce ...
            decrease_force: signals.register "decrease-force", (...) -> @\decreaseforce ...
            ball_in_hole: signals.register "ball-in-hole", (...) -> @\doscore ...
        @\loadborders!
        @\loadballs!

    disconnecthandlers: =>
        -- TODO: why is this failing?
        pcall signals.remove, (name\gsub "_", "-"), handlers for name, handler in pairs @handlers

    update: (dt) =>
        @world\update dt
        @rotation = internals.calculaterotation!
        @rolling = false
        survivors = {}

        for name, ball in pairs @balls
            @\applyfriction ball, dt if ball.body\isAwake!
            x, y = ball.body\getPosition!
            signals.emit "ball-in-hole", ball if internals.ishole x, y
            survivors[name] = ball if ball.fixture
        @balls = survivors
        
        signals.emit "game-over" if (maxn survivors) == 0
        if @firsthit and not @rolling
            @score = max 0, @score - 1
            firsthit = false

    draw: =>
        for _, ball in pairs @balls
            x, y = ball.body\getPosition!
            love.graphics.setColor ball.color
            love.graphics.circle "fill", x, y, ball.shape\getRadius!

    doscore: (ball) =>
        if ball == @balls.white
            @score = 0
            ball.body\setAwake false
            with internals.startpos
                ball.body\setPosition .x, .y
        else
            @score += 1
            ball.fixture\destroy!
            ball.body\destroy!
            ball.fixture = nil

    increaseforce: (dt) =>
        @force += internals.deltaforce * dt
        @force = min @force, 100

    decreaseforce: (dt) =>
        @force -= internals.deltaforce * dt
        @force = max @force, 0

    scaleforce: (f) =>
        for x = 0, ceil @force
            b = 255 * (100 - x) / 100
            r = 255 * x / 100
            f x, r, 0, b

    shot: =>
        unless @rolling
            force = @force * internals.max_force
            angle = rad (180 + @rotation) % 360
            @firsthit = true
            @balls.white.body\applyForce (cos angle) * force,
                                         (sin angle) * force

    collision: (a, b, coll) =>
        colsig = "ball-touches-border"
        if a\getUserData! == "ball" and b\getUserData! == "ball"
            colsig = nil
            if @firsthit and ((a == @balls.white.fixture) or (b == @balls.white.fixture))
                @firsthit = false
                colsig = "white-hit"
        signals.emit "collision", colsig

    applyfriction: (ball, dt) =>
        x, y = ball.body\getLinearVelocity!
        x, y = internals.getfriction x, y, internals.friction * dt
        ball.body\applyForce x, y

        x, y = ball.body\getLinearVelocity!
        x, y = (internals.nantozero x), (internals.nantozero y)
        if (x * x) + (y * y) < internals.minvelocity
            ball.body\setAwake false
        else
            @rolling = true

    loadborders: =>
        with {bs: internals.borders, ph: love.physics}
            .bs.upleft =
                body: .ph.newBody @world, 200, 6, "static"
                shape: .ph.newRectangleShape 378, 12
            .bs.upright =
                body: .ph.newBody @world, 600, 6, "static"
                shape: .ph.newRectangleShape 378, 12
            .bs.downleft =
                body: .ph.newBody @world, 200, 416, "static"
                shape: .ph.newRectangleShape 378, 12
            .bs.downright =
                body: .ph.newBody @world, 600, 416, "static"
                shape: .ph.newRectangleShape 378, 12
            .bs.left =
                body: .ph.newBody @world, 6 ,211, "static"
                shape: .ph.newRectangleShape 12, 378
            .bs.right =
                body: .ph.newBody @world, 794 ,211, "static"
                shape: .ph.newRectangleShape 12, 378

            for _, border in pairs .bs
                border.fixture = .ph.newFixture border.body, border.shape

        love.graphics.setBackgroundColor 0, 0, 0

    loadballs: =>
        size = 8
        bounce = .9
        mass = .4
        density = 2

        with love.physics
            @balls.white =
                body: .newBody @world, internals.startpos.x, internals.startpos.y, "dynamic"
                shape: .newCircleShape size
                color: {0xff, 0xff, 0xff}
            @balls.white.fixture = .newFixture @balls.white.body,
                                               @balls.white.shape,
                                               density
            with @balls.white
                .body\setMass mass
                .fixture\setUserData "ball"
                .fixture\setRestitution bounce

            positions = {
                {x: 199, y: 211}
                {x: 186, y: 205}
                {x: 183, y: 217}
                {x: 173, y: 199}
                {x: 173, y: 211}
                {x: 173, y: 222}
                {x: 160, y: 193}
                {x: 160, y: 205}
                {x: 160, y: 217}
                {x: 160, y: 229}
            }

            for i, pos in ipairs positions
                @balls[i] =
                    body: .newBody @world, pos.x, pos.y, "dynamic"
                    shape: .newCircleShape size
                    color: {0xff, 0x20, 0x20}
                @balls[i].fixture = .newFixture @balls[i].body,
                                                @balls[i].shape,
                                                density
                with @balls[i]
                    .body\setMass mass
                    .fixture\setUserData "ball"
                    .fixture\setRestitution bounce


--------------------------------------------------------------------------------
Billiard
