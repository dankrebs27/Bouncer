local trajectory = {}

function trajectory.init(config)
    trajectory.world = love.physics.newWorld(config.gravity[1], config.gravity[2], true)
    trajectory.points = {}

    -- Create a simulation body for trajectory calculations
    trajectory.simulationBody = love.physics.newBody(trajectory.world, 0, 0, "dynamic")
    trajectory.simulationShape = love.physics.newCircleShape(30)
    trajectory.simulationFixture = love.physics.newFixture(trajectory.simulationBody, trajectory.simulationShape)
    trajectory.simulationFixture:setSensor(true) -- Does not interact with objects
end

function trajectory.calculate(player, platforms)
    trajectory.points = {}

    -- Capture platform positions for consistent simulation
    local staticPlatforms = {}
    for _, platform in ipairs(platforms) do
        table.insert(staticPlatforms, {
            x1 = platform.x1, y1 = platform.y1,
            x2 = platform.x2, y2 = platform.y2,
            restitution = platform.fixture:getRestitution()
        })
    end

    -- Sync physics simulation with player's actual position & velocity
    local ballRadius = player.shape:getRadius() -- Get the ball radius
    local x, y = player.body:getX(), player.body:getY() + ballRadius -- Move start position down
    local vx, vy = 0, 0 -- Assume starting velocity is zero before launch
    trajectory.simulationBody:setPosition(x, y)
    trajectory.simulationBody:setLinearVelocity(vx, vy)
    trajectory.simulationFixture:setRestitution(0)

    local dt = love.timer.getDelta()
    for _ = 1, 500 do
        local gravityX, gravityY = trajectory.world:getGravity()
        trajectory.world:update(dt)

        local tx, ty = trajectory.simulationBody:getX(), trajectory.simulationBody:getY()
        local svx, svy = trajectory.simulationBody:getLinearVelocity()

        -- **Apply gravity step manually**
        svy = svy + (gravityY * dt)

        trajectory.simulationBody:setLinearVelocity(svx, svy)

        -- Stop if offscreen
        if ty > 600 or tx < 0 or tx > 800 then
            break
        end

        local nearestCollision = nil
        for _, platform in ipairs(staticPlatforms) do
            local hit, nx, ny, ix, iy, dist = trajectory.checkCollision(tx, ty, svx, svy, platform)

            if hit and (not nearestCollision or dist < nearestCollision.dist) then
                nearestCollision = {nx = nx, ny = ny, ix = ix, iy = iy, dist = dist, restitution = platform.restitution}
            end
        end

        if nearestCollision then
            local dot = svx * nearestCollision.nx + svy * nearestCollision.ny
            local platformRestitution = nearestCollision.restitution
            local ballRestitution = trajectory.simulationFixture:getRestitution()
            
            -- **Combine the platform and ball bounciness for a realistic bounce**
            local totalRestitution = platformRestitution * 2.5 --* ballRestitution
            --print("restitution: ", totalRestitution)
        
            -- **Reflect velocity using physics-based bounce formula**
            local newVx = svx - (1 + totalRestitution) * dot * nearestCollision.nx
            local newVy = svy - (1 + totalRestitution) * dot * nearestCollision.ny
        
            trajectory.simulationBody:setLinearVelocity(newVx, newVy)
            trajectory.simulationBody:setPosition(nearestCollision.ix, nearestCollision.iy)
                
        else
            table.insert(trajectory.points, tx)
            table.insert(trajectory.points, ty)
        end
    end
end

function trajectory.checkCollision(x, y, vx, vy, platform)
    -- Line intersection test
    local denom = vx * (platform.y2 - platform.y1) - vy * (platform.x2 - platform.x1)
    if math.abs(denom) < 1e-6 then
        return false, 0, 0, 0, 0, math.huge -- Parallel lines
    end

    local ua = ((platform.x2 - platform.x1) * (y - platform.y1) - (platform.y2 - platform.y1) * (x - platform.x1)) / denom
    local ub = (vx * (y - platform.y1) - vy * (x - platform.x1)) / denom

    if ua >= 0 and ua <= 1 and ub >= 0 and ub <= 1 then
        local ix = x + ua * vx
        local iy = y + ua * vy

        -- Compute platform normal
        local dx, dy = platform.x2 - platform.x1, platform.y2 - platform.y1
        local length = math.sqrt(dx * dx + dy * dy)
        local nx, ny = -dy / length, dx / length

        local dist = math.sqrt((ix - x)^2 + (iy - y)^2)
        return true, nx, ny, ix, iy, dist, platform.restitution
    end

    return false, 0, 0, 0, 0, math.huge
end

function trajectory.draw()
    if #trajectory.points >= 4 then
        love.graphics.setColor(1, 1, 0, 0.8) -- Yellow trajectory
        love.graphics.setLineWidth(2)
        love.graphics.line(trajectory.points)
    end
end

return trajectory
