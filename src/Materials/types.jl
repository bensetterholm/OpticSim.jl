# MIT license
# Copyright (c) Microsoft Corporation. All rights reserved.
# See LICENSE in the project root for full license information.

abstract type RelativeDispersion end

struct Schott <: RelativeDispersion
    a0::Float64
    a1::Float64
    a2::Float64
    a3::Float64
    a4::Float64
    a5::Float64
end

struct Sellmeier1 <: RelativeDispersion
    K1::Float64
    L1::Float64
    K2::Float64
    L2::Float64
    K3::Float64
    L3::Float64
end

struct Sellmeier2 <: RelativeDispersion
    A::Float64
    B1::Float64
    l1::Float64
    B2::Float64
    l2::Float64
end

struct Sellmeier3 <: RelativeDispersion
    K1::Float64
    L1::Float64
    K2::Float64
    L2::Float64
    K3::Float64
    L3::Float64
    K4::Float64
    L4::Float64
end

struct Sellmeier4 <: RelativeDispersion
    A::Float64
    B::Float64
    C::Float64
    D::Float64
    E::Float64
end

struct Sellmeier5 <: RelativeDispersion
    K1::Float64
    L1::Float64
    K2::Float64
    L2::Float64
    K3::Float64
    L3::Float64
    K4::Float64
    L4::Float64
    K5::Float64
    L5::Float64
end

struct Herzberger <: RelativeDispersion
    A::Float64
    B::Float64
    C::Float64
    D::Float64
    E::Float64
    f::Float64
end

struct Conrady <: RelativeDispersion
    n0::Float64
    A::Float64
    B::Float64
end

struct HandbookOfOptics1 <: RelativeDispersion
    A::Float64
    B::Float64
    C::Float64
    D::Float64
end

struct HandbookOfOptics2 <: RelativeDispersion
    A::Float64
    B::Float64
    C::Float64
    D::Float64
end

struct Extended <: RelativeDispersion
    a0::Float64
    a1::Float64
    a2::Float64
    a3::Float64
    a4::Float64
    a5::Float64
    a6::Float64
    a7::Float64
end

struct Extended2 <: RelativeDispersion
    a0::Float64
    a1::Float64
    a2::Float64
    a3::Float64
    a4::Float64
    a5::Float64
    a6::Float64
    a7::Float64
end

struct Extended3 <: RelativeDispersion
    a0::Float64
    a1::Float64
    a2::Float64
    a3::Float64
    a4::Float64
    a5::Float64
    a6::Float64
    a7::Float64
    a8::Float64
end

struct GOptical <: RelativeDispersion
    C1::Float64
    C2::Float64
    C3::Float64
    C4::Float64
    Nd::Float64
    Vd::Float64
end

struct Cauchy <: RelativeDispersion
    C1::Float64
    C2::Float64
    C3::Float64
    C4::Float64
    C5::Float64
    C6::Float64
end


abstract type AbstractMaterial end

struct Material
    Lmin::Float64 # μm
    Lmax::Float64 # μm
    n_rel::RelativeDispersion
    D0::Float64
    D1::Float64
    D2::Float64
    E0::Float64
    E1::Float64
    Ltk::Float64
    Temp::Float64
    TransL::Vector{Float64}
    TransTr::Vector{Float64}
    TransTh::Vector{Float64}
end

struct Air <: AbstractMaterial end
isair(::Air) = true
isair(::Material) = false
isair(::AbstractMaterial) = false

struct ModelGlass <: AbstractMaterial
    Nd::Float64
    Vd::Float64
    dPgF::Float64
end

function Material(glass::ModelGlass)
    # from Schott "TIE-29: Refractive Index and Dispersion"
    a = glass.dPgF + 0.6438 - 0.001682 * glass.Vd
    # https://www.gnu.org/software/goptical/manual/Material_Abbe_class_reference.html
    C1 = a * -6.11873891971188577088 + 1.17752614766485175224
    C2 = a * 18.27315722388047447566 + -8.93204522498095698779
    C3 = a * -14.55275321129051135927 + 7.91015964461522003148
    C4 = a * 3.48385106908642905310 + -1.80321117937358499361
    disp = GOptical(C1, C2, C3, C4, glass.Nd, glass.Vd)
    return Material(0.36, 0.75, disp, zeros(6)..., TEMP_REF, [], [], [])
end

struct MILGlass <: AbstractMaterial
    number::Int32
end

function MILGlass(number::AbstractFloat)
    @assert number > 1
    return MILGlass(round(Int, number * 1e6))
end

