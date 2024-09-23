cd("C:/Users/ritch/Documents/DOE Papers/differential_evolution.jl/")

using Distributed
length(Sys.cpu_info())    # Number of logical CPU cores available in the system
nprocs()      # Number of available processes.
nworkers()

#
addprocs(length(Sys.cpu_info()) - 1)
nprocs()
nworkers()

@everywhere using Distributions, LinearAlgebra, Combinatorics, Random, CSV, DataFrames, Distributed

@everywhere begin
    functions = readdir("Jfunctions/")
    functions = functions[findall(occursin.(".jl", functions))]
    nf = length(functions)
    for i in 1:nf
        ftemp = string("Jfunctions\\", functions[i])
        include(ftemp)
    end


    # Random.seed!(16)
    nRuns = 21
    nReps = 20

    ## set up  combinatoric runs by factor numAgents
    nVec = vcat(3:9, 6:12, 10:16)
    kVec = repeat(1:3, inner = 7)
    critVec = [D_optim, A_optim, G_optim, I_optim]
    totalRuns = nRuns * nReps
    DVec = Array{Float64}(undef, totalRuns, 6)
    AVec = Array{Float64}(undef, totalRuns, 6)
    GVec = Array{Float64}(undef, totalRuns, 6)
    IVec = Array{Float64}(undef, totalRuns, 6)

    DDesign = Array{Array{Float64}}(undef, totalRuns)
    ADesign = Array{Array{Float64}}(undef, totalRuns)
    GDesign = Array{Array{Float64}}(undef, totalRuns)
    IDesign = Array{Array{Float64}}(undef, totalRuns)


    function run_optimization(i, j, k)
        K = kVec[i]
        N = nVec[i]
        d = K * N
        bounds = easyBounds(K)
        nAgents = numAgents(d)
        agents = initializeAgents(nAgents, N, K, bounds)
        nArchive = Int(floor(numAgents(d) / 4))
        archive = initializeAgents(nArchive, N, K, bounds)
        bounds = [[-1, 1] for i in 1:d]
        C = [.8 for x in 1:nAgents]
        F = [.7 for x in 1:nAgents]
        H = d * 2
        mF = [.7 for x in 1:H]
        mC = [.8 for x in 1:H]

        out = differentialEvolution(deepcopy(agents), C, F, critVec[k], maxIters = 1000, convergeIters = 100, mF = mF, mC = mC, method = "current_to_pbest/1", variant = "L-SHADE", p = .05, H = H, doArchive = true, archive = archive, nArchive = nArchive, bounds = bounds, boundType = "absorbingWall")

        if k == 1
            critVal = DToBork(D_optim(out[1]), N, Int(2 * K + K * (K - 1) / 2 + 1))
            return (:D, j + nReps * (i - 1), [j, K, N, out[3], nAgents, critVal], out[1])
        elseif k == 2
            critVal = AToBork(A_optim(out[1]), N, Int(2 * K + K * (K - 1) / 2 + 1))
            return (:A, j + nReps * (i - 1), [j, K, N, out[3], nAgents, critVal], out[1])
        elseif k == 3
            critVal = GToBork(G_optim(out[1]), Int(2 * K + K * (K - 1) / 2 + 1))
            return (:G, j + nReps * (i - 1), [j, K, N, out[3], nAgents, critVal], out[1])
        else
            critVal = IToBork(I_optim(out[1]))
            return (:I, j + nReps * (i - 1), [j, K, N, out[3], nAgents, critVal], out[1])
        end
    end
end

## Use pmap to parallelize the optimization runs
results = pmap(x -> run_optimization(x[1], x[2], x[3]), [(i, j, k) for i in 1:nRuns for j in 1:nReps for k in 1:4])

## Store the results in the respective matrices
for res in results
    critType, index, vec, design = res
    if critType == :D
        DVec[index, :] = vec
        DDesign[index] = design
    elseif critType == :A
        AVec[index, :] = vec
        ADesign[index] = design
    elseif critType == :G
        GVec[index, :] = vec
        GDesign[index] = design
    else
        IVec[index, :] = vec
        IDesign[index] = design
    end
end


D_frame = DataFrame(hcat(DVec, DDesign), ["testRun","k","N","niter","Sv","fgbest","gbest"])
CSV.write("D_sim.csv", D_frame)

A_frame = DataFrame(hcat(AVec, ADesign), ["testRun","k","N","niter","Sv","fgbest","gbest"])
CSV.write("A_sim.csv", A_frame)

G_frame = DataFrame(hcat(GVec, GDesign), ["testRun","k","N","niter","Sv","fgbest","gbest"])
CSV.write("G_sim.csv", G_frame)

I_frame = DataFrame(hcat(IVec, IDesign), ["testRun","k","N","niter","Sv","fgbest","gbest"])
CSV.write("I_sim.csv", I_frame)
