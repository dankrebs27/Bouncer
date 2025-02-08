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
    local px, py = star.player.body:getX(), star.player.body:getY()
    for i = #stars, 1, -1 do
        local s = stars[i]
        if math.sqrt((px - s.x)^2 + (py - s.y)^2) < 30 then -- Collision radius
            table.remove(stars, i)
            love.audio.play(love.audio.newSource("Assets/Sound/Tink1.mp3", "static"))
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
