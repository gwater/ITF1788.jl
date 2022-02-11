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
    lhs = parse_lhs(lhs)
    rhs = parse_rhs(rhs)

    expr = build_expression(lhs, rhs)
    try
        return ifelse(isbroken(expr), "@test_broken ", "@test ") * expr
    catch
        @warn "caused exception: " * expr
        return "#@test_broken " * expr
    end
end

function parse_lhs(lhs)
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
    rhs == "true" && return lhs
    rhs == "false" && return lhs[end] == ')' ? "!" * lhs : "!($lhs)"
    #rhs == "emptyinterval()" && return "isempty($lhs)"
    return "$lhs == $rhs"
end

function build_expression(lhs, rhs::Vector)
    length(rhs) == 1 && return build_expression(lhs, rhs[1])
    expr = [build_expression(lhs*"[$i]", r) for (i, r) in enumerate(rhs)]
    return join(expr, " && ")
end
