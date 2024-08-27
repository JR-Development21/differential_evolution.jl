############### Function to run differential evolution ##################

function differentialEvolution(agents, C, F,  testFunc; mF = nothing, mC = nothing, nMin = 5, maxIters = 500, H = nothing, doArchive = false, archive = nothing, nArchive = nothing, method = "rand/1", variant = "classic", bounds = nothing, boundType = nothing, p = nothing)
    nAgents = size(agents)[3]
    nMax = deepcopy(nAgents)
    agentLength = length(agents[:,:,1])
    fCurrent = Array{Float64}(undef, nAgents)
    for i in 1:nAgents
        fCurrent[i] = testFunc(agents[:,:,i])
    end
    best = updateBest(method = method, variant = variant, p = p, nAgents = nAgents, fCurrent = fCurrent)
    k = 1
    for i in 1:maxIters
        F, C, mC, mF, k, agents, nAgents, fCurrent, best = runGeneration(;iter = i, k = k, agents = agents, C = C, F = F, mF = mF, mC = mC, nAgents = nAgents, agentLength = agentLength, testFunc = testFunc, fCurrent = fCurrent, maxIter = maxIters, nMin = nMin, nMax = nMax, H = H, doArchive = doArchive, archive = archive, nArchive = nArchive, method = method, variant = variant, bounds = bounds, boundType = boundType, best = best, p = p)
    end
    bestInd = argmin(fCurrent)
    return agents[:,:,bestInd], fCurrent[bestInd]
end