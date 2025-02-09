local star = {}
local stars = {}
local initialPositions = {}

function star.init(playerModule)
    star.player = playerModule
    stars = {}
    initialPositions = {}
end

function star.setPositions(positions)
    stars = positions
    initialPositions = {} -- Reset initial positions
    for _, s in ipairs(positions) do
        table.insert(initialPositions, { x = s.x, y = s.y })
    end
end

function star.resetToInitialPositions()
    stars = {} -- Clear current stars
    for _, pos in ipairs(initialPositions) do
        table.insert(stars, { x = pos.x, y = pos.y })
    end
end

function star.update(dt)
    if not star.player or not star.player.getCaptureRadius then
        print("Error: Player reference is nil or getCaptureRadius() is missing!")
        return
    end

    local px, py = star.player.body:getX(), star.player.body:getY()
    local captureRadius = star.player.getCaptureRadius()

    if not captureRadius then
        print(star.player:getCaptureRadius())
        print("Warning: getCaptureRadius() returned nil. Defaulting to 30.")
        captureRadius = 30 -- Set a fallback value to prevent crash
    end

    for i = #stars, 1, -1 do
        local s = stars[i]
        local distance = math.sqrt((px - s.x)^2 + (py - s.y)^2)

        -- **Capture stars inside the capture radius**
        if distance < captureRadius then
            table.remove(stars, i)
            love.audio.play(love.audio.newSource("Assets/Sound/Tink1.mp3", "static"))
            print("Star captured by player!")
        end
    end
end



function star.draw()
    for _, s in ipairs(stars) do
        -- Draw glow effect
        love.graphics.setColor(0, 0, 1, 0.2)
        for radius = 30, 10, -5 do
            love.graphics.circle("fill", s.x, s.y, radius)
        end

        -- Draw the star
        love.graphics.setColor(0, 0, 1)
        love.graphics.circle("fill", s.x, s.y, 10)
    end
end

function star.allCollected()
    return #stars == 0
end

return star
