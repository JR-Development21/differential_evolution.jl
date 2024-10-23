####################### Functions to update current values of C and F #########################

function changeC(;C=nothing, method = "classic", H=nothing, popSize = nothing, mC = nothing, terminalValue = nothing)
    if method == "classic"
        return C
    end
    if (method == "L-SHADE") || (method == "SHADE")
        r_i = rand(1:H, popSize)
        cVals = Array{Float64}(undef, popSize)
        for i in 1:popSize
            if (mC[r_i[i]] == terminalValue)
                cVals[i] = 0
            else
                cVals[i] = rand(Normal(mC[r_i[i]], .1), 1)[1]
                if cVals[i] > 1
                    cVals[i] = 1
                end
                if cVals[i] < 0
                    cVals[i] = 0
                end
            end
        end
        return cVals
    end
    throw("Please input a valid method")
end

function changeF(;F=nothing, method = "classic", H=nothing, popSize = nothing, mF = nothing)
    if method == "classic"
        return F
    end
    if (method == "L-SHADE") || (method == "SHADE")
        r_i = rand(1:H, popSize)
        fVals = Array{Float64}(undef, popSize)
        for i in 1:popSize
            fVals[i] = rand(truncated(Cauchy(mF[r_i[i]], .1), lower = 0), 1)[1]
            if fVals[i] > 1
                fVals[i] = 1
            end
        end
        return fVals
    end
    throw("Please input a valid method")
end

####################### Functions to update historic values of C and F #########################

function updateMemC(;method = "classic", fDel = nothing, mC = nothing, sC = nothing, k = nothing, terminalValue = nothing)
    if method == "classic"
        return 0
    end
    if (method == "SHADE")
        if length(sC) == 0
            mC_new = mC[k]
        else
            w = fDel ./ sum(fDel)
            mC_new = sum(sC .* w)
        end
        return(mC_new)
    end
    if (method == "L-SHADE")
        if length(sC) == 0
            mC_new = mC[k]
        else
            if (abs(maximum(sC)) < sqrt(eps(Float64))) || (mC[k] == terminalValue)
                mC_new = terminalValue
            else
                w = fDel ./ sum(fDel)
                mC_new = sum(sC.^2 .* w) / sum(sC .* w)
            end
        end
        return(mC_new)
    end
    throw("Please input a valid method")
end

function updateMemF(;method = "classic", fDel = nothing, mF = nothing, sF = nothing, k = nothing)
    if method == "classic"
        return 0
    end
    if (method == "L-SHADE") || (method == "SHADE")
        if length(sF) == 0
            mF_new = mF[k]
        else
            w = fDel ./ sum(fDel)
            mF_new = sum(sF.^2 .* w) / sum(sF .* w)
        end
        return(mF_new)
    end
    throw("Please input a valid method")
end

function updateK(k, kMax)
    if k == kMax
        k = 1
    else
        k += 1
    end
    return k
end
