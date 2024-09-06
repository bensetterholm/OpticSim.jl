# MIT license
# Copyright (c) Microsoft Corporation. All rights reserved.
# See LICENSE in the project root for full license information.

function absorption(glass::Material, λ::T; temperature=TEMP_REF, pressure=PRESSURE_REF) where T<:Real
    # if the glass has no transmission data then assume no absorption
    N = length(glass.TransL)
    iszero(N) && return zero(T)

    # to work out the wavelength at the reference temperature we need the RIs of air at system temp and at reference temp
    n_air_at_sys = absairindex(λ; temperature, pressure)
    n_air_at_ref = absairindex(λ; temperature=glass.Temp)

    # scale the wavelength to air at the reference temperature/pressure
    λ = λ * (n_air_at_sys / n_air_at_ref)

    if λ < glass.TransL[1]
        t = glass.TransTr[1]
        τ = glass.TransTh[1]
        return T(-log1p(t - 1.0) / τ)
    elseif λ > glass.TransL[N]
        t = glass.TransTr[N]
        τ = glass.TransTh[N]
        return T(-log1p(t - 1.0) / τ)
    else
        let λlow = 0.0, tlow = 0.0, τlow = 0.0, λhigh = 0.0, thigh = 0.0, τhigh = 0.0
            for i in 2:N
                if λ <= glass.TransL[i]
                    λlow, tlow, τlow = glass.TransL[i-1], glass.TransTr[i-1], glass.TransTh[i-1]
                    λhigh, thigh, τhigh = glass.TransL[i], glass.TransTr[i], glass.TransTh[i]
                    break
                end
            end
            δλ = λhigh - λlow
            @assert τlow == τhigh
            t = (tlow * (λhigh - λ) / δλ) + (thigh * (λ - λlow) / δλ)
            return T(-log1p(t - 1.0) / τhigh)
        end
    end
end

function absorption(::Air, ::T; temperature=TEMP_REF, pressure=PRESSURE_REF) where T<:Real
    return zero(T)
end

function absorption(glass::AbstractMaterial, λ::T; temperature=TEMP_REF, pressure=PRESSURE_REF) where T<:Real
    return absorption(Material(glass), λ; temperature, pressure)
end
