############## Function to mutate a given agent ##############

function mutateAgent(iter, nAgents, agents, agentLength, fVal, cVal, testFunc, fCurrent; method = "rand/1", doArchive = false, archive = nothing, nArch = nothing, best = nothing, boundType = nothing, bounds = nothing)
    popInd = sampPop(iter=iter, nAgents = nAgents, method = method, doArchive=doArchive, nArch = nArch, best = best)
    lenPop = length(popInd)
    if doArchive
        pop = []
        for i in 1:lenPop
            if popInd[i] > nAgents
                pop = vcat(pop, archive[popInd[i] - nAgents])
            else
                pop = vcat(pop, agents[popInd[i]])
            end
        end
    else
        pop = agents[popInd]
    end
    begInd = 2:2:lenPop
    endInd = 3:2:lenPop
    numbComb = length(begInd)
    if length(fVal > 1)
        fVec = [fVal[iter] for x in 1:numbComb]
        cVec = cVal[iter]
    else
        fVec = [fVal for x in 1:numbComb]
        cVec = cVec
    end
    iterChange = rand(1:agentLength)
    iterProb = rand(Uniform(), agentLength)
    iterProb[iterChange] = 0
    mutVec = deepcopy(pop[1])
    for i in 1:numbComb
        for j in 1:agentLength
            if iterProb[j] <= cVec
                mutVec[j] += fVec[i] * (pop[begInd[i]][j] - pop[endInd[i]][j])
            end
        end
    end

    if boundType == "absorbingWall"
        for j in 1:agentLength
            if mutVec[j] < bounds[1][j]
                mutVec[j] = bounds[1][j]
            elseif mutvec[j] > bounds[2][j]
                mutVec[j] = bounds[2][j]
            end
        end
    elseif boundType == "L-SHADE"
        for j in 1:agentLength
            if mutVec[j] < bounds[1][j]
                mutVec[j] = (bounds[1][j] + pop[1][j]) / 2
            elseif mutvec[j] > bounds[2][j]
                mutVec[j] = (bounds[2][j] + pop[1][j]) / 2
            end
        end
    end
    fMut = testFunc(mut)
    fDelMut = fMut - fCurrent
    return mut, fDelMut, fMut
end

function updateParams(agents, mut, fMut, fDelMut, sC, sF, fDel, iter, c, f, nAgents; doArchive = false, archive = nothing, nArch = nothing, method = "rand/1")
    if fDelMut <= 0
        if occursin("current_to_pbest", method)
            sC = vcat(sC, c)
            sF = vcat(sF, f)
            fDel = vcat(fDel, abs(fDelMut))
            if doArchive
                archive = vcat(archive, agents[iter])
                nArch += 1
                if nArch > nAgents
                    archive = rand(archive, nAgents)
                    nArch = deepcopy(nAgents)
                end
            end
        end
        agents[iter] = mut
        fCurrent[iter] = fMut
    end
end
