# MIT license
# Copyright (c) Microsoft Corporation. All rights reserved.
# See LICENSE in the project root for full license information.

using HTTP
using Scratch
using SHA
using TOML
using ZipFile

mod_dir = dirname(@__DIR__)
uuid = Base.UUID(TOML.parsefile(joinpath(mod_dir, "Project.toml"))["uuid"])
AGF_DIR = get_scratch!(uuid, "agf")
SOURCES_PATH = joinpath(get_scratch!(uuid, "sources"), "agf_sources.txt")

include(joinpath(mod_dir, "src", "Catalog", "external.jl"))

# Build/verify a source directory using information from sources.txt
build!(; source_txt_backup=joinpath(@__DIR__, "agf_sources.txt"))
