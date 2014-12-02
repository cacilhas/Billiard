local gamestate = assert(require "hump.gamestate")
local signals = assert(require "hump.signal")
local timer = assert(require "hump.timer")
local sounds = assert(require "sounds")
local Billiard = assert(require "billiard")
local cue = {dist = 0, dir = 6 }
local shotcount = 0
local app, board, splash, pointer, font, gameoverfont


local menustate = {}
local mainstate = {}
local pausestate = {}
local gameoverstate = {}


------------------------------------------------------------------------
function love.load()
  love.mouse.setVisible(false)
  splash = love.graphics.newImage("images/splash.jpg")
  board = love.graphics.newImage("images/board.jpg")
  cue.img = love.graphics.newImage("images/cue.png")
  pointer = love.graphics.newImage("images/pointer.png")
  font = love.graphics.newFont("resources/PlantagenetCherokee.ttf", 24)
  gameoverfont = love.graphics.newFont("resources/brasil-new.ttf", 64)

  signals.register("shoot", function() shotcount = shotcount + 1 end)
  signals.register("game-over", function() gamestate.switch(gameoverstate) end)
  sounds.load()

  gamestate.registerEvents()
  gamestate.switch(menustate)
end


------------------------------------------------------------------------
-- Main state --
----------------
function mainstate:enter()
  app = Billiard()
  shotcount = 0
end


------------------------------------------------------------------------
function mainstate:update(dt)
  app:update(dt)

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
function mainstate:keypressed(key, isrepeat)
  if key == " " and not app.rolling then return signals.emit("shoot") end
end


------------------------------------------------------------------------
function mainstate:keyreleased(key)
  if key == "p" then return gamestate.push(pausestate)
  elseif key == "escape" then return gamestate.switch(menustate) end
end


------------------------------------------------------------------------
function mainstate:mousepressed(x, y, button)
  if button == "l" and not app.rolling then
    return signals.emit("shoot")

  elseif button == "wu" then
    return signals.emit("increase-force", .0625)

  elseif button == "wd" then
    return signals.emit("decrease-force", .0625)
  end
end


------------------------------------------------------------------------
function mainstate:draw()
  local x, y

  -- Draw board
  love.graphics.draw(board, 0, 0)

  -- Draw balls
  app:draw()

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
  app:scaleforce(function(x, r, g, b)
    love.graphics.setColor(r, g, b)
    love.graphics.rectangle("fill", x * 2 + 11, 433, 2, 98)
  end)

  -- Draw score
  love.graphics.setColor(0xff, 0xff, 0xff)
  love.graphics.setFont(font)
  love.graphics.print("Score: " .. app.score, 300, 432)
  love.graphics.print("Shots: " .. shotcount, 300, 464)

  -- Draw pointer
  if not app.rolling then
    x, y = love.mouse.getPosition()
    love.graphics.draw(pointer, x - 13, y - 13)
  end
end


------------------------------------------------------------------------
-- Menu state --
----------------
function menustate:enter()
  if app then return app:disconnecthandlers() end
end


------------------------------------------------------------------------
function menustate:keyreleased(key)
  if key == "return" then return gamestate.switch(mainstate)
  elseif key == "escape" then return love.event.quit() end
end


------------------------------------------------------------------------
function menustate:draw()
  love.graphics.setColor(0xff, 0xff, 0xff)
  love.graphics.draw(splash, 0, 0)
end


------------------------------------------------------------------------
-- Pause state --
-----------------
function pausestate:enter(previous)
  self.timer = timer.new()
  self.alpha = 0
  self.previous = previous
  return self.timer:tween(.5, self, {alpha=1}, "linear")
end


------------------------------------------------------------------------
function pausestate:leave()
  self.previous = nil
  return self.timer:clear()
end


------------------------------------------------------------------------
function pausestate:keyreleased(key)
  if key == "p" or key == "escape" then return gamestate.pop() end
end


------------------------------------------------------------------------
function pausestate:update(dt)
  return self.timer:update(dt)
end


------------------------------------------------------------------------
function pausestate:draw()
  if self.previous then self.previous:draw() end
  love.graphics.setColor(0x00, 0x00, 0x60, math.floor(0xa0 * self.alpha))
  local width, height = love.window.getDimensions()
  love.graphics.rectangle("fill", 0, 0, width, height)

  love.graphics.setColor(0xff, 0xff, 0x00, math.floor(0xff * self.alpha))
  love.graphics.setFont(gameoverfont)
  love.graphics.print("Paused", 312, 166)
end


------------------------------------------------------------------------
-- Game over state --
---------------------
function gameoverstate:enter(previous)
  self.previous = previous
  self.timer = timer.new()
  self.tx_game_x = -100
  self.tx_over_x = love.window.getWidth()
  self.timer:tween(2, self, {tx_game_x=272, tx_over_x=416}, "out-expo")
end


------------------------------------------------------------------------
function gameoverstate:leave()
  self.previous = nil
  return self.timer:clear()
end


------------------------------------------------------------------------
function gameoverstate:keyreleased(key)
  if key == "escape" then return gamestate.switch(menustate) end
end


------------------------------------------------------------------------
function gameoverstate:update(dt)
  return self.timer:update(dt)
end


------------------------------------------------------------------------
function gameoverstate:draw()
  if self.previous then self.previous:draw() end
  love.graphics.setColor(0xff, 0x00, 0x00)
  love.graphics.setFont(gameoverfont)
  love.graphics.print("Game", self.tx_game_x, 166)
  love.graphics.print("Over", self.tx_over_x, 166)
  love.graphics.setColor(0xff, 0xff, 0xff)
  love.graphics.draw(cue.img, 390, 432)
end
