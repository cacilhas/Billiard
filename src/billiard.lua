local app = {
    _VERSION = "1.0",
    _DESCRIPTION = "Billiard",
    _AUTHOR = "ℜodrigo ℭacilhας <batalema@cacilhas.info>",
    _URL = "",
    _LICENSE = "BSD-3 Clausule",

    borders = {},
    balls = {},
    startpos = {x=622, y=211},
    sounds = {},
    score = 0,
    max_force = 120,
    friction = 180,
    force = 100,
    rotation = 0,
    rolling = false,
    firsthit = true,
    score = 0,
    cuedist = {
        dist = 0,
        dir = 6,
    },
}

local calculaterotation, loadborders, loadballs, ishole, getfriction, nantozero, collision


------------------------------------------------------------------------
function app.load()
    app.world = love.physics.newWorld(0, 0)
    app.world:setCallbacks(collision)
    loadborders()
    loadballs()
end


------------------------------------------------------------------------
function app.update(dt)
    app.world:update(dt)
    app.rotation = calculaterotation()

    local aux = {}
    app.rolling = false
    table.foreach(app.balls, function(name, ball)
        local x, y

        if ball.body:isAwake() then
            -- Friction
            x, y = ball.body:getLinearVelocity()
            x, y = getfriction(x, y, app.friction * dt)
            ball.body:applyForce(x, y)

            x, y = ball.body:getLinearVelocity()
            x, y = nantozero(x), nantozero(y)
            if (x * x) + (y * y) < 600 then
                ball.body:setAwake(false)
            else
                app.rolling = true
            end
        end

        x, y = ball.body:getPosition()
        if name == "white" then
            aux.white = ball
            if ishole(x, y) then
                app.sounds.ball_in_hole:play()
                app.score = 0
                ball.body:setAwake(false)
                ball.body:setPosition(app.startpos.x, app.startpos.y)
            end

        else
            if ishole(x, y) then
                app.score = app.score + 1
                ball.fixture:destroy()
                ball.body:destroy()
                app.sounds.ball_in_hole:play()
            else
                table.insert(aux, ball)
            end
        end
    end)
    app.balls = aux
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
function loadborders()
    app.borders.upleft = {
        body = love.physics.newBody(app.world, 200, 6, "static"),
        shape = love.physics.newRectangleShape(378, 12),
    }
    app.borders.upleft.fixture = love.physics.newFixture(
        app.borders.upleft.body, app.borders.upleft.shape
    )
    app.borders.upright = {
        body = love.physics.newBody(app.world, 600, 6, "static"),
        shape = love.physics.newRectangleShape(378, 12),
    }
    app.borders.upright.fixture = love.physics.newFixture(
        app.borders.upright.body, app.borders.upright.shape
    )

    app.borders.downleft = {
        body = love.physics.newBody(app.world, 200, 416, "static"),
        shape = love.physics.newRectangleShape(378, 12),
    }
    app.borders.downleft.fixture = love.physics.newFixture(
        app.borders.downleft.body, app.borders.downleft.shape
    )
    app.borders.downright = {
        body = love.physics.newBody(app.world, 600, 416, "static"),
        shape = love.physics.newRectangleShape(378, 12),
    }
    app.borders.downright.fixture = love.physics.newFixture(
        app.borders.downright.body, app.borders.downright.shape
    )

    app.borders.left = {
        body = love.physics.newBody(app.world, 6, 211, "static"),
        shape = love.physics.newRectangleShape(12, 378),
    }
    app.borders.left.fixture = love.physics.newFixture(
        app.borders.left.body, app.borders.left.shape
    )

    app.borders.right = {
        body = love.physics.newBody(app.world, 794, 211, "static"),
        shape = love.physics.newRectangleShape(12, 378),
    }
    app.borders.right.fixture = love.physics.newFixture(
        app.borders.right.body, app.borders.right.shape
    )

    love.graphics.setBackgroundColor(0, 0, 0)
end


------------------------------------------------------------------------
function loadballs()
    local size = 8
    local bounce = .9
    local mass = .4
    local density = 2
    local massdata

    app.balls.white = {
        body = love.physics.newBody(app.world, app.startpos.x, app.startpos.y, "dynamic"),
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
        app.sounds.cue_hits_ball:play()
        local force = app.force * app.max_force
        local angle = math.rad((180 + app.rotation) % 360)

        app.balls.white.body:applyForce(
            math.cos(angle) * force,
            math.sin(angle) * force
        )
    end
end


------------------------------------------------------------------------
function ishole(x, y)
    if (x <= 22 or x >= 778) and (y <= 22 or y >= 398) then return true end
    if (x >= 392 and x <= 406) and (y <= 22 or y >= 398) then return true end
    return false
end


------------------------------------------------------------------------
function getfriction(x, y, f)
    x, y = nantozero(x), nantozero(y)
    local ax = math.abs(x)
    local ay = math.abs(y)
    local fx = math.min(ax, f)
    local fy = math.min(ay, f)

    if ax == 0 then ax = 1 end
    if ay == 0 then ay = 1 end

    return -fx * x / ax, -fy * y / ay
end


function nantozero(v)
    if v == v then return v else return 0 end
end


------------------------------------------------------------------------
function calculaterotation()
    local x, y, mx, my, bx, by, c, angle
    mx, my = love.mouse.getPosition()
    bx, by = app.balls.white.body:getPosition()
    x, y = bx - mx, my - by
    c = math.sqrt((x * x) + (y * y))
    angle = math.asin(y / c)

    return angle * 90 * math.pi
end


------------------------------------------------------------------------
function collision(a, b, coll)
    if a:getUserData() == "ball" and b:getUserData() == "ball" then
        if app.firsthit and (a == app.balls.white.fixtures or b == app.balls.white.fixtures) then
            app.firsthit = false
            app.sounds.white_hit:play()
        else
            app.sounds.ball_hits_ball:play()
        end
    else
        app.sounds.ball_touches_border:play()
    end
end


------------------------------------------------------------------------
return app
