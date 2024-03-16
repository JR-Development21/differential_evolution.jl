############### Function to run differential evolution ##################

function differentialEvolution(agents, C, F, mF, mC, testfunc; nMin = 5, maxIters = 500, H = nothing, doArchive = false, archive = nothing, nArchive = nothing, method = "rand/1", variant = "classic", bounds = nothing, boundType = nothing, p = nothing)
    nAgents = length(agents)
    nMax = deepcopy(nAgents)
    agentLength = length(agents[1])
    fCurrent = Array{Float64}(undef, nAgents)
    for i in 1:nAgents
        fCurrent[i] = testfunc(agents[i])
    end
    best = updateBest(method = method, variant = variant, p = p, nAgents = nothing, fCurrent = fCurrent)
    for i in 1:maxIters
        runGeneration(iter = i, agents = agents, C = C, F = F, mF = mF, mC = mC, nAgents = nAgents, agentLength = agentLength, testfunc = testfunc, fCurrent = fCurrent, maxIter = maxIters, nMin, nMax; H = H, doArchive = doArchive, archive = archive, nArchive = nArchive, method = method, variant = variant, bounds = bounds, boundType = boundType, best = best, p = p)
    end
end