# MIT license
# Copyright (c) Microsoft Corporation. All rights reserved.
# See LICENSE in the project root for full license information.

RelativeDispersion(glass::AGFGlass) = @match glass.NM.dispersion_formula begin
     1 => Schott(glass.CD[1:6]...)
     2 => Sellmeier1(glass.CD[1:6]...)
     3 => Herzberger(glass.CD[1:6]...)
     4 => Sellmeier2(glass.CD[1:5]...)
     5 => Conrady(glass.CD[1:3]...)
     6 => Sellmeier3(glass.CD[1:8]...)
     7 => HandbookOfOptics1(glass.CD[1:4]...)
     8 => HandbookOfOptics2(glass.CD[1:4]...)
     9 => Sellmeier4(glass.CD[1:5]...)
    10 => Extended(glass.CD[1:8]...)
    11 => Sellmeier5(glass.CD[1:10]...)
    12 => Extended2(glass.CD[1:8]...)
    13 => Extended3(glass.CD[1:9]...)
    _  => error("Glass has unknown dispersion formula")
end

(g::Schott)(λ) = sqrt(
    g.a0 + g.a1 * λ^2 + g.a2 * λ^-2 + g.a3 * λ^-4 + g.a4 * λ^-6 + g.a5 * λ^-8
)

function (g::Sellmeier1)(λ)
    λ² = λ^2
    return sqrt(
        1 + g.K1 * λ² / (λ² - g.L1) + g.K2 * λ² / (λ² - g.L2) + g.K3 * λ² / (λ² - g.L3)
    )
end

function (g::Sellmeier2)(λ)
    λ² = λ^2
    return sqrt(
        1 + g.A + g.B1 * λ² / (λ² - g.l1^2) + g.B2 * λ² / (λ² - g.l2^2)
    )
end

function (g::Sellmeier3)(λ)
    λ² = λ^2
    return (
        1,
        g.K1 * λ² / (λ² - g.L1),
        g.K2 * λ² / (λ² - g.L2),
        g.K3 * λ² / (λ² - g.L3),
        g.K4 * λ² / (λ² - g.L4),
    ) |> sum |> sqrt
end

function (g::Sellmeier4)(λ)
    λ² = λ^2
    return sqrt(g.A + g.B * λ² / (λ² - g.C) + g.D * λ² / (λ² - g.E))
end

function (g::Sellmeier5)(λ)
    λ² = λ^2
    return (
        1,
        g.K1 * λ² / (λ² - g.L1),
        g.K2 * λ² / (λ² - g.L2),
        g.K3 * λ² / (λ² - g.L3),
        g.K4 * λ² / (λ² - g.L4),
        g.K5 * λ² / (λ² - g.L5),
    ) |> sum |> sqrt
end

function (g::Herzberger)(λ)
    L = 1 / (λ^2 - 0.028)
    return g.A + g.B * L + g.C * L^2 + g.D * λ^2 + g.E * λ^4 + g.f * λ^6
end

(g::Conrady)(λ) = g.n0 + g.A / λ + g.B / λ^3.5

function (g::HandbookOfOptics1)(λ)
    λ² = λ^2
    return sqrt(g.A + g.B / (λ² - g.C) - g.D * λ²)
end

function (g::HandbookOfOptics2)(λ)
    λ² = λ^2
    return sqrt(g.A + g.B * λ² / (λ² - g.C) - g.D * λ²)
end

(g::Extended)(λ) = (
    g.a0,
    g.a1 * λ^2,
    g.a2 * λ^-2,
    g.a3 * λ^-4,
    g.a4 * λ^-6,
    g.a5 * λ^-8,
    g.a6 * λ^-10,
    g.a7 * λ^-12,
) |> sum |> sqrt

(g::Extended2)(λ) = (
    g.a0,
    g.a1 * λ^2,
    g.a2 * λ^-2,
    g.a3 * λ^-4,
    g.a4 * λ^-6,
    g.a5 * λ^-8,
    g.a6 * λ^4,
    g.a7 * λ^6,
) |> sum |> sqrt

(g::Extended3)(λ) = (
    g.a0,
    g.a1 * λ^2,
    g.a2 * λ^4,
    g.a3 * λ^-2,
    g.a4 * λ^-4,
    g.a5 * λ^-6,
    g.a6 * λ^-8,
    g.a7 * λ^-10,
    g.a8 * λ^-12,
) |> sum |> sqrt

(g::GOptical)(λ) = g.Nd + (g.Nd - 1) / g.Vd * (g.C1 + g.C2 / λ + g.C3 / λ^2 + g.C4 / λ^3)

(g::Cauchy)(λ) = g.C1 + g.C2 * λ^-2 + g.C3 * λ^-4 + g.C4 * λ^-6 + g.C5 * λ^-8 + g.C6 * λ^-10


function index(glass::Material, λ::T; temperature=TEMP_REF, pressure=PRESSURE_REF) where T<:Real
    # all calculations for the material must be done at the reference temperature (glass.Temp)
    # to work out the wavelength at the reference temperature we need the RIs of air at system temp and at reference temp
    n_air_at_sys = absairindex(λ; temperature, pressure)
    n_air_at_ref = absairindex(λ; temperature=glass.Temp)

    # scale the wavelength to air at the reference temperature/pressure
    λabs = λ * n_air_at_sys
    λ = λabs / n_air_at_ref

    if (λ < glass.Lmin) || (λ > glass.Lmax)
        error("Cannot calculate an index for the specified wavelength: $λ, valid range: [$(glass.Lmin), $(glass.Lmax)].\n")
    end

    n_rel = glass.n_rel(λ)

    # get the absolute index of the material
    n_abs = n_rel * n_air_at_ref

    # If "TD" is included in the glass data, then include pressure and temperature dependence of the lens
    # environment. From Schott"s technical report "TIE-19: Temperature Coefficient of the Refractive Index".
    # The above "n_rel" data are assumed to be from the reference temperature T_ref. Now we add a small change
    # delta_n to it due to a change in temperature.
    D0, D1, D2, E0, E1, Ltk = [getfield(glass, s) for s in (:D0, :D1, :D2, :E0, :E1, :Ltk)]
    ΔT = temperature - glass.Temp
    Δn_abs = if iszero(abs(ΔT)) || all(iszero.([D0, D1, D2, E0, E1]))
        0.0
    else
        ((n_rel^2 - 1) / (2.0 * n_rel)) * (D0 * ΔT + D1 * ΔT^2 + D2 * ΔT^3 + ((E0 * ΔT + E1 * ΔT^2) / (λ^2 - sign(Ltk) * Ltk^2)))
    end

    # make the index relative to the RI of the air at the system temperature/pressure again
    n_rel = (n_abs + Δn_abs) / n_air_at_sys
    return T(n_rel)
end

function index(::Air, ::T; temperature=TEMP_REF, pressure=PRESSURE_REF) where T<:Real
    return one(T)
end

function index(glass::AbstractMaterial, λ::T; temperature=TEMP_REF, pressure=PRESSURE_REF) where T<:Real
    return index(Material(glass), λ; temperature, pressure)
end

function absairindex(λ::T; temperature=TEMP_REF, pressure=PRESSURE_REF) where T<:Real
    # convert to required units
    n_ref = 1 + ((6432.8 + ((2949810.0 * λ^2) / (146.0 * λ^2 - 1)) + ((25540.0 * λ^2) / (41.0 * λ^2 - 1))) * 1e-8)
    n_rel = 1 + ((n_ref - 1) / (1 + (temperature - 15.0) * 0.0034785)) * (pressure / PRESSURE_REF)
    return T(n_rel)
end
