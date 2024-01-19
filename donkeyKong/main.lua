local sti = require("src/lib/sti")
local windfield = require("src/lib/windfield")

local gameMap
local spriteSheet
local sprites = {}
local world

local frameWidth, frameHeight = 80, 64

local player = {
    x = 100,
    y = 534,
    width = frameWidth,
    height = frameHeight,
    velocityY = 0,
    isJumping = false,
    speed = 200,
    jumpStrength = -3000,  -- Negative for upward movement
    gravity = 500,
    collider
}


function love.load()
    gameMap = sti("src/map/map.lua")
    spriteSheet = love.graphics.newImage("sprites/mario.png")
    world = windfield.newWorld(0, 500, false) -- Gravity strength and whether the world allows sleep
    local sheetWidth, sheetHeight = spriteSheet:getDimensions()

    world:addCollisionClass('Player')
    world:addCollisionClass('Ground')

    player.collider = world:newRectangleCollider(player.x, player.y, player.width, player.height)
    player.collider:setType('dynamic')
    player.collider:setCollisionClass('Player')


    player.collider:setPreSolve(function(collider_1, collider_2, contact)
        if collider_2.collision_class == 'Ground' then
            local px, py = collider_1:getPosition()
            local gx, gy, gw, gh = collider_2:getBoundingBox()
            if py + player.height / 2 < gy + gh / 2 then  -- Check if player is above the ground
                player.isJumping = false
            end
        end
    end)

    local collisionLayer = gameMap.layers["collision"]
    if collisionLayer then
        for _, object in ipairs(collisionLayer.objects) do
            if object.shape == "rectangle" then
                local platformCollider = world:newRectangleCollider(object.x, object.y, object.width, object.height)
                platformCollider:setType('static')
                platformCollider:setCollisionClass('Ground')
                platformCollider:setAngle(math.rad(object.rotation or 0))
            end
        end
    end

    sprites[1] = love.graphics.newQuad(13, 0, frameWidth, frameHeight, sheetWidth, sheetHeight)  -- First sprite
    sprites[2] = love.graphics.newQuad(113, 0, frameWidth, frameHeight, sheetWidth, sheetHeight) -- Second sprite
    sprites[3] = love.graphics.newQuad(213, 0, frameWidth, frameHeight, sheetWidth, sheetHeight) -- Third sprite
end

local currentFrame = 1
local elapsedTime = 0
local frameDuration = 3  -- Duration of each frame in seconds
local keysPressed = {}


function love.keypressed(key)
    keysPressed[key] = true

    if keysPressed["space"] and not player.isJumping then
        player.collider:applyLinearImpulse(0, player.jumpStrength)
        player.isJumping = true
    end
end

function love.keyreleased(key)
    keysPressed[key] = nil
end


function love.update(dt)
    local vx, vy = player.collider:getLinearVelocity()
    if keysPressed["a"] then
        vx = -player.speed
    elseif keysPressed["d"] then
        vx = player.speed
    else
        vx = 0
    end

    player.collider:setLinearVelocity(vx, vy)

    elapsedTime = elapsedTime + dt
    if elapsedTime >= frameDuration then
        elapsedTime = 0
        currentFrame = currentFrame + 1
        if currentFrame > #sprites then
            currentFrame = 1
        end
    end
    
    world:update(dt)
end


function love.draw()
    gameMap:draw()
    local px, py = player.collider:getPosition()
    print(px, py)
    love.graphics.draw(spriteSheet, sprites[1], px - player.width / 2, py - player.height / 2)

    --local collisionLayer = gameMap.layers["collision"]
    --if collisionLayer then
    --    for _, object in ipairs(collisionLayer.objects) do
    --        local rotation = math.rad(object.rotation or 0) 
--
    --        love.graphics.push()
    --        love.graphics.translate(object.x, object.y) -- Move the origin to the object's position
    --        love.graphics.rotate(rotation) -- Apply rotation
--
    --        if object.shape == "rectangle" then
    --            love.graphics.rectangle("line", 0, 0, object.width, object.height)
    --        end
--
    --        love.graphics.pop()
    --    end
    --end 

    world:draw()
end