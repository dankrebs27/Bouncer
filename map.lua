local map = {}

local levels = {}
local icons = {} -- Store icons here
local gameReference = nil -- Reference to the game module
local onLevelSelect = nil -- Callback for when a level is selected
local iconScale = 1.5 -- Scale icons to 150% of their original size
local scrollOffset = 0 -- Tracks the current scroll position
local maxScroll = 0 -- Maximum scrollable height
local windowWidth, windowHeight = 800, 600 -- Window dimensions
local activeRow = 1 -- Tracks the currently active row
local runSeedMap = nil

function map.init(onSelectCallback, gameModule, runModule)
    -- Load icons once
    icons.challenge = love.graphics.newImage("Assets/Images/ChallengeIcon.png")
    icons.treasure = love.graphics.newImage("Assets/Images/TreasureIcon.png")
    icons.mystery = love.graphics.newImage("Assets/Images/MysteryIcon.png")
    -- Use the run seed for deterministic room generation
    if runModule then
        if runModule.seed then
            math.randomseed(runModule.seed)
        else
            print("Seed is nil!")
        end
    else
        print("Run module is nil!")
    end

    -- Generate 120 levels
    local rows, cols = 30, 4 -- 30 rows, 4 columns
    local gridWidth = windowWidth * 0.7 -- 70% of window width
    local buttonWidth, buttonHeight = 150, 100
    local spacingX = (gridWidth - (cols * buttonWidth)) / (cols - 1)
    local spacingY = 20
    local offsetShift = (buttonWidth + spacingX) / 2 -- Half-width shift for staggered rows
    local startX = (windowWidth - gridWidth) / 2 - offsetShift / 2 -- Adjust grid to center staggered layout
    local startY = 100
    levels = {}

    for row = 1, rows do
        for col = 1, cols do
            -- Apply horizontal offset for every other row
            local offsetX = (row % 2 == 0) and offsetShift or 0
            local x = startX + offsetX + (col - 1) * (buttonWidth + spacingX)
            local y = startY + (row - 1) * (buttonHeight + spacingY)

            -- Determine room type with updated probabilities
            local rand = math.random()
            local roomType
            local icon
            if rand <= 0.65 then
                roomType = "challenge"
                icon = icons.challenge
            elseif rand <= 0.95 then
                roomType = "mystery"
                icon = icons.mystery
            else
                roomType = "treasure"
                icon = icons.treasure
            end

            table.insert(levels, {
                x = x,
                y = y,
                width = buttonWidth,
                height = buttonHeight,
                levelID = roomType,
                icon = icon,
                row = row, -- Track which row this level belongs to
                completed = false -- Initially, no levels are completed
            })
        end
    end

    -- Calculate the maximum scrollable height
    local lastLevel = levels[#levels]
    maxScroll = (lastLevel.y + buttonHeight) - windowHeight

    activeRow = 1 -- Reset the active row at the start of a new run
    onLevelSelect = onSelectCallback -- Assign the callback for level selection
    gameReference = gameModule -- Assign reference to the game module
end

function map.draw()
    love.graphics.setBackgroundColor(0.824, 0.706, 0.549) -- Tan color background

    -- Apply scrolling
    love.graphics.push()
    love.graphics.translate(0, -scrollOffset)

    -- Draw platform inventory count
    if gameReference then
        love.graphics.setColor(1, 1, 1)
        --love.graphics.printf("Platforms Remaining:", 10, 10 + scrollOffset, 200, "left")
        --love.graphics.printf("Base: " .. gameReference.platformInventory.base, 10, 30 + scrollOffset, 200, "left")
        --love.graphics.printf("Power: " .. gameReference.platformInventory.power, 10, 50 + scrollOffset, 200, "left")
        --love.graphics.printf("Ice: " .. gameReference.platformInventory.ice, 10, 70 + scrollOffset, 200, "left")

    end

    -- Draw level icons
    for _, level in ipairs(levels) do
        local scaledWidth = level.icon:getWidth() * iconScale
        local scaledHeight = level.icon:getHeight() * iconScale
        local iconX = level.x + (level.width - scaledWidth) / 2
        local iconY = level.y + (level.height - scaledHeight) / 2

        -- Dim icons that are unselectable
        if level.row == activeRow then
            love.graphics.setColor(1, 1, 1) -- Fully visible for active row
        elseif level.completed then
            love.graphics.setColor(0.5, 0.5, 0.5) -- Dim completed levels
        else
            love.graphics.setColor(0.3, 0.3, 0.3) -- Dim inactive rows
        end

        -- Draw the scaled icon
        love.graphics.draw(level.icon, iconX, iconY, 0, iconScale, iconScale)
    end

    love.graphics.pop() -- Reset translation
end

function map.handleClick(x, y)
    local adjustedY = y + scrollOffset -- Adjust for scrolling
    for _, level in ipairs(levels) do
        if level.row == activeRow and not level.completed and
           adjustedY >= level.y and adjustedY <= level.y + level.height and
           x >= level.x and x <= level.x + level.width then
            if onLevelSelect then
                onLevelSelect(level.levelID) -- Trigger the callback for level selection
            end
            return
        end
    end
end

function map.handleScroll(delta)
    scrollOffset = math.max(0, math.min(scrollOffset - delta * 30, maxScroll))
end

function map.markLevelComplete(levelID)
    for _, level in ipairs(levels) do
        if level.levelID == levelID then
            level.completed = true
            activeRow = math.min(activeRow + 1, #levels) -- Move to the next row
            break
        end
    end
end

return map
