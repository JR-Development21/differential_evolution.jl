################# Function to run a single generation ###################

function runGeneration(iter, agents, C, F, mF, mC, nAgents, agentLength, testfunc, fCurrent, maxIter, nMin, nMax; H = nothing, doArchive = false, archive = nothing, nArchive = nothing, method = "rand/1", variant = "classic", bounds = nothing, boundType = nothing, best = nothing, p = nothing)
    F = changeF(F = F, method = variant, H = H, popSize = nAgents, mF = mF)
    C = changeF(F = C, method = variant, H = H, popSize = nAgents, mC = mC)
    sF = Array{Float64}(undef, 0)
    sC = Array{Float64}(undef, 0)
    fDel = Array{Float64}(undef, 0)
    mut = Array{Float64}(undef, nAgents)
    fDelMut = Array{Float64}(undef, nAgents)
    fMut = Array{Float64}(undef, nAgents)
    for i in 1:nAgents
        mut, fDelMut, fMut = mutateAgent(iter = i, nAgents=nAgents, agents=agents, agentLength = agentLength, testfunc = testfunc, fVal = F, Cval = C, method = method, doArchive=doArchive, archive = archive, nArch=nArchive, best = best, boundType=boundType, bounds = bounds)
    end
    for i in 1:nAgents
        updateParams(mut = mut, fDelMut = fDelMut, fMut = fMut, iter = i, nAgents=nAgents, agents=agents, agentLength = agentLength, testfunc = testfunc, fVal = F, Cval = C, method = method, doArchive=doArchive, archive = archive, nArch=nArchive, best = best, boundType=boundType, bounds = bounds)
    end
    mC = updateMemC(method = variant, fDel = fDel, mC = mC, sC = sC, k = k)
    mF = updateMemC(method = variant, fDel = fDel, mF = mF, sF = sF, k = k)
    updateK(k, H)
    keepAgents = cullHerd(method = variant, nAgents = nAgents, nMin=nMin, nMax=nMax, maxIter = maxIter, iter = iter, fCurrent = fCurrent)
    agents = agents[keepAgents]
    nAgents = length(keepAgents)
    fCurrent = fCurrent[keepAgents]
    best = updateBest(method = method, variant = variant, p = p, nAgents = nothing, fCurrent = fCurrent)
end
