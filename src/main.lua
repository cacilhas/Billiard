local signals = assert(require "hump.signal")
local sounds = assert(require "sounds")
local app = assert(require "billiard")
local cue = {dist = 0, dir = 6}
local board, pointer


------------------------------------------------------------------------
function love.load()
    love.mouse.setVisible(false)
    board = love.graphics.newImage("images/board.jpg")
    cue.img = love.graphics.newImage("images/cue.png")
    pointer = love.graphics.newImage("images/pointer.png")
    sounds.load()
    app.load()

    signals.register("shoot", sounds.shot)
    signals.register("shoot", app.shot)
    signals.register("increase-force", app.increaseforce)
    signals.register("decrease-force", app.decreaseforce)
    signals.register("ball-in-hole", sounds.score)
    signals.register("ball-in-hole", app.doscore)
    signals.register("collision", sounds.collision)
end


------------------------------------------------------------------------
function love.update(dt)
    app.update(dt)

    if love.keyboard.isDown("up") or love.keyboard.isDown("right") then
        signals.emit("increase-force", dt)

    elseif love.keyboard.isDown("down") or love.keyboard.isDown("left") then
        signals.emit("decrease-force", dt)
    end

    cue.dist = cue.dist + (cue.dir * dt)
    if cue.dist > 16 then
        cue.dist = 16
        cue.dir = -math.abs(cue.dist)
    elseif cue.dist < 0 then
        cue.dist = 0
        cue.dir = math.abs(cue.dir)
    end
end


------------------------------------------------------------------------
function love.keypressed(key, isrepeat)
    if key == " " and not app.rolling then signals.emit("shoot") end
end


------------------------------------------------------------------------
function love.mousepressed(x, y, button)
    if button == "l" and not app.rolling then
        signals.emit("shoot")

    elseif button == "wu" then
        signals.emit("increase-force", .0625)

    elseif button == "wd" then
        signals.emit("decrease-force", .0625)
    end
end


------------------------------------------------------------------------
function love.draw()
    local x, y

    -- Draw board
    love.graphics.draw(board, 0, 0)

    -- Draw balls
    app.draw()

    -- Draw cue
    if not app.rolling then
        love.graphics.setColor(0xff, 0xff, 0xff)
        x, y = app.balls.white.body:getPosition()
        love.graphics.draw(
            cue.img, x, y,
            math.rad(app.rotation),
            1, 1,
            cue.dist, cue.img:getHeight() / 2
        )
    end

    -- Draw force bar
    love.graphics.setColor(0xff, 0xff, 0xff)
    love.graphics.rectangle("line", 10, 432, 204, 100)
    app.scaleforce(function(x, r, g, b)
        love.graphics.setColor(r, g, b)
        love.graphics.rectangle("fill", x * 2 + 11, 433, 2, 98)
    end)

    -- Draw score
    love.graphics.setColor(0xff, 0xff, 0xff)
    love.graphics.print("Score: " .. app.score, 300, 432)

    -- Draw pointer
    if not app.rolling then
        x, y = love.mouse.getPosition()
        love.graphics.draw(pointer, x - 13, y - 13)
    end
end
