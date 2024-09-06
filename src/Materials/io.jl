# MIT license
# Copyright (c) Microsoft Corporation. All rights reserved.
# See LICENSE in the project root for full license information.

parseAGFline(str::AbstractString) = @match str begin
    r"CC.*" => chop(str; head=2, tail=0) |> strip |> String
    r"NM.+" => AGFNameData(str)
    r"GC.*" => chop(str; head=2, tail=0) |> strip |> String255
    r"ED.+" => AGFExtraData(str)
    r"CD.+" => AGF_CD(str)
    r"TD.+" => AGFThermalData(str)
    r"MD.+" => AGFMechanicalData(str)
    r"OD.+" => AGFOtherData(str)
    r"LD.+" => AGFLambdaData(str)
    r"IT.+" => AGFInternalTransmittance(str)
    r"BD.+" => AGFBirefringenceData(str)
    _       => nothing
end

function AGFNameData(str::AbstractString)
    substrs = split(str)
    @assert popfirst!(substrs) == "NM"
    return AGFNameData(
        String63(substrs[1]),
        parse(Int8, get(substrs, 2, "0")),
        parse(Int32, get(substrs, 3, "0")),
        parse(Float32, get(substrs, 4, "0")),
        parse(Float32, get(substrs, 5, "0")),
        parse(Bool, get(substrs, 6, "true")),
        parse(Int8, get(substrs, 7, "-1")),
        parse(Int8, get(substrs, 8, "-1")),
    )
end

function AGFExtraData(str::AbstractString)
    substrs = split(str)
    @assert popfirst!(substrs) == "ED"
    return AGFExtraData(
        parse(Float64, get(substrs, 1, "0")),
        parse(Float64, get(substrs, 2, "0")),
        parse(Float64, get(substrs, 3, "0")),
        parse(Float64, get(substrs, 4, "0")),
        parse(Bool, get(substrs, 5, "true")),
    )
end

AGFExtraData() = AGFExtraData("ED")

function AGF_CD(str::AbstractString)
    substrs = split(str)
    @assert popfirst!(substrs) == "CD"
    return SVector{10, Float64}(
        parse(Float64, get(substrs, 1, "0")),
        parse(Float64, get(substrs, 2, "0")),
        parse(Float64, get(substrs, 3, "0")),
        parse(Float64, get(substrs, 4, "0")),
        parse(Float64, get(substrs, 5, "0")),
        parse(Float64, get(substrs, 6, "0")),
        parse(Float64, get(substrs, 7, "0")),
        parse(Float64, get(substrs, 8, "0")),
        parse(Float64, get(substrs, 9, "0")),
        parse(Float64, get(substrs, 10, "0")),
    )
end

AGF_CD() = AGF_CD("CD")

function AGFThermalData(str::AbstractString)
    substrs = split(str)
    @assert popfirst!(substrs) == "TD"
    return AGFThermalData(
        parse(Float64, get(substrs, 1, "0")),
        parse(Float64, get(substrs, 2, "0")),
        parse(Float64, get(substrs, 3, "0")),
        parse(Float64, get(substrs, 4, "0")),
        parse(Float64, get(substrs, 5, "0")),
        parse(Float64, get(substrs, 6, "0")),
        parse(Float64, get(substrs, 7, "0")),
    )
end

AGFThermalData() = AGFThermalData("TD")

function AGFMechanicalData(str::AbstractString)
    substrs = split(str)
    @assert popfirst!(substrs) == "MD"
    return AGFMechanicalData(
        parse(Float64, get(substrs, 1, "0")),
        parse(Float64, get(substrs, 2, "0")),
        parse(Float64, get(substrs, 3, "0")),
        parse(Float64, get(substrs, 4, "0")),
        parse(Float64, get(substrs, 5, "0")),
    )
end

AGFMechanicalData() = AGFMechanicalData("MD")

