-- Check if cell is walkable
function IsCellWalkable(x, y, z)
    local sq = getCell():getGridSquare(x, y, z)
    -- Basic check for non-nil cell, you can add more checks for obstacles or terrain as needed
    return sq ~= nil
end

--  Get neighbors for tile, ensuring boundaries
function GetNeighbors(x, y, z, mapWidth, mapHeight)
    local neighbors = {}
    if x > 1 then table.insert(neighbors, {x=x-1, y=y, z=z}) end
    if x < mapWidth then table.insert(neighbors, {x=x+1, y=y, z=z}) end
    if y > 1 then table.insert(neighbors, {x=x, y=y-1, z=z}) end
    if y < mapHeight then table.insert(neighbors, {x=x, y=y+1, z=z}) end
    return neighbors
end

-- Build graph for whole map (use smaller section for performance!)
function BuildGraphFromMap(mapWidth, mapHeight, mapZ)
    local graph = {}

    for x = 1, mapWidth do
        for y = 1, mapHeight do
            local nodeKey = string.format("%d,%d,%d", x, y, mapZ)
            if IsCellWalkable(x, y, mapZ) then
                graph[nodeKey] = {}
                local neighbors = GetNeighbors(x, y, mapZ, mapWidth, mapHeight)
                for _,n in ipairs(neighbors) do
                    if IsCellWalkable(n.x, n.y, n.z) then
                        local neighborKey = string.format("%d,%d,%d", n.x, n.y, n.z)
                        graph[nodeKey][neighborKey] = 1 -- uniform cost
                    end
                end
            end
        end
    end
    return graph
end
