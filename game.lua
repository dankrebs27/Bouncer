local game = {}
local platform
local player
local star
local trajectory
local roomType -- Tracks the current room type
local run -- Tracks the player's current run data
local rewards

function game.init(playerModule, platformModule, starModule, trajectoryModule, boonsModule, killerModule, headerModule, rewardsModule)
    player = playerModule
    platform = platformModule
    star = starModule
    trajectory = trajectoryModule
    boons = boonsModule
    killer = killerModule
    header = headerModule
    drawer = drawerModule
    rewards = rewardsModule

    love.physics.setMeter(64)
    game.gravity = 600 -- Default gravity, can be adjusted
    game.world = love.physics.newWorld(0, game.gravity, true)
    game.isPaused = true
    game.strikes = 0
    game.maxStrikes = 2 -- Starts at 0 so max of 2 gives you 3 tries
    game.platformInventory = {
        base = 10,
        power = 5,
        ice = 3
    }
    game.stars = {} -- Positions of stars
    game.targets = {} -- Treasure room targets
    game.showMessage = nil
    game.levelCleared = false
    game.pendingReset = false
    game.boonPopup = nil
    roomType = "challenge" -- Default room type
    run = nil -- Initialize the run data

    trajectory.init({ gravity = {0, 500} }) -- Separate world for trajectory simulation
    killer.init(game.world, game)

    -- Register a new global collision handler
    game.world:setCallbacks(platform.handleCollision, nil, nil, killer.handleCollision)
end

function game.setRunData(newRun)
    run = newRun -- Store the current run data
    game.platformInventory = run.platformInventory
    drawer.init(platform, boons) -- Initialize the drawer with the platform module
end

function game.getRunData()
    return run
end

function game.setRoomType(type)
    roomType = type
end

function game.reset(fullReset)
    game.strikes = 0
    game.showMessage = nil
    game.levelCleared = false
    game.isPaused = true
    platform.clear()

    -- Reset maxStrikes to its base value before applying boons
    game.maxStrikes = 3

    if fullReset then
        game.platformInventory = {
            base = 10,
            power = 5,
            ice = 3
        }
    end

    -- Generate room-specific contents
    game.generateRoomContents()
end

function game.generateRoomContents()
    if roomType == "challenge" then
        player.reset(50, 50) -- Top-left position
        game.generateStars()
    elseif roomType == "treasure" then
        player.reset(400, 50) -- Top-middle position
        game.generateTargets()
    end
end

function game.generateStars(seed)
    if seed then
        math.randomseed(seed)
    else
        math.randomseed(os.time())
    end

    game.stars = {}
    for i = 1, 3 do
        local x = math.random(50, 750)
        local y = math.random(50, 550)
        table.insert(game.stars, { x = x, y = y })
    end

    star.setPositions(game.stars)
end

function game.generateTargets()
    local selectedBoons = boons.getRandomBoons()

    -- Place boon targets on the left and right sides of the screen
    game.targets = {
        { x = 150, y = 300, radius = 50, boon = selectedBoons[1] }, -- Left side
        { x = 650, y = 300, radius = 50, boon = selectedBoons[2] }  -- Right side
    }
end

function game.usePlatform(platformType)
    if not game.platformInventory or not game.platformInventory[platformType] then
        print("Error: Invalid platform type or inventory not initialized.")
        return false
    end

    if roomType == "treasure" then
        return true -- Allow one free platform in treasure rooms
    else
        if game.platformInventory[platformType] > 0 then
            game.platformInventory[platformType] = game.platformInventory[platformType] - 1
            return true
        end
        return false
    end
end

function game.update(dt)
    game.world:update(dt) -- First, update the physics world

    if math.random() < 0.005 then -- Print only sometimes to avoid spam
        print("Memory usage (KB):", collectgarbage("count"))
        print(gameState)
    end

    -- Room-specific logic
    if roomType == "treasure" then
        game.updateTreasureRoom()
    elseif roomType == "challenge" then
        game.updateChallengeRoom()
    end

    -- Now that physics is updated, we can safely reset the player
    if game.pendingReset then
        player.reset()
        star.resetToInitialPositions()
        game.pendingReset = false -- Reset flag
    end
