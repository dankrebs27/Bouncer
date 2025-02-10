local game = require("game")
local platform = require("platform")
local player = require("player")
local star = require("star")
local menu = require("menu")
local map = require("map")
local trajectory = require("trajectory")
local run = require("run")
local killer = require("killer")
local drawer = require("drawer")
local boons = require("boons")
local header = require("header")
local rewards = require("rewards")


local gameState = "menu" -- Possible states: "menu", "map", "play"
local levelSelected = nil -- Track the selected level

function love.load()
    love.window.setTitle("Draw Platforms Game")
    love.window.setMode(800, 600)

    -- Initialize menu
    menu.init()
    menu.onStart = function()
        run.startNew() -- Initialize the new run
        map.init(function(levelID)
            levelSelected = levelID
            startGameForLevel(levelID)
        end, game, run) -- Pass run module to map
        gameState = "map" -- Transition to the map screen
    end


    -- Initialize game modules
    game.init(player, platform, star, trajectory, boons, killer, header, rewards)
    platform.init(game.world, game)
    player.init(game.world)
    star.init(player)
    drawer.init(platform, boons) -- Pass the platform module to drawer
    trajectory.init({ gravity = { 0, 500 } })
    header.init(run, player) -- Initialize the header with run data
    rewards.init(game, player, run)

    -- Register collision callback for the physics world
    game.world:setCallbacks(platform.handleCollision, nil, nil, killer.handleCollision)

    -- Handle level completion
    game.onLevelComplete(function()
        map.markLevelComplete(levelSelected) -- Mark the level as completed
        gameState = "map" -- Return to the map screen
    end)
end

function love.update(dt)
    if gameState == "play" then
        drawer.update(dt) -- Always update the drawer
        platform.update(dt)
        if not game.isPaused then
            game.update(dt)
            player.update(dt)
            star.update(dt)
        end
    end
end

function love.draw()
    if gameState == "menu" then
        menu.draw()
    else
        header.draw(gameState, game.platformInventory) -- Only draws when in map or play mode

        if gameState == "map" then
            map.draw()
        elseif gameState == "play" then
            player.draw()
            platform.draw()
            star.draw()
            killer.draw()
            game.drawUI()
            drawer.draw()
        end
    end
end


function love.mousepressed(x, y, button)
    if button == 1 then
        if gameState == "menu" then
            menu.handleClick(x, y)
        elseif gameState == "map" then
            map.handleClick(x, y)
        elseif gameState == "play" then
            if drawer.handleMouseClick(x, y) then return end
            if game.handleMouseClick(x, y) then return end
            platform.startDrawing(x, y)
        end
    end
end

function love.mousereleased(x, y, button)
    if button == 1 and gameState == "play" then
        platform.finishDrawing()
    end
end

function love.keypressed(key)
    if gameState == "play" and key == "r" then
        game.reset()
    end
end

function love.wheelmoved(x, y)
    if gameState == "map" then
        map.handleScroll(y)
    end
end


function startGameForLevel(roomType)
    print("Starting room: " .. roomType) -- Debug info
    gameState = "play"

    -- Clear platforms & reset game state
    platform.clear()
    game.levelCleared = false
    game.showMessage = nil
    
    -- Use roomType to determine the room content
    if roomType == "challenge" then
        game.loadChallengeRoom()
    elseif roomType == "treasure" then
        game.loadTreasureRoom()
    elseif roomType == "mystery" then
        if math.random() <= 0.7 then
            game.loadChallengeRoom()
        else
            game.loadTreasureRoom()
        end
    end
end


