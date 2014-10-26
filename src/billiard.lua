local signals = assert(require "hump.signal")
local vector = assert(require "hump.vector-light")

local app = {
    _VERSION = "1.0",
    _DESCRIPTION = "Billiard",
    _AUTHOR = "ℜodrigo ℭacilhας <batalema@cacilhas.info>",
    _URL = "https://bitbucket.org/cacilhas/billiard/",
    _LICENSE = "BSD-3 Clausule",

    balls = {},
    score = 0,
    rotation = 0,
    rolling = false,
}


local internals = {
    borders = {},
    startpos = {x=622, y=211},
    max_force = 120,
    friction = 200,
    minvelocity = 600,
    force = 100,
    deltaforce = 50, -- percentual per second
    firsthit = false,
}


------------------------------------------------------------------------
function app.load()
    app.world = love.physics.newWorld(0, 0)
    app.world:setCallbacks(internals.collision)
    internals.loadborders()
    internals.loadballs()
end


------------------------------------------------------------------------
function app.update(dt)
    app.world:update(dt)
    app.rotation = internals.calculaterotation()

    app.rolling = false
    local survivors = {}
    table.foreach(app.balls, function(name, ball)
        if ball.body:isAwake() then internals.applyfriction(ball, dt) end
        local x, y = ball.body:getPosition()
        if internals.ishole(x, y) then signals.emit("ball-in-hole", ball) end
        if ball.fixture then survivors[name] = ball end
    end)
    app.balls = survivors
    if table.maxn(survivors) == 0 then signals.emit("game-over") end
    if internals.firsthit and not app.rolling then
        app.score = math.max(0, app.score - 1)
        internals.firsthit = false
    end
end


------------------------------------------------------------------------
function app.draw()
    table.foreach(app.balls, function(_, ball)
        local x, y = ball.body:getPosition()
        love.graphics.setColor(ball.color)
        love.graphics.circle("fill", x, y, ball.shape:getRadius())
    end)
end


------------------------------------------------------------------------
function app.doscore(ball)
    if ball == app.balls.white then
        app.score = 0
        ball.body:setAwake(false)
        ball.body:setPosition(internals.startpos.x, internals.startpos.y)
    else
        app.score = app.score + 1
        ball.fixture:destroy()
        ball.body:destroy()
        ball.fixture = nil
    end
end


------------------------------------------------------------------------
function app.increaseforce(dt)
    internals.force = internals.force + (internals.deltaforce * dt)
    if internals.force > 100 then internals.force = 100 end
end


function app.decreaseforce(dt)
    internals.force = internals.force - (internals.deltaforce * dt)
    if internals.force < 0 then internals.force = 0 end
end


function app.scaleforce(f)
    local x, b, r
    for x = 0, math.ceil(internals.force) do
        b = 255 * (100 - x) / 100
        r = 255 * x / 100
        f(x, r, 0, b)
    end
end


------------------------------------------------------------------------
function internals.applyfriction(ball, dt)
    -- Friction
    local x, y = ball.body:getLinearVelocity()
    x, y = internals.getfriction(x, y, internals.friction * dt)
    ball.body:applyForce(x, y)

    x, y = ball.body:getLinearVelocity()
    x, y = internals.nantozero(x), internals.nantozero(y)
    if (x * x) + (y * y) < internals.minvelocity then
        ball.body:setAwake(false)
    else
        app.rolling = true
    end
end


