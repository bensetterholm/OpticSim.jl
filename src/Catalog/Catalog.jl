# MIT license
# Copyright (c) Microsoft Corporation. All rights reserved.
# See LICENSE in the project root for full license information.

module Catalog

import Base: show, propertynames, getproperty
using HTTP
using Scratch
using OrderedCollections
using OpticSim.Materials
import OpticSim.Materials: isair, index, absorption, absairindex, TEMP_REF, PRESSURE_REF
using Plots
using SHA
using Unitful
using ZipFile

const AGF_DIR = @get_scratch!("agf")
const SOURCES_PATH = joinpath(@get_scratch!("sources"), "agf_sources.txt")

const AirMaterial = Materials.Air

include("types.jl")
include("collection.jl")
include("liquids.jl")
include("eye.jl")
include("io.jl")
include("search.jl")
include("external.jl")

function modelglass(Nd, Vd, dPgF; name=nothing)
    T = Materials.ModelGlass
    glass = T(Nd, Vd, dPgF)
    mgdict = get!(GLASSES, T, OrderedDict{String, Glass}())
    _name = isnothing(name) ? "MODEL_$(length(mgdict))" : name
    id = addGlass(_name, glass)
    return GLASSES[T].vals[id]
end

function glassfromMIL(n)
    glass = Materials.MILGlass(n)
    id = addGlass("MIL_$(glass.number)", glass)
    return GLASSES[Materials.MILGlass].vals[id]
end

const AGF_GLASS_NAMES = GLASSES[AGFGlass].keys
const AGF_GLASSES = GLASSES[AGFGlass].vals

struct _OtherGlasses end
function getproperty(::_OtherGlasses, sym::Symbol)
    return vcat(
        getproperty(GLASSES[CARGILLE.RefractiveLiquid], sym),
        getproperty(GLASSES[EYE.Eye], sym)
    )
end
_OTHER_GLASSES = _OtherGlasses()
const OTHER_GLASS_NAMES = _OTHER_GLASSES.keys
const OTHER_GLASSES = _OTHER_GLASSES.vals

function __init__()
    agf_files = filter(endswith(".agf"), readdir(AGF_DIR, join=true))
    generate_agf_module.(agf_files) .|> eval
end

end # module Catalog
