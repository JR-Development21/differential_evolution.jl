############## Function to mutate a given agent ##############

function mutateAgent(;iter, nAgents, agents, agentLength, fVal, cVal, testFunc, fCurrent, method = "rand/1", variant = "classic", doArchive = false, archive = nothing, nArch = nothing, best = nothing, boundType = nothing, bounds = nothing)
    popInd = sampPop(;iter=iter, nAgents = nAgents, method = method, variant = variant, doArchive=doArchive, nArch = nArch, best = best)
    lenPop = length(popInd)
    if doArchive
        K,n = size(agents)[[1,2]]
        pop = Array{Float64}(undef, (K, n ,nArch))
        for i in 1:lenPop
            if popInd[i] > nAgents
                pop[:,:,i] = archive[:,:,popInd[i] - nAgents]
            else
                pop[:,:,i] = agents[:,:,popInd[i]]
            end
        end
    else
        pop = agents[:,:,popInd]
    end
    begInd = 2:2:lenPop
    endInd = 3:2:lenPop
    numbComb = length(begInd)
    if length(fVal) > 1
        fVec = [fVal[iter] for x in 1:numbComb]
        cVec = cVal[iter]
    else
        fVec = [fVal for x in 1:numbComb]
        cVec = cVal
    end
    iterChange = rand(1:agentLength)
    iterProb = rand(Uniform(), agentLength)
    iterProb[iterChange] = 0
    mutVec = deepcopy(pop[:,:,1])
    for i in 1:numbComb
        for j in 1:agentLength
            if iterProb[j] <= cVec
                mutVec[j] += fVec[i] * (pop[:,:,begInd[i]][j] - pop[:,:,endInd[i]][j])
            end
        end
    end

    if boundType == "absorbingWall"
        for j in 1:agentLength
            if mutVec[j] < bounds[j][1]
                mutVec[j] = bounds[j][1]
            elseif mutVec[j] > bounds[j][2]
                mutVec[j] = bounds[j][2]
            end
        end
    elseif boundType == "L-SHADE"
        for j in 1:agentLength
            if mutVec[j] < bounds[j][1]
                mutVec[j] = (bounds[j][1] + pop[:,:,1][j]) / 2
            elseif mutVec[j] > bounds[j][2]
                mutVec[j] = (bounds[j][2] + pop[:,:,1][j]) / 2
            end
        end
    end
    fMut = testFunc(mutVec)
    fDelMut = fMut - fCurrent
    return mutVec, fDelMut, fMut
end

function updateParams(;agents, fCurrent, mut, fMut, fDelMut, sC, sF, fDel, cVal, fVal, nAgents, doArchive = false, archive = nothing, nArch = nothing, method = "rand/1")
    for i in 1:nAgents
        if fDelMut[i] < 0
            if occursin("current_to_pbest", method)
                sC = vcat(sC, cVal[i])
                sF = vcat(sF, fVal[i])
                fDel = vcat(fDel, abs(fDelMut[i]))
                if doArchive
                    archive = cat(dims = [3], archive, agents[:,:,i])
                    nArch += 1
                    if nArch > nAgents
                        randInds = sample(1:nArch, nAgents, replace = false)
                        archive = archive[:,:,randInds]
                        nArch = deepcopy(nAgents)
                    end
                end
            end
            agents[:,:,i] = mut[:,:,i]
            fCurrent[i] = fMut[i]
        end
    end
    return sC, sF, fDel, archive, nArch, agents, fCurrent
end
