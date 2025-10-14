local function dijkstra(graph, startNode, endNode)
    local dist      = {}
    local prev      = {}
    local unvisited = {}

    for node, _ in pairs(graph) do
    dist[node]      = math.huge
    prev[node]      = nil
    unvisited[node] = true
    end

    dist[startNode] = 0

    while next(unvisited) do
        local currentNode   = nil
        local smallestDist  = math.huge

        for node in pairs(unvisited) do
            if dist[node] < smallestDist then
                currentNode     = node
                smallestDist    = dist[node]
            end
        end

        if not currentNode then
            break -- reachable nodes processed
        end

        if currentNode == endNode then
            break -- reached destination
        end

        unvisited[currentNode] = nil -- mark visited

        -- update distances for neighbors
        for neighbor, cost in pairs(graph[currentNode] or {}) do
            if unvisited[neighbor] then
                local alt = dist[currentNode] + cost
                if alt < dist[neighbor] then
                    dist[neighbor] = alt
                    prev[neighbor] = currentNode
                end
            end
        end 
    end

    -- path from start to end nodes
    local path = {}
    local u = endNode
    while u do
        table.insert(path, 1, u)
        u = prev[u]
    end

    if path[1] == startNode then
        return path 
    else
        return nil
    end
end

return {
    dijkstra = dijkstra
}