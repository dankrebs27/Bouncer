local run = {}

function run.init(seed)
    if not seed then
        run.seed = os.time() -- Generate a random seed for the run
    else
        run.seed = seed -- Use provided seed for deterministic runs
    end
    print("Run initialized with seed:", run.seed)
    run.platformInventory = {
        base = 10,
        power = 5,
        ice = 3
    }
    run.boons = {} -- Placeholder for future boons
    run.curses = {} -- Placeholder for future curses
    run.currentRoom = 1 -- Track the current room (or level)
    run.boons = {} -- List of collected boons
end

function run.startNew()
    run.init() -- Initialize the run
    math.randomseed(run.seed) -- Seed the random number generator
end

function run.applyRoomOutcome(success)
    if not success then
        print("Run ended.")
        return false
    end
    run.currentRoom = run.currentRoom + 1
    print("Advancing to room:", run.currentRoom)
    return true
end

function run.getRunData()
    return {
        seed = run.seed,
        platformInventory = run.platformInventory,
        boons = run.boons,
        curses = run.curses,
        currentRoom = run.currentRoom
    }
end

function run.modifyPlatformInventory(amount)
    run.platformInventory = run.platformInventory + amount
    if run.platformInventory < 0 then run.platformInventory = 0 end
end

function run.addBoon(boonName)
    table.insert(run.boons, boonName)
    print("Boon acquired:", boonName)
end

function run.hasBoon(boonName)
    for _, boon in ipairs(run.boons) do
        if boon == boonName then
            return true
        end
    end
    return false
end

function run.resetBoons()
    run.boons = {} -- Clear all collected boons
end

return run
