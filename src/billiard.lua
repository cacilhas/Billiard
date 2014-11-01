local signals = assert(require "hump.signal")
local vector = assert(require "hump.vector-light")
local class = assert(require "hump.class")

local Billiard = class {
    _VERSION = "1.0",
    _DESCRIPTION = "Billiard",
    _AUTHOR = "ℜodrigo ℭacilhας <batalema@cacilhas.info>",
    _URL = "https://bitbucket.org/cacilhas/billiard/",
    _LICENSE = "BSD-3 Clausule",

    balls = {},
    score = 0,
    rotation = 0,
    rolling = false,
    firsthit = false,
    force = 100,
}


local internals = {
    borders = {},
    startpos = {x=622, y=211},
    max_force = 120,
    friction = 200,
    minvelocity = 600,
    deltaforce = 50, -- percentual per second
}


------------------------------------------------------------------------
function Billiard:init()
    self.world = love.physics.newWorld(0, 0)
    self.world:setCallbacks(function(...) self:collision(...) end)

    self.handlers = {
        shot = signals.register("shoot", function(...) self:shot(...) end),
        increase_force = signals.register("increase-force", function(...) self:increaseforce(...) end),
        decrease_force = signals.register("decrease-force", function(...) self:decreaseforce(...) end),
        ball_in_hole = signals.register("ball-in-hole", function(...) self:doscore(...) end),
    }

    self:loadborders()
    self:loadballs()
end


------------------------------------------------------------------------
function Billiard:disconnecthandlers()
    signals.remove("shoot", self.handlers.shot)
    signals.remove("increase-force", self.handlers.increase_force)
    signals.remove("decrease-force", self.handlers.decrease_force)
    signals.remove("ball-in-hole", self.handlers.ball_in_hole)
end


------------------------------------------------------------------------
function Billiard:update(dt)
    self.world:update(dt)
    self.rotation = internals.calculaterotation()

    self.rolling = false
    local survivors = {}
    table.foreach(self.balls, function(name, ball)
        if ball.body:isAwake() then self:applyfriction(ball, dt) end
        local x, y = ball.body:getPosition()
        if internals.ishole(x, y) then signals.emit("ball-in-hole", ball) end
        if ball.fixture then survivors[name] = ball end
    end)
    self.balls = survivors
    if table.maxn(survivors) == 0 then signals.emit("game-over") end
    if self.firsthit and not self.rolling then
        self.score = math.max(0, self.score - 1)
        self.firsthit = false
    end
end


------------------------------------------------------------------------
function Billiard:draw()
    table.foreach(self.balls, function(_, ball)
        local x, y = ball.body:getPosition()
        love.graphics.setColor(ball.color)
        love.graphics.circle("fill", x, y, ball.shape:getRadius())
    end)
end


------------------------------------------------------------------------
function Billiard:doscore(ball)
    if ball == self.balls.white then
        self.score = 0
        ball.body:setAwake(false)
        ball.body:setPosition(internals.startpos.x, internals.startpos.y)
    else
        self.score = self.score + 1
        ball.fixture:destroy()
        ball.body:destroy()
        ball.fixture = nil
    end
end


------------------------------------------------------------------------
function Billiard:increaseforce(dt)
    self.force = self.force + (internals.deltaforce * dt)
    if self.force > 100 then self.force = 100 end
end


------------------------------------------------------------------------
function Billiard:decreaseforce(dt)
    self.force = self.force - (internals.deltaforce * dt)
    if self.force < 0 then self.force = 0 end
end


------------------------------------------------------------------------
function Billiard:scaleforce(f)
    local x, b, r
    for x = 0, math.ceil(self.force) do
        b = 255 * (100 - x) / 100
        r = 255 * x / 100
        f(x, r, 0, b)
    end
end


------------------------------------------------------------------------
function Billiard:shot()
    if not self.rolling then
        local force = self.force * internals.max_force
        local angle = math.rad((180 + self.rotation) % 360)
        self.firsthit = true

        self.balls.white.body:applyForce(
            math.cos(angle) * force,
            math.sin(angle) * force
        )
    end
end


