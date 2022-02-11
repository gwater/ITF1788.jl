const indent = "    "

extract_name(line) = join(split(line)[2:end-1], " ")

start_block(dest, line) =
    println(dest, "@testset \"", extract_name(line), "\" begin")
finish_block(dest) = println(dest, "end")

skip_block(line) = occursin("dec", extract_name(line))

function translate!(dest::IO, src::IO)
    while !eof(src)
        line = rstrip(strip(readline(src)), ';')
        if isempty(line) || startswith(line, "//")
            nothing
        elseif startswith(line, "/*")
            readuntil(src, "\n*/\n")
        elseif startswith(line, "testcase")
            if skip_block(line)
                readuntil(src, "\n}\n")
            else
                start_block(dest, line)
            end
        elseif line == "}"
            finish_block(dest)
        else
            translate!(dest, line)
        end
    end
end

skip_testcase(line) = any((
        occursin("]_", line), # decorated intervals
        occursin("d-numsToInterval", line), # decorated intervals
        occursin("textToInterval", line), # string input
        occursin("signal", line), # log tests
    ))

function translate!(dest::IO, itl_test::AbstractString)
    skip_testcase(itl_test) && return
    jl_test = translate(itl_test)
    print(dest, join(repeat(' ', 4))) # indentation
    println(dest, jl_test)
end

isbroken(expr) = !eval(Meta.parse(expr))

"""

This function parses a line into julia code, e.g.

```
add [1, 2] [1, 2] = [2, 4]
```

is parsed into
```
@test +(Interval(1, 2), Interval(1, 2)) === Interval(2, 4)
```
"""
function translate(itl_test)
    lhs, rhs = split(itl_test, "=")
    jl_test = rebuild(rebuild_lhs(lhs), rebuild_rhs(rhs))
    try
        return ifelse(isbroken(jl_test), "@test_broken ", "@test ") * jl_test
    catch
        @warn "caused exception: " * jl_test
        return "#@test_broken " * jl_test
    end
end

function rebuild_lhs(lhs)
    lhs = strip(lhs)
    fname, args = split(lhs, limit = 2)

    # input numbers
    args = replace(args, "infinity" => "Inf")
    args = replace(args, "X" => "x")
    if fname == "b-numsToInterval"
        args = join(split(args), ',')
        return "interval($args)"
    end

    # input intervals
    rx = r"\[([^\]]+)\](?:_(\w+))?" # this is incomprehensible
    for m in eachmatch(rx, args)
        args = replace(args, m.match => translate_interval(m[1], m[2]))
    end
    args = replace(args, " " => ", ")
    args = replace(args, ",," => ",")
    args = replace(args, "{" => "[")
    args = replace(args, "}" => "]")
    return functions[fname](args)

end

function int_to_float(x)
    if isnothing(tryparse(Int, x))
        return x
    else
        return x*".0"
    end
end
function rebuild_rhs(rhs)
    rhs = strip(rhs)
    rhs = replace(rhs, "infinity" => "Inf")
    rhs = replace(rhs, "X" => "x")
    if '[' ∉ rhs # one or more scalar/bolean values separated by space
        return map(int_to_float, split(rhs))
    else # one or more intervals
        rx = r"\[([^\]]+)\](?:_(\w+))?"
        ivals = [translate_interval(m[1], m[2]) for m in eachmatch(rx, rhs)]
        return ivals
    end
end

const special_intervals = Dict(
    "nai" => "nai()",
    "entire" => "entireinterval()",
    "empty" => "emptyinterval()"
)

translate_interval(ival, dec) =
    haskey(special_intervals, ival) ?
    special_intervals[ival] :
    "interval($ival)"

function rebuild(lhs, rhs::AbstractString)
    rhs == "nai()" && return "isnai($lhs)"
    rhs == "NaN" && return "isnan($lhs)"
    rhs == "true" && return lhs
    rhs == "false" && return lhs[end] == ')' ? "!" * lhs : "!($lhs)"
    #rhs == "emptyinterval()" && return "isempty($lhs)"
    return "$lhs == $rhs"
end

function rebuild(lhs, rhs::Vector)
    length(rhs) == 1 && return rebuild(lhs, rhs[1])
    expr = [rebuild(lhs*"[$i]", r) for (i, r) in enumerate(rhs)]
    return join(expr, " && ")
end
