local boons = {}

local boons = {}

boons.icons = {
    ["Bouncy Ball"] = love.graphics.newImage("Assets/Images/BouncyBoon.png"),
    ["Gravitron"] = love.graphics.newImage("Assets/Images/GravBoon.png"),
    ["Lucky Finder"] = love.graphics.newImage("Assets/Images/LuckyBoon.png"),
    ["Doubler"] = love.graphics.newImage("Assets/Images/DoublerBoon.png"),
    ["Trajectory"] = love.graphics.newImage("Assets/Images/TrajBoon.png"),
    ["Timestop"] = love.graphics.newImage("Assets/Images/TimeStopBoon.png"),
    ["Armour"] = love.graphics.newImage("Assets/Images/ArmourBoon.png"),
    ["Extra Try"] = love.graphics.newImage("Assets/Images/ExtraTryBoon.png")
}


boons.list = {
    { name = "Bouncy Ball", description = "Increases ball bounce height.", icon = boons.icons["Bouncy Ball"], active = false },
    { name = "Gravitron", description = "Pulls stars and powerups to it.", icon = boons.icons["Gravitron"], active = false },
    { name = "Lucky Finder", description = "Higher chance of platforms appearing in rooms", icon = boons.icons["Lucky Finder"], active = false },
    { name = "Doubler", description = "Every object you collect has a chance to double", icon = boons.icons["Doubler"], active = false },
    { name = "Trajectory", description = "View the initial path of the ball before the game starts", icon = boons.icons["Trajectory"], active = false },
    { name = "Timestop", description = "Allowed to stop time and adjust platform", icon = boons.icons["Timestop"], active = false },
    { name = "Armour", description = "Armour that can take 3 hits from spikes/enemies before falling off", icon = boons.icons["Armour"], active = false },
    { name = "Extra Try", description = "Gain an extra attempt before failing a level.", icon = boons.icons["Extra Try"], active = true }
}

--Function to activate boon in boon list
function boons.activateBoon(boonName)
    for _, boon in ipairs(boons.list) do
        if boon.name == boonName then
            boon.active = true
            print("Boon activated:", boonName)
            return
        end
    end
    print("Error: Boon not found:", boonName)
end

-- Function to get 3 random boons
function boons.getRandomBoons()
    local availableBoons = {}

    -- Only include boons that are NOT active
    for _, boon in ipairs(boons.list) do
        if not boon.active then
            table.insert(availableBoons, boon)
        end
    end

    -- Shuffle available boons
    for i = #availableBoons, 2, -1 do
        local j = math.random(i)
        availableBoons[i], availableBoons[j] = availableBoons[j], availableBoons[i]
    end

    -- Return the first 2 shuffled boons
    return { availableBoons[1], availableBoons[2] }
end


--Check to see if boon is active
function boons.hasBoon(boonName)
    for _, boon in ipairs(boons.list) do
        if boon.name == boonName and boon.active then
            return true
        end
    end
    return false
end

return boons