------------------------------------------------------------------------
function Billiard:collision(a, b, coll)
    local colsig = "ball-touches-border"
    if a:getUserData() == "ball" and b:getUserData() == "ball" then
        colsig = nil
        if self.firsthit and ((a == Billiard.balls.white.fixture) or (b == Billiard.balls.white.fixture)) then
            self.firsthit = false
            colsig = "white-hit"
        end
    end
    signals.emit("collision", colsig)
end


------------------------------------------------------------------------
function Billiard:applyfriction(ball, dt)
    -- Friction
    local x, y = ball.body:getLinearVelocity()
    x, y = internals.getfriction(x, y, internals.friction * dt)
    ball.body:applyForce(x, y)

    x, y = ball.body:getLinearVelocity()
    x, y = internals.nantozero(x), internals.nantozero(y)
    if (x * x) + (y * y) < internals.minvelocity then
        ball.body:setAwake(false)
    else
        self.rolling = true
    end
end


------------------------------------------------------------------------
function Billiard:loadborders()
    internals.borders.upleft = {
        body = love.physics.newBody(self.world, 200, 6, "static"),
        shape = love.physics.newRectangleShape(378, 12),
    }
    internals.borders.upleft.fixture = love.physics.newFixture(
        internals.borders.upleft.body, internals.borders.upleft.shape
    )
    internals.borders.upright = {
        body = love.physics.newBody(self.world, 600, 6, "static"),
        shape = love.physics.newRectangleShape(378, 12),
    }
    internals.borders.upright.fixture = love.physics.newFixture(
        internals.borders.upright.body, internals.borders.upright.shape
    )

    internals.borders.downleft = {
        body = love.physics.newBody(self.world, 200, 416, "static"),
        shape = love.physics.newRectangleShape(378, 12),
    }
    internals.borders.downleft.fixture = love.physics.newFixture(
        internals.borders.downleft.body, internals.borders.downleft.shape
    )
    internals.borders.downright = {
        body = love.physics.newBody(self.world, 600, 416, "static"),
        shape = love.physics.newRectangleShape(378, 12),
    }
    internals.borders.downright.fixture = love.physics.newFixture(
        internals.borders.downright.body, internals.borders.downright.shape
    )

    internals.borders.left = {
        body = love.physics.newBody(self.world, 6, 211, "static"),
        shape = love.physics.newRectangleShape(12, 378),
    }
    internals.borders.left.fixture = love.physics.newFixture(
        internals.borders.left.body, internals.borders.left.shape
    )

    internals.borders.right = {
        body = love.physics.newBody(self.world, 794, 211, "static"),
        shape = love.physics.newRectangleShape(12, 378),
    }
    internals.borders.right.fixture = love.physics.newFixture(
        internals.borders.right.body, internals.borders.right.shape
    )

    love.graphics.setBackgroundColor(0, 0, 0)
end


------------------------------------------------------------------------
function Billiard:loadballs()
    local size = 8
    local bounce = .9
    local mass = .4
    local density = 2
    local massdata

    self.balls.white = {
        body = love.physics.newBody(self.world, internals.startpos.x, internals.startpos.y, "dynamic"),
        shape = love.physics.newCircleShape(size),
        color = {0xff, 0xff, 0xff},
    }
    self.balls.white.fixture = love.physics.newFixture(
        self.balls.white.body, self.balls.white.shape, density
    )
    self.balls.white.body:setMass(mass)
    self.balls.white.fixture:setUserData "ball"
    self.balls.white.fixture:setRestitution(bounce)

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
        self.balls[i] = {
            body = love.physics.newBody(self.world, pos.x, pos.y, "dynamic"),
            shape = love.physics.newCircleShape(size),
            color = {0xff, 0x20, 0x20},
        }
        self.balls[i].fixture = love.physics.newFixture(
            self.balls[i].body, self.balls[i].shape, density
        )
        self.balls.white.body:setMass(mass)
        self.balls[i].fixture:setUserData "ball"
        self.balls[i].fixture:setRestitution(bounce)
    end)
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
    bx, by = Billiard.balls.white.body:getPosition()
    angle = vector.angleTo(bx - mx, by - my)
    return angle * 180 / math.pi
end


------------------------------------------------------------------------


------------------------------------------------------------------------
return Billiard
