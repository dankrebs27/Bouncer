local rewards = {}

function rewards.init(gameModule, playerModule, runModule)
    rewards.game = gameModule
    rewards.player = playerModule
    rewards.run = runModule
end

-- **List of Rewards**
rewards.list = {
    { name = "Base Platform", description = "Gives 1 base platform.", effect = function()
        rewards.game.platformInventory.base = rewards.game.platformInventory.base + 1
        print("Reward: +1 Base Platform")
    end },

    { name = "Power Platform", description = "Gives 1 power platform.", effect = function()
        rewards.game.platformInventory.power = rewards.game.platformInventory.power + 1
        print("Reward: +1 Power Platform")
    end },

    { name = "Ice Platform", description = "Gives 1 ice platform.", effect = function()
        rewards.game.platformInventory.ice = rewards.game.platformInventory.ice + 1
        print("Reward: +1 Ice Platform")
    end },

    { name = "Base Platform Bundle", description = "Gives 3 base platforms.", effect = function()
        rewards.game.platformInventory.base = rewards.game.platformInventory.base + 3
        print("Reward: +3 Base Platforms")
    end },

    { name = "Platform Bundle", description = "Gives 1 of each platform type.", effect = function()
        rewards.game.platformInventory.base = rewards.game.platformInventory.base + 1
        rewards.game.platformInventory.power = rewards.game.platformInventory.power + 1
        rewards.game.platformInventory.ice = rewards.game.platformInventory.ice + 1
        print("Reward: +1 of each platform")
    end },

    { name = "Gravity Increase", description = "Increases game gravity by 0.1.", effect = function()
        rewards.game.gravity = rewards.game.gravity + 0.1
        rewards.game.world:setGravity(0, rewards.game.gravity)
        print("Reward: Gravity Increased to " .. rewards.game.gravity)
    end },

    { name = "Gravity Decrease", description = "Decreases game gravity by 0.1.", effect = function()
        rewards.game.gravity = rewards.game.gravity - 0.1
        rewards.game.world:setGravity(0, rewards.game.gravity)
        print("Reward: Gravity Decreased to " .. rewards.game.gravity)
    end },

    { name = "Ball Armour", description = "Adds 1 armour plating to the ball.", effect = function()
        rewards.player.setArmour(rewards.player.getArmour() + 1)
        print("Reward: +1 Ball Armour (Total: " .. rewards.player.getArmour() .. ")")
    end },

    { name = "Ball Capture Radius", description = "Increases ball capture radius.", effect = function()
        rewards.player.increaseCaptureRadius(5) -- Increase capture radius by 5
        print("Reward: Capture Radius Increased to " .. rewards.player.getCaptureRadius())
    end }
}

function rewards.applyReward(rewardName)
    for _, reward in ipairs(rewards.list) do
        if reward.name == rewardName then
            reward.effect()
            return
        end
    end
    print("Error: Reward not found -", rewardName)
end

function rewards.getRandomRewards()
    local availableRewards = {}

    -- Copy rewards list to avoid modifying the original
    for _, reward in ipairs(rewards.list) do
        table.insert(availableRewards, reward)
    end

    -- Shuffle rewards using run.seed for deterministic randomness
    math.randomseed(rewards.run.seed)

    for i = #availableRewards, 2, -1 do
        local j = math.random(i)
        availableRewards[i], availableRewards[j] = availableRewards[j], availableRewards[i]
    end

    -- Return the first 3 rewards
    return { availableRewards[1], availableRewards[2], availableRewards[3] }
end


return rewards
