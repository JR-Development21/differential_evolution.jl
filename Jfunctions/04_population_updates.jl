######################## Functions to update the population ###################

function sampPop(iter, nAgents; method = "rand/1", best=nothing, doArchive = false, nArch = nothing)
    split_str = split(method, "/")
    samp_method = split_str[1]
    samp_number = parse(Int, split_str[2])
    if samp_method == "rand"
        pop_ind = rand(setdiff(1:nAgents, iter), 1 + 2*samp_number)
    elseif samp_method == "current_to_pbest"
        pop_ind = iter
        pbest_indices = setdiff(best, iter)
        if length(pbest_indices) > 1
            pbest_ind = rand(pbest_indices, samp_number)
        else
            pbest_ind = pbest_indices
        end
        r1_ind = rand(setdiff(1:nAgents, iter), samp_number)
        if doArchive
            r2_ind = rand(setdiff(1:(nAgents + nArch), [iter, r1_ind]), samp_number)
        else
            r2_ind = rand(setdiff(1:nAgents, [iter, r1_ind]), samp_number)
        end
        pop_ind = vcat(pop_ind, pbest_ind, r1_ind, r2_ind)
    end
    return pop_ind
end

function updateBest(;method = "random", variant = nothing, p = nothing, nAgents = nothing, fCurrent = nothing)
    if occursin("rand", method)
        return nothing
    elseif occursin("current_to_pbest", method)
        order = sortperm(fCurrent)
        if variant == "SHADE"
            p = Array{Int}(undef, nAgents)
            pbest_ind = Array{Array{Int}}(undef, nAgents)
            for i in 1:nAgents
                p[i] = Int(round(rand(Uniform(2/nAgents, .2)) * nAgents))
                pbest_ind[i] = order[1:p[i]]
            end
        elseif variant == "L-SHADE"
            p_num = minimum([2, p * nAgents])
            p_num = Int(p_num)
            pbest_ind = Array{Float64}(undef, p_num)
            pbest_ind = order[1:p_num]
        end
        return pbest_ind
    end
end

function cullHerd(; method = nothing, nAgents = nothing, nMin = nothing, nMax = nothing, maxIter = nothing, iter = nothing, fCurrent = nothing)
    if ~(method in ["L-SHADE"])
        return 1:nAgents
    elseif method == ["L-SHADE"]
        nAgents = Int((nMin - nMax) / maxIter * iter + nMax)
        keepAgents = sortperm(fCurrent)[1:nAgents]
        return keepAgents
    end
end