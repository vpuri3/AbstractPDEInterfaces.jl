#
# add dependencies to env stack
pkgpath = dirname(dirname(@__FILE__))
tstpath = joinpath(pkgpath, "test")
!(tstpath in LOAD_PATH) && push!(LOAD_PATH, tstpath)

using PDEInterfaces
using OrdinaryDiffEq, LinearSolve, Sundials
using Plots

N = 4096
ν = 1e-3
p = ()

function uIC(x, ftr, k)
    u0 = @. sin(2x) + sin(3x) + sin(5x)
#   u0 = @. sin(x - π)

    Random.seed!(0)
    u0 = begin
        u  = rand(size(x)...)
        uh = ftr * u
        uh[20:end] .= 0
        ftr \ uh
    end

    u0
end
    
function solve_burgers(N, ν, p;
                       uIC=uIC,
                       tspan=(0.0, 10.0),
                       nsave=100,
                      )

    """ space discr """
    space = FourierSpace(N)
    discr = Collocation()
    
    (x,) = points(space)
    ftr  = transforms(space)
    k = modes(space)

    """ IC """
    u0 = uIC(x, ftr, k)

    """ operators """
    A = diffusionOp(ν, space, discr)

    # nonlinear convection
    burgers!(v, u, p, t) = copy!(v, u)

    v = @. x*0 + 1
    f = @. x*0
    C = advectionOp((v,), space, discr; vel_update_funcs=(burgers!,))
    F = AffineOperator(-C, f)

    A = cache_operator(A, x)
    F = cache_operator(F, x)
    
    """ time discr """
    odealg = CVODE_BDF(method=:Functional)
    tsave = range(tspan...; length=nsave)
    prob = SplitODEProblem(A, F, u0, tspan, p)
    @time sol = solve(prob, odealg, saveat=tsave)

    sol, space
end

function plot_sol(sol::ODESolution, space::FourierSpace)
    x = points(space)[1]
    plt = plot()
    for i=1:length(sol)
        plot!(plt, x, sol.u[i], legend=false)
    end
    plt
end

function anim8(sol::ODESolution, space::FourierSpace)
    x = points(space)[1]
    ylims = begin
        u = sol.u[1]
        mi = minimum(u)
        ma = maximum(u)
        buf = (ma-mi)/3
        (mi-buf, ma+buf)
    end
    anim = @animate for i=1:length(sol)
        plt = plot(x, sol.u[i], legend=false, ylims=ylims)
    end
end

sol, space = solve_burgers(N, ν, p)
plt = plot_sol(sol, space)
anim = anim8(sol, space)
gif(anim, "a.gif", fps= 20)

#
nothing
