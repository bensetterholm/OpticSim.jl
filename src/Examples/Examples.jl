# MIT license
# Copyright (c) Microsoft Corporation. All rights reserved.
# See LICENSE in the project root for full license information.

"""Contains example usage of the features in the OpticSim.jl package."""
module Examples
using ..OpticSim
using ..OpticSim.Vis
using ..OpticSim.Geometry
using ..OpticSim.Emitters
using ..OpticSim.GlassCat
using ..OpticSim.Repeat

using StaticArrays
using DataFrames: DataFrame
using Images
using Unitful
using Plots
using LinearAlgebra
import Luxor

#Hardcode these glass types so this code will work even if it is not possible to download the glasses at build time.
_catalog = read(joinpath(@__DIR__, "examples.agf"), OpticSim.Materials.AGFCatalog)
for (name, glass) in zip(_catalog.glass_name, _catalog.glass)
    id = OpticSim.Catalog.addGlass(string(name), glass)
    :(const $name = OpticSim.Catalog.AGF_GLASSES[$id]) |> eval
end

include("docs_examples.jl")
include("other_examples.jl")
include("repeating_structure_examples.jl")
include("eyemodels.jl")

end #module Examples
export Examples
