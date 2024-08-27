function D_optim(x)
    -det(x' * x)
end

function D_optim2(x)
    x = hcat(x, x[:,1] .* x[:,2],x[:,3] .* x[:,2],x[:,1] .* x[:,3],x[:,1] .* x[:,2] .* x[:,3])
    return D_optim(x)
end

function addIntOrder(matrix, vars, powers)
    size_mat = size(matrix)
    K = size_mat[2]
    N = size_mat[1]
    matrix = hcat(matrix, [0 for x in 1:N])
    for i in eachindex(vars)
        matrix[:, K + 1] = matrix[:, K + 1] .+ matrix[:, vars[i]].^powers[i]
    end
    return(matrix)
end


function createMM(matrix, vars, powers)
    for i in eachindex(vars)
        matrix = addIntOrder(matrix, vars[i], powers[i])
    end
    return(matrix)
end
