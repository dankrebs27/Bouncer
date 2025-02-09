local platform = {}
--local platforms = {}
local platforms = platforms or {}
local isDrawing = false
local currentPlatform = nil
local maxLength = 100

local selectedPlatform = nil
local interactionType = nil -- "move" or "rotate"
local dragOffsetX, dragOffsetY = 0, 0 -- Offset for dragging

local bounceSounds = {
    base = love.audio.newSource("Assets/Sound/Bounce1.mp3", "static"),
    power = love.audio.newSource("Assets/Sound/PowerBounce.mp3", "static"),
    ice = love.audio.newSource("Assets/Sound/IceBounce.mp3", "static")
}

local gameReference = nil -- Reference to the game module

-- Default platform type
local currentPlatformType = "base"

-- Bounciness values for different platform types
local platformBounciness = {
    base = .9,
    ice = 0.2,
    power = 1.3
}

local platformColors = {
    base = {1, 0, 0},       -- Red
    ice = {0.5, 0.8, 1},    -- Ice blue
    power = {0.8, 0.3, 1}   -- Bright purple
}

function platform.init(world, gameModule)
    platform.world = world
    gameReference = gameModule -- Assign the game module reference
end

function platform.update(dt)
    if isDrawing and currentPlatform then
        -- Update the platform being drawn
        local mx, my = love.mouse.getPosition()
        local dx = mx - currentPlatform.x1
        local dy = my - currentPlatform.y1
        local length = math.sqrt(dx^2 + dy^2)

        -- Constrain the platform's length to maxLength
        if length > maxLength then
            local scale = maxLength / length
            dx = dx * scale
            dy = dy * scale
        end

        currentPlatform.x2 = currentPlatform.x1 + dx
        currentPlatform.y2 = currentPlatform.y1 + dy
    elseif selectedPlatform and love.mouse.isDown(1) then
        -- Handle dragging or rotating a selected platform
        local mx, my = love.mouse.getPosition()
        if interactionType == "move" then
            -- Dragging logic
            local dx = mx - dragOffsetX
            local dy = my - dragOffsetY
            selectedPlatform.x1 = selectedPlatform.x1 + dx
            selectedPlatform.y1 = selectedPlatform.y1 + dy
            selectedPlatform.x2 = selectedPlatform.x2 + dx
            selectedPlatform.y2 = selectedPlatform.y2 + dy

            dragOffsetX, dragOffsetY = mx, my
        elseif interactionType == "rotate" then
            -- Rotating logic
            local pivotX, pivotY = selectedPlatform.x1, selectedPlatform.y1
            local dx = mx - pivotX
            local dy = my - pivotY
            local length = math.sqrt(dx^2 + dy^2)

            if length > maxLength then
                local scale = maxLength / length
                dx = dx * scale
                dy = dy * scale
            end

            selectedPlatform.x2 = pivotX + dx
            selectedPlatform.y2 = pivotY + dy
        end

        -- Update physics body of the platform
        platform.updatePhysics(selectedPlatform)
    end
end

function platform.handleCollision(fixtureA, fixtureB, contact)
    for _, p in ipairs(platforms) do
        -- Check if one of the colliding fixtures belongs to a platform
        if fixtureA == p.fixture or fixtureB == p.fixture then
            local restitution = p.fixture:getRestitution()
            print("Collision detected with platform type:", p.type)
            print("Restitution applied on collision:", restitution)

            local sound = bounceSounds[p.type] -- Get the correct sound for platform type
            if sound then
                sound:play()
            end
            return
        end
    end
end

