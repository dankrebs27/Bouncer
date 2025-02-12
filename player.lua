-- player.lua
local player = {}
local initialVelocity = {x = 0, y = 0} -- Default initial velocity
local bounciness = 0.8
local playerImage = nil
local imageScale = 1
local baseRadius = 30
player.armour = 1
player.lastHitTime = 0
player.captureRadius = baseRadius -- Default capture radius same as ball radius

-- **Armour Break Animation Variables**
local armourBreakDuration = 0.5 -- **Time before animations fade out (modifiable)**
local armourBreakImages = {
    top = love.graphics.newImage("Assets/Images/armourbreak-top.png"),
    right = love.graphics.newImage("Assets/Images/armourbreak-right.png"),
    bottom = love.graphics.newImage("Assets/Images/armourbreak-bottom.png"),
    left = love.graphics.newImage("Assets/Images/armourbreak-left.png")
}
local armourBreakAnimations = {} -- **Stores active animations**

function player.init(world)
    -- Load the ball image
    playerImage = love.graphics.newImage("Assets/Images/redball.png")
    local ballRadius = 30

    -- Calculate scale based on current ball size (assuming radius 20)
    local imageWidth = playerImage:getWidth()
    local imageHeight = playerImage:getHeight()
    imageScale = (ballRadius * 2) / imageWidth -- Scale to match 40px diameter
    
    player.body = love.physics.newBody(world, 100, 80, "dynamic")
    player.shape = love.physics.newCircleShape(ballRadius)
    player.fixture = love.physics.newFixture(player.body, player.shape, 1)
    player.fixture:setRestitution(0)
    player.fixture:setUserData("player") -- Identify the player for collision checks
end

function player.update(dt)
    -- Ensure the ball's rotation does not affect gameplay
    --player.body:setAngularVelocity(0) -- Stop angular velocity

    for i = #armourBreakAnimations, 1, -1 do
        local anim = armourBreakAnimations[i]
        anim.time = anim.time + dt
        anim.alpha = 1 - (anim.time / armourBreakDuration) -- **Fade out over time**
        anim.x = anim.x + (anim.dx * dt * 2) -- **Move outward**
        anim.y = anim.y + (anim.dy * dt * 2)

        -- **Remove animation when time is up**
        if anim.time >= armourBreakDuration then
            table.remove(armourBreakAnimations, i)
        end
    end
end

function player.draw()
    if player.body and playerImage then
        local x, y = player.body:getX(), player.body:getY()

        -- **Draw the Capture Radius (Faint Yellow Circle)**
        love.graphics.setColor(1, 1, 0, 0.3) -- Yellow with low opacity
        love.graphics.setLineWidth(2) -- Thin line
        love.graphics.circle("line", x, y, player.captureRadius)

        -- **Draw the Player Ball**
        love.graphics.setColor(1, 1, 1) -- Ensure the sprite is drawn in full color
        love.graphics.draw(playerImage, x, y, 0, imageScale, imageScale, playerImage:getWidth() / 2, playerImage:getHeight() / 2)
    end

    for _, anim in ipairs(armourBreakAnimations) do
        love.graphics.setColor(1, 1, 1, anim.alpha) -- **Apply fading effect**
        love.graphics.draw(anim.img, anim.x, anim.y, 0, 1, 1, anim.img:getWidth() / 2, anim.img:getHeight() / 2)
    end

    -- Reset color after drawing animations
    love.graphics.setColor(1, 1, 1)
end

--Can I remove this?
function player.reset()
    player.body:setPosition(100, 50)
    player.body:setLinearVelocity(0, 0)
end

function player.increaseCaptureRadius(amount)
    player.captureRadius = player.captureRadius + amount
    print("Capture Radius increased to:", player.captureRadius)
end

function player.decreaseCaptureRadius(amount)
    player.captureRadius = math.max(baseRadius, player.captureRadius - amount) -- Prevent below base radius
    print("Capture Radius decreased to:", player.captureRadius)
end

function player.getCaptureRadius()
    return player.captureRadius
end

function player.setArmour(value)
    player.armour = math.max(0, value) -- Ensure armour is never negative
end

function player.getArmour()
    return player.armour
end

-- Function to remove 1 armour
function player.removeArmour()
    player.armour = player.armour - 1
end

function player.hitKiller()
    local currentTime = love.timer.getTime() -- Get the current time in seconds

    -- If the player was hit less than 0.5 seconds ago, ignore this hit
    if currentTime - player.lastHitTime < 0.5 then
        print("Ignoring repeated hit within cooldown window.")
        return
    end

    -- Update last hit time
    player.lastHitTime = currentTime

    if player.armour > 0 then
        print("Player hit a killer but has armour! Armour reduced by 1.")
        player.armour = player.armour - 1
        return
    end

    -- If no armour, normal death behavior
    --game.playerHitKiller()
end

function player.isBelowScreen()
    return player.body:getY() > 600
end

function player.getBody()
    return player.body
end

function player.getBounciness()
    return bounciness
end

function player.setBounciness(value)
    bounciness = value
    player.fixture:setRestitution(bounciness) -- Update physics restitution
end

-- Get the initial velocity
function player.getInitialVelocity()
    return initialVelocity.x, initialVelocity.y
end

-- Set the initial velocity (can be called when the game starts)
function player.setInitialVelocity(vx, vy)
    initialVelocity.x = vx
    initialVelocity.y = vy
end

function player.reset(x, y)
    player.body:setPosition(x or 100, y or 80)
    player.body:setLinearVelocity(0, 0)
    player.body:setAngularVelocity(0) -- Reset angular velocity

    -- **Recalculate trajectory after reset**
    --if game.isPaused then
    --    trajectory.calculate(player, platform.getPlatforms()) -- Ensure trajectory updates after death
    --end
end

function player.triggerArmourBreakAnimation()
    local x, y = player.body:getX(), player.body:getY()

    -- **Spawn four armour break pieces, moving in different directions**
    table.insert(armourBreakAnimations, { img = armourBreakImages.top, x = x, y = y - 20, dx = 0, dy = -20, alpha = 1, time = 0 })
    table.insert(armourBreakAnimations, { img = armourBreakImages.right, x = x + 20, y = y, dx = 20, dy = 0, alpha = 1, time = 0 })
    table.insert(armourBreakAnimations, { img = armourBreakImages.bottom, x = x, y = y + 20, dx = 0, dy = 20, alpha = 1, time = 0 })
    table.insert(armourBreakAnimations, { img = armourBreakImages.left, x = x - 20, y = y, dx = -20, dy = 0, alpha = 1, time = 0 })
end


return player
