using Distributions

cd("C:/Users/ritch/Documents/DOE Papers/differential_evolution.jl/")

functions = readdir("Jfunctions/")
functions = functions[findall(occursin.(".jl", functions))]
nf = length(functions)
for i in 1:nf
    ftemp = string("Jfunctions\\", functions[i])
    include(ftemp)
end
