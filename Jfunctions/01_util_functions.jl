function D_optim(x)
    -det(x' * x)
end

function D_optim2(x)
    x = hcat(x, x[:,1] .* x[:,2],x[:,3] .* x[:,2],x[:,1] .* x[:,3],x[:,1] .* x[:,2] .* x[:,3])
    return D_optim(x)
end