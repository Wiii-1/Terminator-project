function BuildGraphFromMap(mapWidth, mapHeight, mapZ)
    local graph = {}

    for x = 1, mapWidth do
        for y = 1, mapHeight do
            local nodeKey = string.format("%d,%d,%d", x, y, mapZ)
            if IsCellWalkable(x, y, mapZ) then
                graph[nodeKey] = {}
                local neighbors = GetNeighbors(x, y, mapZ)
                
                for _,n in ipairs(neighbors) do
                    if IsCellWalkable(n.x, n.y, n.z) then
                        local neighborsKey = string.format("%d,%d,%d", n.x, n.y, n.z)
                        graph[nodeKey][neighborsKey] = 1 -- cost 1
                    end
                end
            end
        end
    end
    return graph
end