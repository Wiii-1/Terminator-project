local LastKnownLocation = {}
local UPDATE_INTERVAL = 2 -- seconds between allowed writes
local MOVE_THRESHOLD = 0.5 -- tiles

LastKnownLocation._lastUpdate = 0

local function now()
    return os.time()
end

local function storeLocation(player, x, y, z)
    if not player then return end
    local md = player:getModData()
    md.lastKnownLocation = { x = x, y = y, z = z, time = now() }
end

-- Public API
function LastKnownLocation.set(player, x, y, z)
    storeLocation(player, x, y, z)
end

function LastKnownLocation.get(player)
    if not player then return nil end
    local md = player:getModData()
    return md and md.lastKnownLocation or nil
end

-- Internal tick handler: updates periodically if player moved
Events.OnTick.Add(function()
    local player = getPlayer()
    if not player or not player:isAlive() then return end

    local cur = now()
    if cur - LastKnownLocation._lastUpdate < UPDATE_INTERVAL then return end

    local x, y, z = player:getX(), player:getY(), player:getZ()
    local md = player:getModData()
    local prev = md and md.lastKnownLocation

    local moved = true
    if prev then
        local dx = math.abs(prev.x - x)
        local dy = math.abs(prev.y - y)
        local dz = (prev.z ~= z) and 1 or 0
        moved = (dx > MOVE_THRESHOLD) or (dy > MOVE_THRESHOLD) or (dz ~= 0)
    end

    if moved then
        storeLocation(player, x, y, z)
        LastKnownLocation._lastUpdate = cur
    end
end)

return LastKnownLocation