------------------------------------------------------------------------
function internals.loadborders()
    internals.borders.upleft = {
        body = love.physics.newBody(app.world, 200, 6, "static"),
        shape = love.physics.newRectangleShape(378, 12),
    }
    internals.borders.upleft.fixture = love.physics.newFixture(
        internals.borders.upleft.body, internals.borders.upleft.shape
    )
    internals.borders.upright = {
        body = love.physics.newBody(app.world, 600, 6, "static"),
        shape = love.physics.newRectangleShape(378, 12),
    }
    internals.borders.upright.fixture = love.physics.newFixture(
        internals.borders.upright.body, internals.borders.upright.shape
    )

    internals.borders.downleft = {
        body = love.physics.newBody(app.world, 200, 416, "static"),
        shape = love.physics.newRectangleShape(378, 12),
    }
    internals.borders.downleft.fixture = love.physics.newFixture(
        internals.borders.downleft.body, internals.borders.downleft.shape
    )
    internals.borders.downright = {
        body = love.physics.newBody(app.world, 600, 416, "static"),
        shape = love.physics.newRectangleShape(378, 12),
    }
    internals.borders.downright.fixture = love.physics.newFixture(
        internals.borders.downright.body, internals.borders.downright.shape
    )

    internals.borders.left = {
        body = love.physics.newBody(app.world, 6, 211, "static"),
        shape = love.physics.newRectangleShape(12, 378),
    }
    internals.borders.left.fixture = love.physics.newFixture(
        internals.borders.left.body, internals.borders.left.shape
    )

    internals.borders.right = {
        body = love.physics.newBody(app.world, 794, 211, "static"),
        shape = love.physics.newRectangleShape(12, 378),
    }
    internals.borders.right.fixture = love.physics.newFixture(
        internals.borders.right.body, internals.borders.right.shape
    )

    love.graphics.setBackgroundColor(0, 0, 0)
end


------------------------------------------------------------------------
function internals.loadballs()
    local size = 8
    local bounce = .9
    local mass = .4
    local density = 2
    local massdata

    app.balls.white = {
        body = love.physics.newBody(app.world, internals.startpos.x, internals.startpos.y, "dynamic"),
        shape = love.physics.newCircleShape(size),
        color = {0xff, 0xff, 0xff},
    }
    app.balls.white.fixture = love.physics.newFixture(
        app.balls.white.body, app.balls.white.shape, density
    )
    app.balls.white.body:setMass(mass)
    app.balls.white.fixture:setUserData "ball"
    app.balls.white.fixture:setRestitution(bounce)

    local positions = {
        {x=199, y=211},
        {x=186, y=205},
        {x=183, y=217},
        {x=173, y=199},
        {x=173, y=211},
        {x=173, y=222},
        {x=160, y=193},
        {x=160, y=205},
        {x=160, y=217},
        {x=160, y=229},
    }

    table.foreachi(positions, function(i, pos)
        app.balls[i] = {
            body = love.physics.newBody(app.world, pos.x, pos.y, "dynamic"),
            shape = love.physics.newCircleShape(size),
            color = {0xff, 0x20, 0x20},
        }
        app.balls[i].fixture = love.physics.newFixture(
            app.balls[i].body, app.balls[i].shape, density
        )
        app.balls.white.body:setMass(mass)
        app.balls[i].fixture:setUserData "ball"
        app.balls[i].fixture:setRestitution(bounce)
    end)
end


------------------------------------------------------------------------
function app.shot()
    if not app.rolling then
        local force = internals.force * internals.max_force
        local angle = math.rad((180 + app.rotation) % 360)
        internals.firsthit = true

        app.balls.white.body:applyForce(
            math.cos(angle) * force,
            math.sin(angle) * force
        )
    end
end


------------------------------------------------------------------------
function internals.ishole(x, y)
    if (x <= 22 or x >= 778) and (y <= 22 or y >= 398) then return true end
    if (x >= 392 and x <= 406) and (y <= 22 or y >= 398) then return true end
    return false
end


------------------------------------------------------------------------
function internals.getfriction(x, y, f)
    x, y = internals.nantozero(x), internals.nantozero(y)
    local force = vector.len(x, y)
    local angle = vector.angleTo(x, y) + math.pi
    f = math.min(f, force)
    return f * math.cos(angle), f * math.sin(angle)
end


function internals.nantozero(v)
    if v == v then return v else return 0 end
end


------------------------------------------------------------------------
function internals.calculaterotation()
    local mx, my, bx, by, angle
    mx, my = love.mouse.getPosition()
    bx, by = app.balls.white.body:getPosition()
    angle = vector.angleTo(bx - mx, by - my)
    return angle * 180 / math.pi
end


------------------------------------------------------------------------
function internals.collision(a, b, coll)
    local colsig = "ball-touches-border"
    if a:getUserData() == "ball" and b:getUserData() == "ball" then
        colsig = nil
        if internals.firsthit and ((a == app.balls.white.fixture) or (b == app.balls.white.fixture)) then
            internals.firsthit = false
            colsig = "white-hit"
        end
    end
    signals.emit("collision", colsig)
end


------------------------------------------------------------------------
return app
