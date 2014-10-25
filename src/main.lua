local signals = assert(require "hump.signal")
local sounds = assert(require "sounds")
local app = assert(require "billiard")


------------------------------------------------------------------------
function love.load()
    love.mouse.setVisible(false)
    app.board = love.graphics.newImage("images/board.jpg")
    app.cue = love.graphics.newImage("images/cue.png")
    app.signals = signals
    sounds.load()
    app.load()

    signals.register("shoot", sounds.shot)
    signals.register("shoot", app.shot)
    signals.register("ball-in-hole", sounds.score)
    signals.register("ball-in-hole", app.doscore)
    signals.register("collision", sounds.collision)
end


------------------------------------------------------------------------
function love.update(dt)
    app.update(dt)

    if love.keyboard.isDown("up") or love.keyboard.isDown("right") then
        app.force = app.force + (50 * dt)

    elseif love.keyboard.isDown("down") or love.keyboard.isDown("left") then
        app.force = app.force - (50 * dt)
    end

    if app.force < 0 then app.force = 0 end
    if app.force > 100 then app.force = 100 end

    app.cuedist.dist = app.cuedist.dist + (app.cuedist.dir * dt)
    if app.cuedist.dist > 16 then
        app.cuedist.dist = 16
        app.cuedist.dir = -math.abs(app.cuedist.dist)
    elseif app.cuedist.dist < 0 then
        app.cuedist.dist = 0
        app.cuedist.dir = math.abs(app.cuedist.dir)
    end
end


------------------------------------------------------------------------
function love.keypressed(key, isrepeat)
    if key == " " and not app.rolling then signals.emit("shoot") end
end


------------------------------------------------------------------------
function love.mousepressed(x, y, button)
    if button == "l" and not app.rolling then signals.emit("shoot") end
end


------------------------------------------------------------------------
function love.draw()
    local x, y, r, b, cue

    -- Draw board
    love.graphics.draw(app.board, 0, 0)

    -- Draw balls
    app.draw()

    -- Draw cue
    if not app.rolling then
        love.graphics.setColor(0xff, 0xff, 0xff)
        x, y = app.balls.white.body:getPosition()
        love.graphics.draw(
            app.cue, x, y,
            math.rad(app.rotation),
            1, 1,
            app.cuedist.dist, app.cue:getHeight() / 2
        )
    end

    -- Draw force bar
    love.graphics.setColor(0xff, 0xff, 0xff)
    love.graphics.rectangle("line", 10, 432, 204, 100)
    for x = 0, math.ceil(app.force) do
        b = 255 * (100 - x) / 100
        r = 255 * x / 100
        love.graphics.setColor(r, 0, b)
        love.graphics.rectangle("fill", x * 2 + 11, 433, 2, 98)
    end

    -- Draw score
    love.graphics.setColor(0xff, 0xff, 0xff)
    love.graphics.print("Score: " .. app.score, 300, 432)
end
