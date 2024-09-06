# MIT license
# Copyright (c) Microsoft Corporation. All rights reserved.
# See LICENSE in the project root for full license information.

const GLASSES = LittleDict(
    AGFGlass => OrderedDict{String, Glass}()
)

function addGlass(name::String, glass::T) where T<:AbstractMaterial
    if isair(glass)
        @warn "Cannot add Air to $(string(@__MODULE__)).GLASSES"
        return -1
    end
    glass_dict = get!(GLASSES, T, OrderedDict{String, Glass}())
    id = length(glass_dict) + 1
    glass_dict[name] = Glass(id, glass)
    return id
end

function generate_agf_module(source::AbstractString)
    modname = Materials._makevalidsym(Materials._catalogname(source))
    genmod = quote
        module $modname
            using OpticSim.Catalog
            using OpticSim.Materials
            _catalog = read($source, Materials.AGFCatalog)
            for (i, name) in enumerate(_catalog.glass_name)
                _name = join((last(split(string($modname), '.')), name), '.')
                if String(_name) ∉ Catalog.AGF_GLASS_NAMES
                    id = Catalog.addGlass(_name, _catalog.glass[i])
                    :(const $name = Catalog.AGF_GLASSES[$id]) |> eval
                    :(export $name) |> eval
                end
            end
        end
        export $modname
    end
    genmod.head = :toplevel
    return genmod
end
