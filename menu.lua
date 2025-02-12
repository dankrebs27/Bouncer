-- menu.lua
local menu = {}
local centerY = 600 -- Half of new screen height (1200 / 2)

local buttons = {}

function menu.init()
    buttons = {
        { label = "Start", x = 300, y = 200, width = 200, height = 50, action = function() menu.startGame() end },
        { label = "Settings", x = 300, y = 270, width = 200, height = 50, action = function() menu.openSettings() end },
        { label = "Exit", x = 300, y = 340, width = 200, height = 50, action = function() love.event.quit() end },
    }
end

function menu.draw()
    love.graphics.setColor(1, 1, 1)

    love.graphics.printf("Main Menu", 0, centerY - 50, 800, "center") -- Move title up
    for _, button in ipairs(buttons) do
        love.graphics.setColor(0.5, 0.5, 0.5)
        love.graphics.rectangle("fill", button.x, button.y + centerY - 150, button.width, button.height)
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf(button.label, button.x, button.y + centerY - 135, button.width, "center")
    end
end

function menu.handleClick(x, y)
    for _, button in ipairs(buttons) do
        local adjustedY = button.y + centerY - 150 -- Match new vertical alignment

        if x >= button.x and x <= button.x + button.width and
           y >= adjustedY and y <= adjustedY + button.height then
            button.action()
            return
        end
    end
end


function menu.startGame()
    menu.onStart()
end

function menu.openSettings()
    print("Settings menu is not implemented yet.")
end

return menu
