sqr(x) = x^2
sum_sqr(x) = sum(x.^2)
sum_abs(x) = sum(abs.(x))
functions = Dict(
    "atan2" => "atan",
    "add" => "+",
    "sub" => "-",
    "pos" => "+",
    "neg" => "-",
    "mul" => "*",
    "div" => "/",
    "convexHull" => "hull",
    "intersection" => "intersect",
    "interior" => "isinterior",
    "subset" => "issubset",
    "equal" => "==",
    "sqr" => "sqr",
    "pow" => "^",
    "rootn" => "nthroot",
    "sqrt" => "sqrt",
    "exp" => "exp",
    "exp2" => "exp2",
    "exp10" => "exp10",
    "log" => "log",
    "log2" => "log2",
    "log10" => "log10",
    "sin" => "sin",
    "cos" => "cos",
    "tan" => "tan",
    "cot" => "cot",
    "asin" => "asin",
    "acos" => "acos",
    "atan" => "atan",
    "acot" => "acot",
    "sinh" => "sinh",
    "cosh" => "cosh",
    "tanh" => "tanh",
    "coth" => "coth",
    "asinh" => "asinh",
    "acosh" => "acosh",
    "atanh" => "atanh",
    "acoth" => "acoth",
    "expm1" => "expm1",
    "logp1" => "log1p",
    "cbrt" => "cbrt",
    "csc" => "csc",
    "csch" => "csch",
    "hypot" => "hypot",
    "sec" => "sec",
    "sech" => "sech",
    "intervalPart" => "interval_part",
    "isEmpty" => "isempty",
    "isEntire" => "isentire",
    "isNaI" => "isnai",
    "less" => "≤",
    "strictLess" => "<",
    "precedes" => "precedes",
    "strictPrecedes" => "strictprecedes",
    "disjoint" => "isdisjoint",
    "newDec" => "DecoratedInterval",
    "setDec" => "DecoratedInterval",
    "decorationPart" => "decoration",
    "recip" => "inv",
    "fma" => "fma",
    "pown" => "^",
    "sign" => "sign",
    "ceil" => "ceil",
    "floor" => "floor",
    "trunc" => "trunc",
    "roundTiesToEven" => "MISSINGroundTiesToEven",
    "roundTiesToAway" => "MISSINGroundTiesToAway",
    "abs" => "abs",
    "min" => "min",
    "max" => "max",
    "inf" => "inf",
    "sup" => "sup",
    "mid" => "mid",
    "rad" => "radius",
    "midRad" => "midpoint_radius",
    "wid" => "diam",
    "mag" => "mag",
    "mig" => "mig",
    "overlap" => "MISSING_overlap",
    "isCommonInterval" => "iscommon",
    "isSingleton" => "isthin",
    "isMember" => "in",
    "cancelPlus" => "cancelplus",
    "cancelMinus" => "cancelminus",
    "sum_nearest" => "sum",
    "dot_nearest" => "dot",
    "sum_abs_nearest" => "sum_abs",
    "sum_sqr_nearest" => "sum_sqr"
)