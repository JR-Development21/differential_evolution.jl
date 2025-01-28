############### Function to run differential evolution ##################

function differentialEvolution(agents, C, F,  testFunc; mF = nothing, mC = nothing, nMin = 4, maxItersPSO = 500, convergeIters = 15, H = nothing, doArchive = false, archive = nothing, nArchive = nothing, pArchive = nothing, method = "rand/1", variant = "classic", bounds = nothing, boundType = nothing, p = nothing)
    terminalValue = -1
    nAgents = size(agents)[3]
    maxFuncEvals = maxItersPSO * nAgents
    nMax = deepcopy(nAgents)
    agentLength = length(agents[:,:,1])
    fCurrent = Array{Float64}(undef, nAgents)
    for i in 1:nAgents
        fCurrent[i] = testFunc(agents[:,:,i])
    end
    best = updateBest(method = method, variant = variant, p = p, nAgents = nAgents, fCurrent = fCurrent)
    k = 1
    fTrack = deepcopy(minimum(fCurrent))
    f_change = 1
    itersUsed = 0
    i = 0
    fEvals = 0
    PSOGenerations = 1
    converge = false
    while (fEvals < maxFuncEvals) & ~converge
        fEvals += nAgents
        F, C, mC, mF, k, agents, nAgents, fCurrent, best = runGeneration(;k = k, agents = agents, C = C, F = F, mF = mF, mC = mC, nAgents = nAgents, agentLength = agentLength, testFunc = testFunc, fCurrent = fCurrent, nMin = nMin, nMax = nMax, H = H, doArchive = doArchive, archive = archive, nArchive = nArchive, pArchive = pArchive, method = method, variant = variant, bounds = bounds, boundType = boundType, best = best, p = p, terminalValue = terminalValue, fEvals = fEvals, maxFuncEvals = maxFuncEvals)
        if floor(fEvals / nMax) >= PSOGenerations
            PSOGenerations += 1
            minF = deepcopy(minimum(fCurrent))
            if fTrack > minF
                #uncomment this
                # if (fTrack - minF) < sqrt(eps(Float64))
                #     converge = true
                # end
                fTrack = minF
                f_change = 1
            else
                f_change += 1
            end
        end
        if f_change >= convergeIters
            break
        end
        i+=1
        itersUsed = deepcopy(i)
    end
    bestInd = argmin(fCurrent)
    return agents[:,:,bestInd], fCurrent[bestInd], itersUsed, fEvals
end