function ModelGlass(glass::MILGlass)
    Nd = floor(Int, glass.number / 1000) / 1000 + 1
    Vd = (glass.number - floor(Int, glass.number / 1000) * 1000) / 10
    return ModelGlass(Nd, Vd, 0)
end

Material(glass::MILGlass) = glass |> ModelGlass |> Material


struct AGFNameData
    name::String63
    dispersion_formula::Int8   # key to interpret CD entry
    MIL_num::Int32             # unused
    Nd::Float32                # index at d-line; unused
    Vd::Float32                # Abbe number at d-line; unused
    exclude_substitution::Bool
    status::Int8               # 0-indexed: [Standard, Preferred, Obsolete, Special, Melt]
    melt_freq::Int8            # Value 1-5, relative frequency of melting by manufacturer
end

struct AGFExtraData
    TCE::Float64          # -30 to 70 °C; (unitless × 10⁻⁶)
    TCE_hightemp::Float64 # ignored; 100 - 300 °C
    density::Float64      # g/cm³
    dPgF::Float64         # relative partial dispersion deviation from normal line
    ignore_thermal_expansion::Bool
end

struct AGFThermalData
    D0::Float64
    D1::Float64
    D2::Float64
    E0::Float64
    E1::Float64
    Ltk::Float64
    Temp::Float64
end

struct AGFMechanicalData
    E::Float64  # Young's Modulus in GPa (10³ N/mm²)
    nu::Float64 # Poisson's Ratio
    HK::Float64 # Knoop Hardness kg_f/mm²
    cp::Float64 # Heat Capacity J/kgK
    k::Float64  # Heat Conductivity W/mK
end

struct AGFOtherData
    relative_cost::Float64 # relative to Schott BK7
    CR::Float64 # Climatic Resistance
    FR::Float64 # Stain Resistance
    SR::Float64 # Acid Resistance
    AR::Float64 # Alkali Resistance
    PR::Float64 # Phosphate Resistance
end

struct AGFLambdaData
    min::Float64 # μm
    max::Float64 # μm
end

struct AGFInternalTransmittance
    lambda::Float64
    transmission::Float64
    thickness::Float64
end

struct AGFBirefringenceData
    lambda::Float64 # μm
    K::Float64      # Stress Optical Coefficient K = K11-K12 (10⁻⁶ mm²/N)
    mK11::Float64   # -K11: Photoelastic Coefficient ∥ to stress (10⁻⁶ mm²/N)
    mK12::Float64   # -K12: Photoelastic Coefficient ⊥ to stress (10⁻⁶ mm²/N)
end

struct AGFGlass <: AbstractMaterial
    NM::AGFNameData
    GC::String255
    ED::AGFExtraData
    CD::SVector{10, Float64}
    TD::AGFThermalData
    MD::AGFMechanicalData
    OD::AGFOtherData
    LD::AGFLambdaData
    IT::SVector{100, AGFInternalTransmittance}
    BD::AGFBirefringenceData
end

function Material(glass::AGFGlass)
    idxs = 1:(findfirst(isequal(AGFInternalTransmittance()), glass.IT) - 1)
    return Material(
        glass.LD.min,
        glass.LD.max,
        RelativeDispersion(glass),
        glass.TD.D0,
        glass.TD.D1,
        glass.TD.D2,
        glass.TD.E0,
        glass.TD.E1,
        glass.TD.Ltk,
        glass.TD.Temp,
        [getfield(x, 1) for x in glass.IT[idxs]],
        [getfield(x, 2) for x in glass.IT[idxs]],
        [getfield(x, 3) for x in glass.IT[idxs]],
    )
end

struct AGFCatalog
    name::String
    comments::Vector{String}
    glass::Vector{AGFGlass}
    glass_name::Vector{Symbol}
    glass_dict::Dict{Symbol, Material}
    function AGFCatalog(
        name,
        comments,
        glass::Vector{AGFGlass}
    )
        glass_name = _makevalidsym.([g.NM.name for g in glass])
        return new(name, comments, glass, glass_name, Dict{Symbol, Material}())
    end
end

function propertynames(x::T, private::Bool=false) where T<:AGFCatalog
    return getfield(x, :glass_name) |> Tuple
end

function getproperty(value::AGFCatalog, name::Symbol)
    glass_name = getfield(value, :glass_name)
    return if name ∉ glass_name
        getfield(value, name)
    else
        i = findfirst(isequal(name), glass_name)
        get(getfield(value, :glass_dict), name, Material(getfield(value, :glass)[i]))
    end
end
