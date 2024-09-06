# MIT license
# Copyright (c) Microsoft Corporation. All rights reserved.
# See LICENSE in the project root for full license information.

_glass_type_short = LittleDict(
    AGFGlass => :AGF,
    ModelGlass => :MODEL,
    MILGlass => :MIL,
    # RefractiveLiquid => :LIQUID,
    # Eye => :EYE,
)

_get_glass_type_short(x) = _glass_type_short[first(typeof(x).parameters)]

Base.show(io::IO, a::GlassID) = print(io, "$(_get_glass_type_short(a)):$(a.num)")
Base.show(io::IO, g::AbstractGlass) = print(io, glassname(g))

function _info(io::IO, g::Material; prologue=true, epilogue=true)
    if prologue
        D = typeof(g.n_rel)
        println(io, "$(rpad("Dispersion formula:", 50)) $(D.name.name)")
        println(io, "Dispersion formula coefficients:")
        for fn in fieldnames(D)
            println(io, "     $(rpad("$fn:", 45)) $(getfield(g.n_rel, fn))")
        end

        println(io, "$(rpad("Valid wavelengths:", 50)) $(g.Lmin)μm to $(g.Lmax)μm")

        println(io, "$(rpad("Reference temperature:", 50)) $(g.Temp)°C")

        if any(.!iszero.([g.D0, g.D1, g.D2, g.E0, g.E1]))
            println(io, "Thermal ΔRI coefficients:")
            println(io, "     $(rpad("D₀:", 45)) $(g.D0)")
            println(io, "     $(rpad("D₁:", 45)) $(g.D1)")
            println(io, "     $(rpad("D₂:", 45)) $(g.D2)")
            println(io, "     $(rpad("E₀:", 45)) $(g.E0)")
            println(io, "     $(rpad("E₁:", 45)) $(g.E1)")
            println(io, "     $(rpad("λₜₖ:", 45)) $(g.Ltk)")
        end
    end

    if epilogue && length(g.TransL) > 0
        println(io, "Transmission data:")
        println(io, prod(lpad.(["Wavelength", "Transmission", "Thickness"], 15)))
        for i in eachindex(g.TransL)
            λ, t, τ = g.TransL[i], g.TransTr[i], g.TransTh[i]
            println(io, prod(lpad.(["$(λ)μm", "$t", "$(τ)mm"], 15)))
        end
    end
end

"""
    info([io::IO], glass::Glass)

Print out all data associated with `glass` in an easily readable format.

# Examples
```julia-repl
julia> info(GlassCat.RPO.IG4)
ID:                                                AGF:52
Dispersion formula:                                Schott (1)
Dispersion formula coefficients:
     a₀:                                           6.91189161
     a₁:                                           -0.000787956404
     a₂:                                           -4.22296071
     a₃:                                           142.900646
     a₄:                                           -1812.32748
     a₅:                                           7766.33028
Valid wavelengths:                                 3.0μm to 12.0μm
Reference temperature:                              20.0°C
Thermal ΔRI coefficients:
     D₀:                                           3.24e-5
     D₁:                                           0.0
     D₂:                                           0.0
     E₀:                                           0.0
     E₁:                                           0.0
     λₜₖ:                                          0.0
TCE (÷1e-6):                                       20.4
Ignore thermal expansion:                          false
Density (p):                                       4.47g/m³
ΔPgF:                                              0.0
RI at sodium D-Line (587nm):                       1.0
Abbe Number:                                       0.0
Cost relative to N_BK7:                              ?
Status:                                            Standard (0)
Melt frequency:                                    0
Exclude substitution:                              false
```
"""
function info(io::IO, glass::Glass{AGFGlass})
    ltz(x) = x < 0 ? "?" : x
    
    println(io, "$(rpad("ID:", 50)) $(repr(glass.id))")

    _info(io, glass.glass; epilogue=false)

    r = glass.raw
    println(io, "$(rpad("TCE (÷1e-6):", 50)) $(r.ED.TCE)")
    println(io, "$(rpad("Ignore thermal expansion:", 50)) $(r.ED.ignore_thermal_expansion)")

    println(io, "$(rpad("Density (p):", 50)) $(r.ED.density)g/m³")
    println(io, "$(rpad("ΔPgF:", 50)) $(r.ED.dPgF)")

    println(io, "$(rpad("RI at sodium D-Line (587nm):", 50)) $(r.NM.Nd)")
    println(io, "$(rpad("Abbe Number:", 50)) $(r.NM.Vd)")

    rc = r.OD.relative_cost
    println(io, "$(rpad("Cost relative to N_BK7:", 50)) $(ltz(rc))")

    if any([getfield(r.OD, s) for s in (:CR, :FR, :SR, :AR, :PR)] .≠ -1)
        println(io, "Environmental resistance:")
        println(io, "     $(rpad("Climate (CR):", 45)) $(ltz(r.OD.CR))")
        println(io, "     $(rpad("Stain (FR):", 45)) $(ltz(r.OD.FR))")
        println(io, "     $(rpad("Acid (SR):", 45)) $(ltz(r.OD.SR))")
        println(io, "     $(rpad("Alkaline (AR):", 45)) $(ltz(r.OD.AR))")
        println(io, "     $(rpad("Phosphate (PR):", 45)) $(ltz(r.OD.PR))")
    end

    STATUS = ["Standard", "Preferred", "Obsolete", "Special", "Melt"]
    println(io, "$(rpad("Status:", 50)) $(STATUS[r.NM.status + 1]) ($(r.NM.status))")
    println(io, "$(rpad("Melt frequency:", 50)) $(ltz(r.NM.melt_freq))/5")
    println(io, "$(rpad("Exclude substitution:", 50)) $(r.NM.exclude_substitution)")

    _info(io, glass.glass; prologue=false)
end

function info(io::IO, glass::Glass{T}) where T<:AbstractMaterial
    println(io, "$(rpad("ID:", 50)) $(repr(glass.id))")
    _info(io, glass.glass)
end

function info(io::IO, ::AirType)
    println(io, "Air")
    print(
        io,
        """
        Material representing air, RI is always 1.0 at system temperature and pressure, \
        absorption is always 0.0.
        """
    )
end

info(g::AbstractGlass) = info(stdout, g)