function platform.startDrawing(x, y)
    -- Check if the click interacts with an existing platform
    for _, p in ipairs(platforms) do
        -- Check if the click is near the middle for dragging
        local centerX = (p.x1 + p.x2) / 2
        local centerY = (p.y1 + p.y2) / 2
        local length = math.sqrt((p.x2 - p.x1)^2 + (p.y2 - p.y1)^2)

        if math.abs(centerX - x) < length * 0.4 and math.abs(centerY - y) < length * 0.4 then
            -- Select platform for moving
            selectedPlatform = p
            interactionType = "move"
            dragOffsetX, dragOffsetY = x, y
            return
        end

        -- Check if the click is near an endpoint for rotating
        if math.sqrt((p.x1 - x)^2 + (p.y1 - y)^2) < 15 or math.sqrt((p.x2 - x)^2 + (p.y2 - y)^2) < 15 then
            -- Select platform for rotating
            selectedPlatform = p
            interactionType = "rotate"
            return
        end
    end

    -- If no platform interaction, start drawing a new platform
    if gameReference and gameReference.usePlatform(currentPlatformType) then
        isDrawing = true
        currentPlatform = {
            x1 = x,
            y1 = y,
            x2 = x,
            y2 = y,
            type = currentPlatformType
        }
    end
end

function platform.finishDrawing()
    if isDrawing and currentPlatform then
        -- Create a static platform as a physics body
        local body = love.physics.newBody(platform.world, 0, 0, "static")
        local shape = love.physics.newEdgeShape(currentPlatform.x1, currentPlatform.y1, currentPlatform.x2, currentPlatform.y2)
        local fixture = love.physics.newFixture(body, shape)

        -- Debug Print
        print("Creating platform of type:", currentPlatform.type)
        print("Assigned restitution:", platformBounciness[currentPlatform.type])

        fixture:setRestitution(platformBounciness[currentPlatform.type]) -- Set bounciness based on platform type

        -- Save the platform
        table.insert(platforms, {
            body = body,
            shape = shape,
            fixture = fixture, -- Save the fixture for collision detection
            x1 = currentPlatform.x1,
            y1 = currentPlatform.y1,
            x2 = currentPlatform.x2,
            y2 = currentPlatform.y2,
            type = currentPlatform.type -- Store the platform type
        })

        isDrawing = false
        currentPlatform = nil

    elseif selectedPlatform then
        -- Release interaction with a platform
        selectedPlatform = nil
        interactionType = nil
    end

end

function platform.updatePhysics(p)
    if p.body then
        p.body:destroy()
    end
    p.body = love.physics.newBody(platform.world, 0, 0, "static")
    p.shape = love.physics.newEdgeShape(p.x1, p.y1, p.x2, p.y2)
    p.fixture = love.physics.newFixture(p.body, p.shape)

    -- Debugging
    --print("Updating platform physics for:", p.type)
    --print("New restitution set:", platformBounciness[p.type])

    p.fixture:setRestitution(platformBounciness[p.type]) -- Update bounciness
end

function platform.draw()
    -- Draw existing platforms
    for _, p in ipairs(platforms) do
        local color = platformColors[p.type] or {1, 1, 1}
        love.graphics.setColor(color)
        love.graphics.setLineWidth(4)
        love.graphics.line(p.x1, p.y1, p.x2, p.y2)
    end

    -- Draw the platform currently being created
    if isDrawing and currentPlatform then
        local color = platformColors[currentPlatform.type] or {1, 1, 1}
        love.graphics.setColor(color[1], color[2], color[3], 0.5)
        love.graphics.setLineWidth(4)
        love.graphics.line(currentPlatform.x1, currentPlatform.y1, currentPlatform.x2, currentPlatform.y2)
    end
end

function platform.setPlatformType(type)
    currentPlatformType = type
end

function platform.clear()
    local clearedCounts = { base = 0, power = 0, ice = 0 }

    -- Destroy all platform physics bodies and clear the list
    for _, p in ipairs(platforms) do
        clearedCounts[p.type] = clearedCounts[p.type] + 1
        p.body:destroy()
    end

    platforms = {}

    return clearedCounts -- Return the count of cleared platforms
end

function platform.getPlatforms()
    return platforms
end

return platform
