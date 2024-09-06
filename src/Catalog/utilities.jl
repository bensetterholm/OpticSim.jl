# MIT license
# Copyright (c) Microsoft Corporation. All rights reserved.
# See LICENSE in the project root for full license information.

const TEMP_REF_UNITFUL = TEMP_REF * u"°C"

"""
    absorption(glass::AbstractGlass, wavelength; temperature=20°C, pressure=1Atm)

Compute the intensity absorption per mm of `glass` at `wavelength`, optionally at specified `temperature` and `pressure`.
Transmission values are linearly interpolated from the adjacent values in the data table of `glass`, if `wavelength` is below the minimum or above the maximum in the table then the nearest value is taken.

Absorption is defined as ``\\frac{-\\log(t)}{\\tau}`` where ``t`` is the transmission value and ``\\tau`` is the thickness, both of which are provided in the data table.

If unitless, arguments are interpreted as μm, °C and Atm respectively.

# Examples
```julia-repl
julia> absorption(GlassCat.SUMITA.LAK7, 700u"nm")
0.0006018072325563021

julia> absorption(GlassCat.SCHOTT.N_BK7, 0.55, temperature = 22.0)
0.00016504471175660636

julia> absorption(GlassCat.SCHOTT.PSK3, 532u"nm", temperature = 25u"°C", pressure = 1.3)
0.00020855284788532435
```
"""
function absorption(glass, wavelength::Length; temperature::Temperature = TEMP_REF_UNITFUL, pressure::Float64 = PRESSURE_REF)::Float64
    λ = Float64(ustrip(u"μm", wavelength))
    return absorption(glass, λ; temperature = ustrip(Float64, u"°C", temperature), pressure)
end

function absorption(glass::Glass, λ::T; temperature::T = T(TEMP_REF), pressure::T = T(PRESSURE_REF))::T where {T<:Real}
    return absorption(glass.glass, λ; temperature, pressure)
end

function absorption(::AirType, ::Length; temperature::Temperature = TEMP_REF_UNITFUL, pressure::Float64 = PRESSURE_REF)::Float64
    return 0.0
end

function absorption(::AirType, ::T; temperature::T = T(TEMP_REF), pressure::T = T(PRESSURE_REF))::T where {T<:Real}
    return zero(T)
end

"""
    index(glass::AbstractGlass, wavelength; temperature=20°C, pressure=1Atm)

Compute the refractive index of `glass` at `wavelength`, optionally at specified `temperature` and `pressure`.
Result is relative to the refractive index of air at given temperature and pressure.

If unitless, arguments are interpreted as μm, °C and Atm respectively.

**This is defined to always equal 1.0 for Air at any temperature and pressure**, use [`absairindex`](@ref) for the absolute refractive index of air at a given temperature and pressure.

# Examples
```julia-repl
julia> index(GlassCat.SUMITA.LAK7, 700u"nm")
1.646494204478318

julia> index(GlassCat.SCHOTT.N_BK7, 0.55, temperature = 22.0)
1.51852824383283

julia> index(GlassCat.HOYA.FF1, 532u"nm", temperature = 25u"°C", pressure = 1.3)
1.5144848290944655
```
"""
function index(glass, wavelength::Length; temperature::Temperature = TEMP_REF_UNITFUL, pressure::Float64 = PRESSURE_REF)::Float64
    λ = Float64(ustrip(uconvert(u"μm", wavelength)))
    return index(glass, λ; temperature = ustrip(Float64, u"°C", temperature), pressure)
end

function index(glass::Glass, λ::T; temperature::T = T(TEMP_REF), pressure::T = T(PRESSURE_REF))::T where {T<:Real}
    return index(glass.glass, λ; temperature, pressure)
end

function index(::AirType, ::Length; temperature::Temperature = TEMP_REF_UNITFUL, pressure::Float64 = PRESSURE_REF)::Float64
    return 1.0
end

function index(::AirType, ::T; temperature::T = T(TEMP_REF), pressure::T = T(PRESSURE_REF))::T where {T<:Real}
    return one(T)
end

"""
    absairindex(wavelength; temperature=20°C, pressure=1Atm)

Compute the absolute refractive index of air at `wavelength`, optionally at specified `temperature` and `pressure`. If unitless, arguments are interpreted as μm, °C and Atm respectively.

# Examples
```julia-repl
julia> absairindex(700u"nm")
1.000271074905147

julia> absairindex(0.7, temperature=27.0)
1.000264738846504

julia> absairindex(532u"nm", temperature = 25u"°C", pressure = 1.3)
1.0003494991178161
```
"""
function absairindex(wavelength::Length; temperature::Temperature = TEMP_REF_UNITFUL, pressure::Float64 = PRESSURE_REF)::Float64
    # convert to required units
    λ = Float64(ustrip(uconvert(u"μm", wavelength)))
    return absairindex(λ; temperature = ustrip(Float64, u"°C", temperature), pressure)
end

# """
#     polyfit_indices(wavelengths, n_rel; degree=5)

# Fit a polynomial to `indices` at `wavelengths`, optionally specifying the `degree` of the polynomial.
# Returns tuple of array of fitted indices at wavelengths and the polynomial.
# """
# function polyfit_indices(wavelengths::Union{AbstractRange{<:Length},AbstractArray{<:Length,1}}, indices::AbstractArray{<:Number,1}; degree::Int = 5)
#     w = ustrip.(uconvert.(u"μm", wavelengths))
#     okay = (indices .> 0.0)
#     if !any(okay)
#         return (ones(Float64, size(w)) .* NaN, nothing)
#     end
#     xs = range(-1.0, stop = 1.0, length = length(w[okay]))
#     poly = fit(xs, indices[okay], degree)
#     interp_indices = poly.(xs)
#     # ensure output has all entries
#     out = ones(Float64, size(w)) .* NaN
#     out[okay] = interp_indices
#     return (out, poly)
# end

