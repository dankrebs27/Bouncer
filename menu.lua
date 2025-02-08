-- menu.lua
local menu = {}

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
    love.graphics.printf("Main Menu", 0, 100, 800, "center")
    for _, button in ipairs(buttons) do
        love.graphics.setColor(0.5, 0.5, 0.5)
        love.graphics.rectangle("fill", button.x, button.y, button.width, button.height)
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf(button.label, button.x, button.y + 15, button.width, "center")
    end
end

function menu.handleClick(x, y)
    for _, button in ipairs(buttons) do
        if x >= button.x and x <= button.x + button.width and y >= button.y and y <= button.y + button.height then
            button.action()
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
