local killer = {}
-- local killers = {}
local killers = killers or {}
local worldReference = nil
local gameReference = nil
local killerRestitution = 1.2

function killer.init(world, game)
    worldReference = world
    gameReference = game
end

function killer.spawnRandom()
    local width = math.random(40, 200)
    local height = math.random(40, 200)
    local x, y
    local validPosition = false
    local maxAttempts = 10
    local attempts = 0

    while not validPosition and attempts < maxAttempts do
        x = math.random(50, 750 - width)
        y = math.random(80, 1100 - height) -- Updated to allow lower half spawning
        validPosition = true
    
        local leftEdge = x
        local rightEdge = x + width
        local topEdge = y
        local bottomEdge = y + height
    
        -- Ensure killers do not overlap stars
        for _, s in ipairs(gameReference.stars) do
            local starX, starY = s.x, s.y
            local distance = math.sqrt((x - starX)^2 + (y - starY)^2)

            if distance < 150 then
                validPosition = false -- Too close, retry placement
                break
            end
        end

        attempts = attempts + 1
    end    

    local body = love.physics.newBody(worldReference, x + width / 2, y + height / 2, "static")
    local shape = love.physics.newRectangleShape(width, height)
    local fixture = love.physics.newFixture(body, shape)

    fixture:setUserData("killer")
    fixture:setRestitution(killerRestitution) -- Keep bounciness

    table.insert(killers, { body = body, shape = shape, fixture = fixture, width = width, height = height })
end


function killer.handleCollision(fixtureA, fixtureB, contact)
    for _, k in ipairs(killers) do
        -- Check if the collision involves a killer fixture
        if fixtureA == k.fixture or fixtureB == k.fixture then
            local player = gameReference:getPlayer()

            if not player then
                print("ERROR: Player reference is nil in killer.handleCollision()")
                return
            end

            local currentTime = love.timer.getTime()
            -- If the player was hit less than 0.5 seconds ago, ignore this hit
            if currentTime - player.lastHitTime < 0.5 then
                print("Ignoring repeated hit within cooldown window.")
                return
            end
            -- Update last hit time
            player.lastHitTime = currentTime

            if player.getArmour() > 0 then
                print("Player hit a killer but has armour! Armour reduced by 1.")
                player.triggerArmourBreakAnimation()
                player.removeArmour()
            else
                gameReference.playerHitKiller() -- Normal death
            end
            return
        end
    end
end

function killer.draw()
    for _, k in ipairs(killers) do
        local x, y = k.body:getX(), k.body:getY() -- Use the body's position
        love.graphics.setColor(1, 0, 0)
        love.graphics.rectangle("fill", x - k.width / 2, y - k.height / 2, k.width, k.height)
    end
end


function killer.clear()
    for _, k in ipairs(killers) do
        if k.body then
            k.body:destroy() -- Ensure physics bodies are removed
        end
    end
    killers = {}
end

return killer
