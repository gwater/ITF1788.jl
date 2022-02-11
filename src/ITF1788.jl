module ITF1788

using IntervalArithmetic, LinearAlgebra

export parse_block, parse_command, generate

# Write your package code here.

include("generate.jl")
include("parse.jl")
include("functions.jl")
end
