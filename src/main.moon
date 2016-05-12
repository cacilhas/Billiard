local *

gamestate = assert require "hump.gamestate"
signals = assert require "hump.signal"
timer = assert require "hump.timer"
sounds = assert require "sounds"
Billiard = assert require "billiard"

import abs, floor, rad from math

cue =
    dist: 0
    dir: 6

shotcount = 0
app = nil
board = nil
splash = nil
font = nil
pointer = nil
gameoverfont = nil


--------------------------------------------------------------------------------
love.load = ->
    love.mouse.setVisible false
    with love.graphics
        splash = .newImage "images/splash.jpg"
        board = .newImage "images/board.jpg"
        cue.img = .newImage "images/cue.png"
        pointer = .newImage "images/pointer.png"
        font = .newFont "resources/PlantagenetCherokee.ttf", 24
        gameoverfont = .newFont "resources/brasil-new.ttf", 64
    signals.register "shoot", -> shotcount += 1
    signals.register "game-over", -> gamestate.switch gameoverstate
    sounds.load!

    gamestate.registerEvents!
    gamestate.switch menustate


--------------------------------------------------------------------------------
mainstate =
    enter: =>
        app = Billiard!
        shotcount = 0

    update: (dt) =>
        app\update dt
        with love.keyboard
            if .isDown"up" or .isDown"right"
                signals.emit "increase-force", dt
            elseif .isDown"down" or .isDown"left"
                signals.emit "decrease-force", dt

        cue.dist += cue.dir * dt
        if cue.dist > 16
            cue.dist = 16
            cue.dir = -abs cue.dir
        elseif cue.dist < 0
            cue.dist = 0
            cue.dir = abs cue.dir

    keypressed: (key, isrepeat) =>
        signals.emit "shoot" if key == " " and not app.rolling

    keyreleased: (key) =>
        switch key
            when "p"
                gamestate.push pausestate
            when "escape"
                gamestate.switch menustate

    mousepressed: (x, y, button) =>
        if button == 1
                signals.emit "shoot" unless app.rolling

    wheelmoved: (x, y) =>
        if y < 0
            signals.emit "increase-force", -.1 * y
        elseif y > 0
            signals.emit "decrease-force", .1 * y

    draw: =>
        with love.graphics
            -- Draw board
            .draw board, 0, 0

            -- Draw balls
            app\draw!

            -- Draw cue
            unless app.rolling
                .setColor 0xff, 0xff, 0xff
                x, y = app.balls.white.body\getPosition!
                .draw cue.img, x, y, rad app.rotation,
                      1, 1, cue.dist, cue.img\getHeight! / 2

            --Draw force bar
            .setColor 0xff, 0xff, 0xff
            .rectangle "line", 10, 432, 204, 100
            app\scaleforce (x, r, g, b) ->
                .setColor r, g, b
                .rectangle "fill", x * 2 + 11, 433, 2, 98

            -- Draw score
            .setColor 0xff, 0xff, 0xff
            .setFont font
            .print "Score: #{app.score}", 300, 432
            .print "Shots: #{shotcount}", 300, 464

            -- Draw pointer
            unless app.rolling
                x, y = love.mouse.getPosition!
                .draw pointer, x - 13, y - 13


--------------------------------------------------------------------------------
menustate =
    enter: =>
        app\disconnecthandlers! if app

    keyreleased: (key) =>
        switch key
            when "return"
                gamestate.switch mainstate
            when "escape"
                love.event.quit!

    draw: =>
        love.graphics.setColor 0xff, 0xff, 0xff
        love.graphics.draw splash, 0, 0


--------------------------------------------------------------------------------
pausestate =
    enter: (previous) =>
        @timer = timer.new!
        @alpha = 0
        @previous = previous
        @timer\tween .5, @, {alpha: 1}, "linear"

    leave: =>
        @previous = nil
        @timer\clear!

    keyreleased: (key) =>
        gamestate.pop! if key == "p" or key == "escape"

    update: (dt) =>
        @timer\update dt

    draw: =>
        @previous\draw! if @previous
        with love.graphics
            .setColor 0x00, 0x00, 0x60, floor 0xa0 * @alpha
            width, height = .getDimensions!
            .rectangle "fill", 0, 0, width, height

            .setColor 0xff, 0xff, 0xff, floor 0xa0 * @alpha
            .setFont gameoverfont
            .print "Paused", 312, 166


--------------------------------------------------------------------------------
gameoverstate =
    enter: (previous) =>
        @previous = previous
        @timer = timer.new!
        @tx_game_x = -100
        @tx_over_x = love.window.getWidth!
        @timer\tween 2, @, {tx_game_x: 272, tx_over_x: 416}, "out-expo"

    leave: =>
        @previous = nil
        @timer\clear!

    keyreleased: (key) =>
        gamestate.switch menustate if key == "escape"

    update: (dt) =>
        @timer\update dt

    draw: =>
        @previous\draw! if @previous
        with love.graphics
            .setColor 0xff, 0x00, 0x00
            .setFont gameoverfont
            .print "Game", @tx_game_x, 166
            .print "Over", @tx_over_x, 166
            .setColor 0xff, 0xff, 0xff
            .draw cur.img, 390, 432
