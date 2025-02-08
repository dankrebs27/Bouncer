local trajectory = {}

function trajectory.init(config)
    trajectory.world = love.physics.newWorld(config.gravity[1], config.gravity[2], true)
    trajectory.points = {}

    -- Prepare the simulation body
    trajectory.simulationBody = love.physics.newBody(trajectory.world, 0, 0, "dynamic")
    trajectory.simulationShape = love.physics.newCircleShape(5)
    trajectory.simulationFixture = love.physics.newFixture(trajectory.simulationBody, trajectory.simulationShape)
    trajectory.simulationFixture:setSensor(true)
end

function trajectory.calculate(player, platforms)
    trajectory.points = {}

    -- Snapshot platform positions to avoid mid-simulation changes
    local staticPlatforms = {}
    for _, platform in ipairs(platforms) do
        table.insert(staticPlatforms, {
            x1 = platform.x1,
            y1 = platform.y1,
            x2 = platform.x2,
            y2 = platform.y2,
        })
    end

    -- Sync trajectory simulation properties with the player
    local x, y = player.body:getX(), player.body:getY()
    local vx, vy = player.getInitialVelocity()
    trajectory.simulationBody:setPosition(x, y)
    trajectory.simulationBody:setLinearVelocity(vx, vy)
    trajectory.simulationFixture:setRestitution(player.getBounciness())
    trajectory.simulationBody:setLinearDamping(player.body:getLinearDamping())
    trajectory.simulationBody:setAngularDamping(player.body:getAngularDamping())

    local dt = 0.01
    for _ = 1, 500 do
        trajectory.world:update(dt)
        local tx, ty = trajectory.simulationBody:getX(), trajectory.simulationBody:getY()
        local svx, svy = trajectory.simulationBody:getLinearVelocity()

        -- Stop if offscreen
        if ty > 600 or tx < 0 or tx > 800 then
            break
        end

        local nearestCollision = nil
        for _, platform in ipairs(staticPlatforms) do
            local hit, nx, ny, ix, iy, dist = trajectory.checkCollision(tx, ty, svx, svy, platform.x1, platform.y1, platform.x2, platform.y2)

            if hit and (not nearestCollision or dist < nearestCollision.dist) then
                nearestCollision = {nx = nx, ny = ny, ix = ix, iy = iy, dist = dist}
            end
        end

        if nearestCollision then
            local dot = svx * nearestCollision.nx + svy * nearestCollision.ny
            trajectory.simulationBody:setLinearVelocity(svx - 2 * dot * nearestCollision.nx, svy - 2 * dot * nearestCollision.ny)
            trajectory.simulationBody:setPosition(nearestCollision.ix, nearestCollision.iy)
        else
            table.insert(trajectory.points, tx)
            table.insert(trajectory.points, ty)
        end
    end
end

function trajectory.checkCollision(x, y, vx, vy, px1, py1, px2, py2)
    -- Line intersection test
    local denom = vx * (py2 - py1) - vy * (px2 - px1)
    if math.abs(denom) < 1e-6 then
        return false, 0, 0, 0, 0, math.huge -- Parallel lines
    end

    local ua = ((px2 - px1) * (y - py1) - (py2 - py1) * (x - px1)) / denom
    local ub = (vx * (y - py1) - vy * (x - px1)) / denom

    if ua >= 0 and ua <= 1 and ub >= 0 and ub <= 1 then
        -- Collision detected
        local ix = x + ua * vx
        local iy = y + ua * vy

        -- Compute platform normal
        local dx, dy = px2 - px1, py2 - py1
        local length = math.sqrt(dx * dx + dy * dy)
        local nx, ny = -dy / length, dx / length

        -- Distance to collision point
        local dist = math.sqrt((ix - x)^2 + (iy - y)^2)
        return true, nx, ny, ix, iy, dist
    end

    return false, 0, 0, 0, 0, math.huge
end

function trajectory.draw()
    if #trajectory.points >= 4 then
        love.graphics.setColor(0, 1, 0, 0.5)
        love.graphics.line(trajectory.points)
    end
end

return trajectory
