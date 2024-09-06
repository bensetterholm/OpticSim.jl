# MIT license
# Copyright (c) Microsoft Corporation. All rights reserved.
# See LICENSE in the project root for full license information.

export CARGILLE

# all other glasses should follow the format below, new glasses must be added to OTHER_GLASSES and OTHER_GLASS_NAMES where the index in the array matches the numeric part of the GlassID

module CARGILLE
using StaticArrays
using OrderedCollections
using OpticSim.Catalog
using OpticSim.Materials: AbstractMaterial, Material, Cauchy
export RefractiveLiquid

struct RefractiveLiquid <: AbstractMaterial
    Lmin::Float64
    Lmax::Float64
    C::SVector{6, Float64}
    D0::Float64
    Temp::Float64
    TransL::Vector{Float64}
    TransTr::Vector{Float64}
    TransTh::Vector{Float64}
    dPgF::Float64
    TCE::Float64
    Nd::Float64
    Vd::Float64
    p::Float64
end

function Material(liquid::RefractiveLiquid)
    return Material(
        liquid.Lmin,
        liquid.Lmax,
        Cauchy(liquid.C...),
        liquid.D0,
        zeros(5)...,
        liquid.Temp,
        liquid.TransL,
        liquid.TransTr,
        liquid.TransTh,
    )
end

_catalog = OrderedDict(
    :OG0608 => RefractiveLiquid(0.32, 1.55, [1.4451400, 0.0043176, -1.80659e-5, 0, 0, 0], -0.0009083144750540808, 25.0, [0.32, 0.365, 0.4047, 0.480, 0.4861, 0.5461, 0.5893, 0.6328, 0.6439, 0.6563, 0.6943, 0.840, 0.10648, 0.1300, 0.1550], [0.03, 0.16, 0.40, 0.71, 0.72, 0.80, 0.90, 0.92, 0.95, 0.96, 0.99, 0.99, 0.74, 0.39, 0.16], [10.0, 100.0, 100.0, 100.0, 100.0, 100.0, 100.0, 100.0, 100.0, 100.0, 100.0, 100.0, 100.0, 100.0, 100.0], 0.008, 800.0, 1.457518, 57.18978, 0.878),
    :OG0607 => RefractiveLiquid(0.32, 1.55, [1.44503, 0.0044096, -2.85878e-5, 0, 0, 0], -0.0009083144750540808, 25.0, [0.32, 0.365, 0.4047, 0.480, 0.4861, 0.5461, 0.5893, 0.6328, 0.6439, 0.6563, 0.6943, 0.840, 0.10648, 0.1300, 0.1550], [0.15, 0.12, 0.42, 0.78, 0.79, 0.86, 0.90, 0.92, 0.90, 0.92, 0.98, 0.99, 0.61, 0.39, 0.11], [10.0, 100.0, 100.0, 100.0, 100.0, 100.0, 100.0, 100.0, 100.0, 100.0, 100.0, 100.0, 100.0, 100.0, 100.0], 0.008, 700.0, 1.457587, 57.19833, 0.878),
    :OG081160 => RefractiveLiquid(0.32, 1.55, [1.49614, 0.00692199, -8.07052e-5, 0, 0, 0], -0.000885983052189022, 25.0, [0.32, 0.365, 0.4047, 0.480, 0.4861, 0.5461, 0.5893, 0.6328, 0.6439, 0.6563, 0.6943, 0.840, 0.10648, 0.1300, 0.1550], [0.04, 0.13, 0.26, 0.48, 0.49, 0.60, 0.68, 0.71, 0.73, 0.74, 0.76, 0.83, 0.86, 0.89, 0.90], [100.0, 100.0, 100.0, 100.0, 100.0, 100.0, 100.0, 100.0, 100.0, 100.0, 100.0, 100.0, 100.0, 100.0, 100.0], 0.014, 700.0, 1.515549, 36.82493, 1.11),
)

for i in 1:length(_catalog)
    sym = _catalog.keys[i]
    id = Catalog.addGlass("CARGILLE.$sym", _catalog.vals[i])
    :(const $sym = Catalog.GLASSES[RefractiveLiquid].vals[$id]) |> eval
    :(export $sym) |> eval
end
end