end

function game.drawUI()
    local buttonYStart = 50 -- Position buttons below the header
    game.drawButton(700, buttonYStart, "Clear")     -- Draw "Clear" button
    game.drawButton(700, buttonYStart + 40, "Start")     -- Draw "Start" button

    -- Draw inventory and strikes
    love.graphics.setColor(1, 1, 1)

    --love.graphics.printf("Platforms:", 10, 10, 200, "left")
    --love.graphics.printf("Base: " .. game.platformInventory.base, 10, 30, 200, "left")
    --love.graphics.printf("Power: " .. game.platformInventory.power, 10, 50, 200, "left")
    --love.graphics.printf("Ice: " .. game.platformInventory.ice, 10, 70, 200, "left")

    love.graphics.printf("Tries: " .. game.strikes, 700, 140, 80, "center")

    -- Draw room-specific elements
    -- Treasure room stuff
    if roomType == "treasure" then
        if game.boonPopup then
            -- Draw pop-up background
            love.graphics.setColor(0, 0, 0, 0.8)
            love.graphics.rectangle("fill", 200, 200, 400, 250)
        
            -- Draw pop-up text
            love.graphics.setColor(1, 1, 1)
            love.graphics.printf(game.boonPopup.name .. " acquired!", 250, 220, 300, "center")
        
            -- Draw boon icon
            if game.boonPopup.icon then
                love.graphics.draw(game.boonPopup.icon, 350, 260, 0, 1.5, 1.5) -- Scale icon
            end
        
            -- Draw "Continue" button
            love.graphics.setColor(0.5, 0.5, 0.5)
            love.graphics.rectangle("fill", 300, 400, 200, 50)
            love.graphics.setColor(1, 1, 1)
            love.graphics.printf("Continue", 300, 415, 200, "center")
        end

        for _, target in ipairs(game.targets) do
            if target.boon and target.boon.icon then
                love.graphics.setColor(1, 1, 1)
                love.graphics.draw(target.boon.icon, target.x - 50, target.y - 50, 0, 2, 2) -- Scale x2
            end
        end
    else
    -- Draw stars for challenge rooms
        star.draw()
    end

    -- Draw trajectory if paused and not in a treasure room
    if game.levelCleared and roomType ~= "treasure" then
        love.graphics.setColor(0, 0, 0, 0.8)
        love.graphics.rectangle("fill", 200, 200, 400, 300) -- Increased height for rewards
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("Level Cleared!", 200, 220, 400, "center")

        -- **Draw Rewards**
        if game.rewardsSelection then
            for i, reward in ipairs(game.rewardsSelection) do
                local yOffset = 260 + (i * 40)

                -- Highlight selected reward
                if game.selectedReward == i then
                    love.graphics.setColor(1, 1, 0.5) -- Light yellow highlight
                else
                    love.graphics.setColor(1, 1, 1) -- Default white
                end
                
                love.graphics.printf(reward.name, 250, yOffset, 300, "center")
            end
        end

        -- **Draw "Continue" button**
        love.graphics.setColor(0.5, 0.5, 0.5)
        love.graphics.rectangle("fill", 300, 450, 200, 50)
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("Continue", 300, 465, 200, "center")
    --elseif game.showMessage then
    --    love.graphics.printf(game.showMessage, 0, 250, 800, "center")
    end
end

function game.updateChallengeRoom()
    -- Handle ball falling below the screen
    if player.isBelowScreen() then
        if game.strikes < game.maxStrikes then
            game.strikes = game.strikes + 1
            game.pendingReset = true
            game.isPaused = true
        else
            game.showMessage = "You lose!"
            game.isPaused = true
        end
    -- Handle collecting all stars
    elseif star.allCollected() then
        game.levelCleared = true
        game.isPaused = true

        game.rewardsSelection = rewards.getRandomRewards()
        game.selectedReward = nil
    end
end

