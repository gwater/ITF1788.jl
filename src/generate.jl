"""
    generate(inpath, outpath="")

Generates the julia tests from the file filename. The tests in filename must be written
using the ITL domain specific language. The tests are written in a .jl file with the same
name of filename. The folder where to save the output file is specifified

If the test fails, then the test is generated as ´@test_broken`.
"""
function generate(inpath = nothing, outpath="test_ITF1788")
    inpath = something(inpath, joinpath(@__DIR__, "itl"))
    try
        mkpath(outpath)
    catch
        return
    end
    basenames = filter(endswith(".itl"), readdir(inpath)) .|> x -> x[1:end-4]
    open(joinpath(outpath, "run_ITF1788.jl"); write=true) do index
        for basename in basenames
            open(joinpath(inpath, basename * ".itl")) do src
                open(joinpath(outpath, basename * ".jl"), write = true) do dest
                    translate!(dest, src)
                end
            end
            println(
                index,
                """@testset "$basename" begin include("$basename.jl") end"""
            )
        end
    end
end
