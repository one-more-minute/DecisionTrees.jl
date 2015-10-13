module DecisionTrees

using MacroTools, Data

include("impurity.jl")
include("tree.jl")
include("nulls.jl")
include("meta.jl")
include("bench.jl")

end # module