function game.updateTreasureRoom()
    local px, py = player.body:getX(), player.body:getY()

    -- Check if player collected a boon
    for i, target in ipairs(game.targets) do
        if math.sqrt((px - target.x)^2 + (py - target.y)^2) < target.radius then
            boons.activateBoon(target.boon.name)
            game.isPaused = true
            game.boonPopup = {
                name = target.boon.name,
                icon = target.boon.icon
            }
            table.remove(game.targets, i)
            break
        end
    end

    -- Ensure level does not auto-clear while the boon popup is active
    if #game.targets == 1 and game.boonPopup == nil then
        game.levelCleared = true
        game.isPaused = true
    end
end

function game.drawButton(x, y, label)
    love.graphics.setColor(0.5, 0.5, 0.5)
    love.graphics.rectangle("fill", x, y, 80, 30)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf(label, x, y + 5, 80, "center")
end

function game.handleMouseClick(x, y)
    --If boonpopup is active
    if game.boonPopup then
        if x >= 300 and x <= 500 and y >= 400 and y <= 450 then
            game.boonPopup = nil -- Close the pop-up
            gameState = "map"
            print(gameState)
            game.levelCleared = true
            game.isPaused = false
            if game.onLevelCompleteCallback then
                game.onLevelCompleteCallback()
            end
            return true
        end
    end
    
    if game.levelCleared then
        -- **Check if a reward is clicked**
        if game.rewardsSelection then
            for i, reward in ipairs(game.rewardsSelection) do
                local rewardY = 260 + (i * 40)
                if x >= 250 and x <= 550 and y >= rewardY and y <= rewardY + 30 then
                    game.selectedReward = i -- **Set the selected reward**
                    print("Selected reward:", reward.name)
                    return true
                end
            end
        end

        -- **Check if "Continue" is clicked**
        if x >= 300 and x <= 500 and y >= 450 and y <= 500 then
            if game.selectedReward and game.rewardsSelection then
                -- **Apply the selected reward**
                rewards.applyReward(game.rewardsSelection[game.selectedReward].name)
            end
            
            -- **Return to map after selecting reward**
            gameState = "map"
            print("Returning to map...")
            game.levelCleared = false
            game.isPaused = false
            if game.onLevelCompleteCallback then
                game.onLevelCompleteCallback()
            end
            return true
        end

    elseif x >= 700 and x <= 780 then
        if y >= 50 and y <= 80 then
            local clearedCounts = platform.clear()
            for type, count in pairs(clearedCounts) do
                game.platformInventory[type] = game.platformInventory[type] + count
            end
            return true
        elseif y >= 90 and y <= 120 then
            game.isPaused = false
            return true
        end
    end
    return false
end

function game.loadChallengeRoom()
    roomType = "challenge" -- Set the room type
    player.reset(50, 80) -- Position for challenge rooms
    game.generateStars() -- Generate stars for the challenge room
    game.isPaused = true -- Pause the game initially

    game.strikes = 0
    game.maxStrikes = 2
    -- Apply "Extra Try" boon if active
    if boons.hasBoon("Extra Try") then
        game.maxStrikes = game.maxStrikes + 1
    end

    killer.clear() -- Remove old killers
    platform.clear() -- Ensure old platforms are removed
    killer.spawnRandom() -- Spawn a new killer
end

function game.loadTreasureRoom()
    roomType = "treasure" -- Set the room type
    player.reset(400, 80) -- Position for treasure rooms
    game.generateTargets() -- Generate targets for the treasure room
    game.isPaused = true -- Pause the game initially

    killer.clear()
end

function game.onLevelComplete(callback)
    game.onLevelCompleteCallback = function()
        header.incrementLevel() -- Increase the level count
        callback()
    end
end


function game.playerHitKiller()
    print("Player hit a killer! Losing a try.")

    if game.strikes < game.maxStrikes then
        game.strikes = game.strikes + 1
        game.pendingReset = true -- Mark the player for reset AFTER physics update
        game.isPaused = true
    else
        game.showMessage = "You lose!"
        game.isPaused = true
    end
end

function game.getPlayer()
    return player
end


return game
