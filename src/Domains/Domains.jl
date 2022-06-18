"""
Domain Interface
"""
module Domains

import Base: eltype, ∈, in
import PDEInterfaces: dims, deform

""" D-Dimensional Domain """
abstract type AbstractDomain{T,D} end

# Interface
include("interface.jl")

# Concrete Types
include("interval.jl")
include("box.jl")
#include("meshed.jl") # TODO

# Deformations
include("deform.jl")
include("maps.jl")

export
       # interface
       dims,
       isperiodic,
       endpoints,
       boundary_tags,
       boundary_tag,
       num_boundaries,

       ×,
       ∈,
       in,

       # concrete types
       IntervalDomain,
       BoxDomain,

       deform

end
#
