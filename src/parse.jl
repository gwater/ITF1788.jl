
extract_name(line) = join(split(line)[2:end-1], " ")

start_testset!(dest, line) =
    println(dest, "@testset \"", extract_name(line), "\" begin")
finish_testset!(dest) = println(dest, "end\n")

begins_testset(line) = startswith(line, "testcase")
finishes_testset(line) = line == "}"
begins_decoration_testset(line) = occursin("dec", extract_name(line))
is_comment(line) = startswith(line, "//")
begins_multiline_comment(line) = startswith(line, "/*")

skip_block(src, stopline) = readuntil(src, "\n" * stopline * "\n")
skip_multiline_comment(src) = skip_block(src, "*/")
skip_testset(src) = skip_block(src, "}")

function translate!(dest::IO, src::IO)
    while !eof(src)
        line = rstrip(strip(readline(src)), ';')
        if isempty(line) || is_comment(line)
            nothing
        elseif begins_multiline_comment(line)
            skip_multiline_comment(src)
        elseif begins_testset(line)
            if begins_decoration_testset(line)
                skip_testset(src)
            else
                start_testset!(dest, line)
            end
        elseif finishes_testset(line)
            finish_testset!(dest)
        else
            itl_test = line
            translate!(dest, itl_test)
        end
    end
end

tests_decorated_intervals(case) =
    occursin("]_", case) || occursin("d-numsToInterval", case)
tests_string_input(case) = occursin("textToInterval", case)
tests_logging(case) = occursin("signal", case)

skip_testcase(case) =
    tests_decorated_intervals(case) ||
    tests_string_input(case) ||
    tests_logging(case)

indent(io) = print(io, repeat(' ', 4))

function translate!(dest::IO, itl_test::AbstractString)
    skip_testcase(itl_test) && return
    jl_test = translate(itl_test)
    indent(dest)
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
        return "# " * itl_test
    end
end

const interval_pattern = r"\[([^\]]+)\]"

function rebuild_lhs(lhs)
    lhs = strip(lhs)
    fname, args = split(lhs, limit = 2)

    # input numbers
    args = replace(args, "infinity" => "Inf")
    args = replace(args, "X" => "x")
    if fname == "b-numsToInterval"
        args = replace(args, ' ' => ',')
        return "interval($args)"
    end

    # input intervals
    for m in eachmatch(interval_pattern, args)
        args = replace(args, m.match => translate_interval(m[1]))
    end
    args = replace(args, " " => ", ")
    args = replace(args, ",," => ",")
    args = replace(args, "{" => "[")
    args = replace(args, "}" => "]")
    return functions[fname](args)
end

isintstring(x) = !isnothing(tryparse(Int, x))
floatstring(x) = x * ifelse(isintstring(x), ".0", "")

function rebuild_rhs(rhs)
    rhs = strip(rhs)
    rhs = replace(rhs, "infinity" => "Inf")
    rhs = replace(rhs, "X" => "x")
    if '[' ∉ rhs # one or more scalar/boolean values separated by space
        return map(floatstring, split(rhs))
    else # one or more intervals
        intervals = map(
            m -> translate_interval(m[1]),
            eachmatch(interval_pattern, rhs)
        )
        return intervals
    end
end

const special_intervals = Dict(
    "nai" => "nai()",
    "entire" => "entireinterval()",
    "empty" => "emptyinterval()"
)

translate_interval(ival) =
    haskey(special_intervals, ival) ?
    special_intervals[ival] :
    "interval($ival)"

function rebuild(lhs, rhs::AbstractString)
    rhs == "nai()" && return "isnai($lhs)"
    rhs == "NaN" && return "isnan($lhs)"
    rhs == "true" && return lhs
    rhs == "false" && return lhs[end] == ')' ? "!" * lhs : "!($lhs)"
    return "$lhs == $rhs"
end

function rebuild(lhs, rhs::Vector)
    length(rhs) == 1 && return rebuild(lhs, rhs[1])
    expr = [rebuild(lhs*"[$i]", r) for (i, r) in enumerate(rhs)]
    return join(expr, " && ")
end
