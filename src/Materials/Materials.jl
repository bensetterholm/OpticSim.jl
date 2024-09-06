# MIT license
# Copyright (c) Microsoft Corporation. All rights reserved.
# See LICENSE in the project root for full license information.

module Materials

import Base: propertynames, getproperty, read
using InlineStrings
using Match
using StaticArrays
using StringEncodings

export AbstractMaterial
export Material
export isair
export AGFGlass, ModelGlass, MILGlass
export AGFCatalog
export absorption
export index, absairindex

const TEMP_REF = 20.0    # °C
const PRESSURE_REF = 1.0 # atm

include("types.jl")
include("io.jl")
include("absorption.jl")
include("dispersion.jl")

end # module Materials