# """
#     plot_indices(glass::AbstractGlass; polyfit=false, fiterror=false, degree=5, temperature=20°C, pressure=1Atm, nsamples=300, sampling_domain="wavelength")

# Plot the refractive index for `glass` for `nsamples` within its valid range of wavelengths, optionally at `temperature` and `pressure`.
# `polyfit` will show a polynomial of optionally specified `degree` fitted to the data, `fiterror` will also show the fitting error of the result.
# `sampling_domain` specifies whether the samples will be spaced uniformly in "wavelength" or "wavenumber".
# """
# function plot_indices(glass::AbstractGlass; polyfit::Bool = false, fiterror::Bool = false, degree::Int = 5, temperature::Temperature = TEMP_REF_UNITFUL, pressure::Float64 = PRESSURE_REF, nsamples::Int = 300, sampling_domain::String = "wavelength")
#     if isair(glass)
#         wavemin = 380 * u"nm"
#         wavemax = 740 * u"nm"
#     else
#         wavemin = glass.λmin * u"μm"
#         wavemax = glass.λmax * u"μm"
#     end

#     if (sampling_domain == "wavelength")
#         waves = range(wavemin, stop = wavemax, length = nsamples)      # wavelength in um
#     elseif (sampling_domain == "wavenumber")
#         sigma_min = 1.0 / wavemax
#         sigma_max = 1.0 / wavemin
#         wavenumbers = range(sigma_min, stop = sigma_max, length = nsamples) # wavenumber in um.^-1
#         waves = 1.0 ./ wavenumbers
#     else
#         error("Invalid sampling domain, should be \"wavelength\" or \"wavenumber\"")
#     end

#     p = plot(xlabel = "wavelength (um)", ylabel = "refractive index")

#     f = w -> begin
#         try
#             return index(glass, w, temperature = temperature, pressure = pressure)
#         catch
#             return NaN
#         end
#     end
#     indices = [f(w) for w in waves]
#     plot!(ustrip.(waves), indices, color = :blue, label = "From Data")

#     if polyfit
#         (p_indices, _) = polyfit_indices(waves, indices, degree = degree)
#         plot!(ustrip.(waves), p_indices, color = :black, markersize = 4, label = "Polyfit")
#     end

#     if polyfit && fiterror
#         err = p_indices - indices
#         p2 = plot(xlabel = "wavelength (um)", ylabel = "fit error")
#         plot!(ustrip.(waves), err, color = :red, label = "Fit Error")
#         p = plot(p, p2, layout = 2)
#     end

#     plot!(title = "$(glassname(glass)) dispersion")

#     gui(p)
# end


# """
#     drawglassmap(glasscatalog::Module; λ::Length = 550nm, glassfontsize::Integer = 3, showprefixglasses::Bool = false)

# Draw a scatter plot of index vs dispersion (the derivative of index with respect to wavelength). Both index and
# dispersion are computed at wavelength λ.

# Choose glasses to graph using the glassfilterprediate argument. This is a function that receives a Glass object and returns true if the glass should be graphed.

# If showprefixglasses is true then glasses with names like `F_BAK7` will be displayed. Otherwise glasses that have a
# leading letter prefix followed by an underscore, such as `F_`, will not be displayed.

# The index formulas for some glasses may give incorrect results if λ is outside the valid range for that glass. This can
# give anomalous results, such as indices less than zero or greater than 6. To filter out these glasses set maximumindex
# to a reasonable value such as 3.0.

# example: plot only glasses that do not contain the strings "E_" and "J_"

# drawglassmap(NIKON,showprefixglasses = true,glassfilterpredicate = (x) -> !occursin("J_",string(x)) && !occursin("E_",string(x)))
# """
# function drawglassmap(glasscatalog::Module; λ::Length = 550nm, glassfontsize::Integer = 3, showprefixglasses::Bool = false, minindex = 1.0, maxindex = 3.0, mindispersion = -.3, maxdispersion = 0.0, glassfilterpredicate = (x)->true)
#     wavelength = Float64(ustrip(uconvert(μm, λ)))
#     indices = Vector{Float64}(undef,0)
#     dispersions = Vector{Float64}(undef,0)
#     glassnames = Vector{String}(undef,0)

#     for name in names(glasscatalog)
#         glass = eval(:($glasscatalog.$name))
#         glassstring = String(name)
#         hasprefix = occursin("_", glassstring)
 
#         if typeof(glass) !== Module && (minindex <= index(glass, wavelength) <= maxindex)
#             f(x) = index(glass,x)
#             g = x -> ForwardDiff.derivative(f, x);
#             dispersion = g(wavelength)

#             # don't show glasses that have an _ in the name. This prevents cluttering the map with many glasses of
#             # similar (index, dispersion).
#             if glassfilterpredicate(glass) && (mindispersion <= dispersion <= maxdispersion) && (showprefixglasses || !hasprefix)
#                 push!(indices, index(glass, wavelength))
#                 push!(dispersions, dispersion)
#                 push!(glassnames, String(name))
#             end
#         end
#     end

#     font = Plots.font(family = "Sans", pointsize = glassfontsize, color = RGB(0.0,0.0,.4))
#     series_annotations = Plots.series_annotations(glassnames, font)
#     scatter(
#         dispersions,
#         indices;
#         series_annotations,
#         markeralpha = 0.0,
#         legends = :none,
#         xaxis = "dispersion @$λ",
#         yaxis = "index",
#         title = "Glass Catalog: $glasscatalog",
#         xflip = true) #should use markershape = :none to prevent markers from being drawn but this option doesn't work. Used markeralpha = 0 so the markers are invisible. A hack which works.
# end
