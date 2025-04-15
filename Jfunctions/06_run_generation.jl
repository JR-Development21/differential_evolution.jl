################# Function to run a single generation ###################

function runGeneration(;k, agents, C, F, mF, mC, nAgents, agentLength, testFunc, fCurrent, nMin, nMax, H = nothing, doArchive = false, archive = nothing, nArchive = nothing, pArchive = nothing, method = "rand/1", variant = "classic", bounds = nothing, boundType = nothing, best = nothing, p = nothing, terminalValue = nothing, fEvals = nothing, maxFuncEvals = nothing)
    F = changeF(F = F, method = variant, H = H, popSize = nAgents, mF = mF)
    C = changeC(C = C, method = variant, H = H, popSize = nAgents, mC = mC, terminalValue = terminalValue)
    sF = Array{Float64}(undef, 0)
    sC = Array{Float64}(undef, 0)
    fDel = Array{Float64}(undef, 0)
    mut = deepcopy(agents)
    fDelMut = Array{Float64}(undef, nAgents)
    fMut = Array{Float64}(undef, nAgents)
    for i in 1:nAgents
        mut[:,:,i], fDelMut[i], fMut[i] = mutateAgent(;iter = i, nAgents=nAgents, agents=agents, agentLength = agentLength, testFunc = testFunc, fCurrent = fCurrent[i], fVal = F, cVal = C, method = method, variant = variant, doArchive=doArchive, archive = archive, nArch=nArchive, best = best, boundType=boundType, bounds = bounds)
    end
    sC, sF, fDel, archive, nArchive, agents, fCurrent = updateParams(;mut = mut, fCurrent = fCurrent, fDelMut = fDelMut, fMut = fMut, nAgents=nAgents, agents=agents, fVal = F, cVal = C, method = method, doArchive=doArchive, archive = archive, nArch=nArchive, pArchive = pArchive, sC = sC, sF = sF, fDel = fDel)
    if variant in ["L-SHADE", "SHADE", "My-SHADE"]
        mC[k] = updateMemC(method = variant, fDel = fDel, mC = mC, sC = sC, k = k, terminalValue = terminalValue)
        mF[k] = updateMemF(method = variant, fDel = fDel, mF = mF, sF = sF, k = k)
    end
    k = updateK(k, H)
    keepAgents = cullHerd(method = variant, nAgents = nAgents, nMin=nMin, nMax=nMax, maxFuncEvals = maxFuncEvals, fEvals = fEvals, fCurrent = fCurrent)
    agents = agents[:,:,keepAgents]
    nAgents = length(keepAgents)
    fCurrent = fCurrent[keepAgents]
    best = updateBest(method = method, variant = variant, p = p, nAgents = nAgents, fCurrent = fCurrent)
    return F, C, mC, mF, k, agents, nAgents, fCurrent, best
end
