local drawer = {}

local isOpen = false
local drawerWidth = 150
local drawerHeight = 600
local drawerX = 800 -- Initially positioned outside the window
local drawerTargetX = 800 -- Target X position for the animation
local tabWidth = 20
local tabHeight = 40
local tabX = drawerX - tabWidth
local animationSpeed = 500
local platformModule -- Reference to the platform module

local buttons = {
    { x = 0, y = 150, width = 50, height = 50, color = {0.5, 0.8, 1}, type = "ice" }, -- Ice platform
    { x = 0, y = 300, width = 50, height = 50, color = {1, 0, 0}, type = "base" }, -- Base platform
    { x = 0, y = 450, width = 50, height = 50, color = {0.8, 0.3, 1}, type = "power" }, -- Power platform
}

function drawer.init(platformRef, boonsRef)
    platformModule = platformRef
    boons = boonsRef -- Store reference to the boons module
end


function drawer.update(dt)
    if isOpen and drawerX > drawerTargetX then
        drawerX = math.max(drawerX - animationSpeed * dt, drawerTargetX)
    elseif not isOpen and drawerX < drawerTargetX then
        drawerX = math.min(drawerX + animationSpeed * dt, drawerTargetX)
    end

    tabX = drawerX - tabWidth
end

function drawer.draw()
    -- Draw the drawer background
    love.graphics.setColor(0.5, 0.5, 0.5)
    love.graphics.rectangle("fill", drawerX, 0, drawerWidth, drawerHeight)

    -- Draw the "Boons" label
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("Boons", drawerX + 10, 10, drawerWidth - 20, "center")

    -- Draw active boon icons
    local yOffset = 40 -- Start below the "Boons" label
    for _, boon in ipairs(boons.list) do
        if boon.active and boon.icon then
            love.graphics.draw(boon.icon, drawerX + 50, yOffset, 0, 0.75, 0.75) -- Scale 75%
            yOffset = yOffset + 50 -- Space out icons
        end
    end

    -- Draw the tab
    love.graphics.setColor(0.3, 0.3, 0.3)
    love.graphics.rectangle("fill", tabX, (drawerHeight - tabHeight) / 2, tabWidth, tabHeight)

    -- Draw the platform selection buttons
    for _, button in ipairs(buttons) do
        love.graphics.setColor(button.color)
        love.graphics.rectangle("fill", drawerX + button.x + 25, button.y, button.width, button.height)
    end
end


function drawer.handleMouseClick(x, y)
    -- Check if the tab is clicked
    if x >= tabX and x <= tabX + tabWidth and y >= (drawerHeight - tabHeight) / 2 and y <= (drawerHeight + tabHeight) / 2 then
        isOpen = not isOpen
        drawerTargetX = isOpen and (800 - drawerWidth) or 800
        return true
    end

    -- Check if any button is clicked
    for _, button in ipairs(buttons) do
        local buttonX = drawerX + button.x + 25
        if x >= buttonX and x <= buttonX + button.width and y >= button.y and y <= button.y + button.height then
            -- Use the platform module to set the platform type
            if platformModule then
                platformModule.setPlatformType(button.type) -- Correctly call setPlatformType
                print("Platform type set to:", button.type) -- Debugging
                return true
            else
                print("Error: Platform module not initialized")
            end
        end
    end

    return false
end

return drawer
