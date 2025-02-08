local killer = {}
-- local killers = {}
local killers = killers or {}
local worldReference = nil
local gameReference = nil

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
        y = math.random(80, 500 - height)
        validPosition = true
    
        local leftEdge = x
        local rightEdge = x + width
        local topEdge = y
        local bottomEdge = y + height
    
        -- Ensure none of the killer's edges are too close to any star
        for _, s in ipairs(gameReference.stars) do
            local starX, starY = s.x, s.y
    
            -- Check distance from each edge of the killer to the star's center
            local distanceLeft = math.sqrt((leftEdge - starX)^2 + (y + height / 2 - starY)^2)
            local distanceRight = math.sqrt((rightEdge - starX)^2 + (y + height / 2 - starY)^2)
            local distanceTop = math.sqrt((x + width / 2 - starX)^2 + (topEdge - starY)^2)
            local distanceBottom = math.sqrt((x + width / 2 - starX)^2 + (bottomEdge - starY)^2)
    
            if distanceLeft < 150 or distanceRight < 150 or distanceTop < 150 or distanceBottom < 150 then
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

    table.insert(killers, { body = body, shape = shape, fixture = fixture, width = width, height = height })
end



function killer.handleCollision(fixtureA, fixtureB, contact)
    for _, k in ipairs(killers) do
        -- Check if the collision involves a killer fixture
        if fixtureA == k.fixture or fixtureB == k.fixture then
            print("Player hit a killer!") -- Debugging output
            gameReference.playerHitKiller() -- Trigger player "death" event
        end
        return
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
