local M = {}

function M.isReserveRank(rankVal)
    return tostring(rankVal) == "RESERVE"
end

function M.isNonZeroRank(rankVal)
    if rankVal == nil then
        return false
    end

    local rankStr = tostring(rankVal)
    if rankStr == "RESERVE" or rankStr == "0" or rankStr == "0.0" then
        return false
    end

    local rankNum = tonumber(rankStr)
    return rankNum == nil or rankNum ~= 0
end

function M.buildEcoPtsDiffList(info)
    local result = {}
    if info == nil or info.rankLowerLimitPtsList == nil then
        return result
    end

    local rankList = info.rankLowerLimitPtsList
    local currentIdx = nil
    for i = 1, #rankList do
        if rankList[i].rank == info.currentLv then
            currentIdx = i
            break
        end
    end

    -- skip the last entry (lowest rank / level 0)
    for i = 1, #rankList - 1 do
        table.insert(result, {
            rank = rankList[i].rank,
            diff = rankList[i].pts - info.ecoPts,
            enabled = (currentIdx ~= nil and i < currentIdx)
        })
    end

    return result
end

function M.getVisibleRanks(ranks)
    local visible = {}
    if ranks == nil then
        return visible
    end

    for i = 1, #ranks do
        if not M.isReserveRank(ranks[i].rank) then
            table.insert(visible, ranks[i])
        end
    end
    return visible
end

return M
