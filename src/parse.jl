const indent = "    "

extract_name(line) = split(line) |> parts -> join(parts[2:end-1], " ")

# ideally this should be rewritten to output to an IO buffer
function parse_block(lines; test_warn=true)
    testset_name = extract_name(first(lines))
    tests = filter(strip.(lines[2:end - 1])) do line
        return !(
            isempty(line) ||
            startswith(line, "//") || # comments
            occursin("]_", line) # decorated intervals
        )
    end
    return mapfoldl(
        test -> parse_command(test; test_warn=test_warn),
        (testset, command) -> string(testset, indent, command, "\n"),
        tests,
        init = """@testset "$testset_name" begin\n"""
    ) * "end\n\n"
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
function parse_command(line; test_warn=true)
    # extract parts in line
    lhs, rhs = split(line, "=")
    rhs = split(rhs, "signal")
    warn = length(rhs) > 1 ? rhs[2] : ""
    rhs = rhs[1]

    lhs = parse_lhs(lhs)
    rhs = parse_rhs(rhs)

    expr = build_expression(lhs, rhs)
    try
        command = ifelse(isbroken(expr), "@test_broken ", "@test ") * expr
    catch
        @warn "caused exception: " * expr
        command = "#@test_broken " * expr
    end
    if test_warn
        # change this to @test_throws?
        command = isempty(warn) ? command : "@test_logs (:warn, ) $command"
    end
    return command
end

function parse_lhs(lhs)
    lhs = strip(lhs)
    fname, args = split(lhs, limit = 2)

    # input text or decorated, ignore
    fname == "b-textToInterval" && return "true" #"@interval($args)"
    fname == "d-textToInterval" && return "true" #"@decorated($args)"
    fname == "d-numsToInterval" && return "true"
#     if fname == "d-numsToInterval"
#         args = join(split(args), ',')
#         return "DecoratedInterval($args)"
#     end
    # filter our decorated intervals

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
        args = replace(args, m.match => parse_interval(m[1], m[2]))
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
function parse_rhs(rhs)
    rhs = strip(rhs)
    rhs = replace(rhs, "infinity" => "Inf")
    rhs = replace(rhs, "X" => "x")
    if '[' ∉ rhs # one or more scalar/bolean values separated by space
        return map(int_to_float, split(rhs))
    else # one or more intervals
        rx = r"\[([^\]]+)\](?:_(\w+))?"
        ivals = [parse_interval(m[1], m[2]; check=false) for m in eachmatch(rx, rhs)]
        return ivals
    end
end

function parse_interval(ival, dec; check=true)
    ival == "nai" && return "nai()"
    if ival == "entire"
        ival =  "entireinterval()"
    elseif ival == "empty"
        ival = "emptyinterval()"
    else
        ival = check ? "interval($ival)" : "Interval($ival)"
    end
    isnothing(dec) || (ival = "DecoratedInterval($ival, $dec)")
    return ival
end

function build_expression(lhs, rhs::AbstractString)
    rhs == "nai()" && return "isnai($lhs)"
    rhs == "NaN" && return "isnan($lhs)"
    return "$lhs == $rhs"
end

function build_expression(lhs, rhs::Vector)
    length(rhs) == 1 && return build_expression(lhs, rhs[1])
    expr = [build_expression(lhs*"[$i]", r) for (i, r) in enumerate(rhs)]
    return join(expr, " && ")
end