function AGFOtherData(str::AbstractString)
    substrs = split(str)
    @assert popfirst!(substrs) == "OD"
    return AGFOtherData(
        parse(Float64, get(substrs, 1, "0")),
        parse(Float64, get(substrs, 2, "0")),
        parse(Float64, get(substrs, 3, "0")),
        parse(Float64, get(substrs, 4, "0")),
        parse(Float64, get(substrs, 5, "0")),
        parse(Float64, get(substrs, 6, "0")),
    )
end

AGFOtherData() = AGFOtherData("OD")

function AGFLambdaData(str::AbstractString)
    substrs = split(str)
    @assert popfirst!(substrs) == "LD"
    return AGFLambdaData(
        parse(Float64, get(substrs, 1, "0")),
        parse(Float64, get(substrs, 2, "0")),
    )
end

AGFLambdaData() = AGFLambdaData("LD")

function AGFInternalTransmittance(str::AbstractString)
    substrs = split(str)
    @assert popfirst!(substrs) == "IT"
    return AGFInternalTransmittance(
        parse(Float64, get(substrs, 1, "0")),
        parse(Float64, get(substrs, 2, "0")),
        parse(Float64, get(substrs, 3, "0")),
    )
end

AGFInternalTransmittance() = AGFInternalTransmittance("IT")

function AGFBirefringenceData(str::AbstractString)
    substrs = split(str)
    @assert popfirst!(substrs) == "BD"
    return AGFBirefringenceData(
        parse(Float64, get(substrs, 1, "0")),
        parse(Float64, get(substrs, 2, "0")),
        parse(Float64, get(substrs, 3, "0")),
        parse(Float64, get(substrs, 4, "0")),
    )
end

AGFBirefringenceData() = AGFBirefringenceData("BD")

function AGFGlass(vec::Vector)
    NM = first(vec)
    GC = _getfirstorbust(String255, vec)
    ED = _getfirstorbust(AGFExtraData, vec)
    CD = _getfirstorbust(SVector{10, Float64}, vec)
    TD = _getfirstorbust(AGFThermalData, vec)
    MD = _getfirstorbust(AGFMechanicalData, vec)
    OD = _getfirstorbust(AGFOtherData, vec)
    LD = _getfirstorbust(AGFLambdaData, vec)
    _IT = filter(x -> isa(x, AGFInternalTransmittance), vec)
    IT = SVector{100, AGFInternalTransmittance}(vcat(_IT, fill(AGFInternalTransmittance(), 100 - length(_IT))))
    BD = _getfirstorbust(AGFBirefringenceData, vec)
    return AGFGlass(NM, GC, ED, CD, TD, MD, OD, LD, IT, BD)
end

function _getfirstorbust(T::DataType, v::AbstractVector)
    i = findfirst(x -> isa(x, T), v)
    return if isnothing(i)
        if T <: SVector
            T(zeros(length(T)))
        else
            T()
        end
    else
        v[i]
    end
end

function _makevalidsym(name::AbstractString)
    # remove invalid characters
    name = replace(name, "*" => "_STAR")
    name = replace(name, r"""[ ,.:;?!()&-]""" => "_")
    # cant have module names which are just numbers so add a _ to the start
    if tryparse(Int, "$(name[1])") !== nothing
        name = "_" * name
    end
    return Symbol(name)
end

function _catalogname(path::AbstractString)
    name = uppercase(basename(path))
    fl = findlast('.', name)
    return if !isnothing(fl) && name[fl:end] == ".AGF"
        name[1:fl-1]
    else
        name
    end
end

function read(path::AbstractString, ::Type{AGFCatalog})
    name = _catalogname(path)
    file = open(path)
    encoding = read(file, UInt16) == 0xfeff ? enc"UTF-16" : enc"UTF-8"
    seekstart(file)
    lines = parseAGFline.(readlines(path, encoding))
    comments = filter(x -> isa(x, String), lines)
    start = findall(x -> isa(x, AGFNameData), lines)
    stop = fill(length(lines), length(start))
    stop[begin:end-1] = start[begin+1:end] .- 1
    glasses = map(range.(start, stop)) do idxs
        AGFGlass(lines[idxs])
    end
    return AGFCatalog(name, comments, glasses)
end
