include("../dg_utils/data_structures.jl")
include("../dg_utils/mesh.jl")
include("advection_diffusion_utils.jl")

using Plots, DifferentialEquations, JLD2, Printf

# Mesh Stuff
K = 16     # Number of elements
n = 8      # Polynomial Order
xmin = 0.0 # left endpoint of domain
xmax = 2π  # right endpoint of domain
𝒢 = Mesh(K, n, xmin, xmax) # Generate Mesh
∇ = Gradient(𝒢)

# Define Initial Condition
u = @. exp(-2 * (xmax-xmin) / 3 * (𝒢.x - (xmax-xmin)/2)^2)

# Define hyperbolic flux
α = 0.0 # Rusanov prameter
flux_type = RusanovBC(α)
field_bc = Dirichlet2(0.0,0.0)
field_data = copy(u)
flux_field = Field(field_data, field_bc)
state = copy(u)
Φ = Flux(flux_type, flux_field, state, calculate_hyperbolic_flux)

# Define Diffusive flux
α = 0.0 # Rusanov parameter
flux_type = Rusanov(α)
field_bc = FreeFlux()
field_data = copy(u)
flux_field = Field(field_data, field_bc)
state = copy(u)
∇Φ = Flux(flux_type, flux_field, state, calculate_parabolic_flux)

# Define Advective flux
α = -1.0 # Rusanov parameter (negative)
flux_type = RusanovBC(α)
field_bc = Dirichlet(0.0,0.0)
field_data = copy(u)
flux_field = Field(field_data, field_bc)
state = copy(u)
𝒜Φ = Flux(flux_type, flux_field, state, calculate_advective_flux)

# Define Diffusion parameters
dt = cfl_advection_diffusion(𝒢, c) # CFL timestep
dt = 0.0001
tspan  = (0.0, 2.0)
params = (∇, Φ, ∇Φ, 𝒜Φ)
rhs! = advection_diffusion!

# Define ODE problem
prob = ODEProblem(rhs!, u, tspan, params);
# Solve it
sol  = solve(prob, Tsit5(), dt=dt, adaptive = false);

# Plot it
theme(:juno)
nt = length(sol.t)
num = 20 # Number of Frames
step = floor(Int, nt/num)
num = floor(Int, nt/step)
indices = step * collect(1:num)
pushfirst!(indices, 1)
push!(indices, nt)
for i in indices
    plt = plot(𝒢.x, sol.u[i], xlims=(xmin, xmax), ylims = (-0.1,1.1), marker = 3,    leg = false)
    plot!(𝒢.x, sol.u[1], xlims = (xmin, xmax), ylims = (-0.1,1.1), color = "red", leg = false, grid = true, gridstyle = :dash, gridalpha = 0.25, framestyle = :box)
    display(plt)
    # sleep(0.25)
end
