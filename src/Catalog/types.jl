# MIT license
# Copyright (c) Microsoft Corporation. All rights reserved.
# See LICENSE in the project root for full license information.

"""
    GlassID{T}

Object identifying a glass, containing a type T, depending on how the glass is defined, and
an integer ID. Air is `AirType:0`, others are on the form `AGF:N`, for example.
"""
struct GlassID{T}
    num::Int
    function GlassID{T}(num) where T<:AbstractMaterial
        new(num)
    end
    function GlassID{AirMaterial}(num=0)
        num ≠ 0 && @warn "Air must have an ID value of 0"
        new(0)
    end
end

abstract type AbstractGlass end

struct AirType <: AbstractGlass end

propertynames(::AirType) = (:id, :glass)
function getproperty(T::AirType, sym::Symbol)
    return if sym == :id
        GlassID{AirMaterial}()
    elseif sym == :glass || sym == :raw
        AirMaterial()
    else
        # generic fallback (throw error)
        getfield(T, sym)
    end
end

"""
    Air

Special glass to represent air. Refractive index is defined to always be 1.0 for any
temperature and pressure (other indices are relative to this).
"""
const Air = AirType()

"""
    isair(a) -> Bool

Tests if a is Air.
"""
isair(::AirType) = true
isair(::GlassID{AirType}) = true

struct Glass{T} <: AbstractGlass
    id::GlassID{T}
    glass::Material
    raw::T
    function Glass(id, glass::T) where T<:AbstractMaterial
        new{T}(GlassID{T}(id), Material(glass), glass)
    end
end

function propertynames(g::Glass)
    return (:id, propertynames(g.glass)...)
end

Glass(_, ::AirMaterial) = Air

"""
    glassid(g::AbstractGlass) -> GlassID

Get the ID of the glass, see [`GlassID`](@ref).
"""
glassid(g::AbstractGlass) = g.id

"""
    glassname(g::Union{AbstractGlass, GlassID})

Get the name (including catalog) of the glass, or glass with this ID.
"""
glassname(::AirType) = "Air"
glassname(g::Glass) = glassname(g.id)
function glassname(ID::GlassID{T}) where T
    if T ∉ GLASSES.keys
        throw(ArgumentError("unsupported GlassID type $T"))
    end
    return GLASSES[T].keys[ID.num]
end

"""
    glassforid(ID::GlassID)

Get the glass for a given ID.
"""
glassforid(::GlassID{AirMaterial}) = Air
function glassforid(ID::GlassID{T}) where T
    if T ∉ GLASSES.keys
        throw(ArgumentError("unsupported GlassID type $T"))
    end
    return GLASSES[T].vals[ID.num]
end
