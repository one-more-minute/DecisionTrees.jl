# x: independent variable
# y: dependent variable
# z: value to split x on

isleft(x, z) = isleft(vartype(x), x, z)

isright(args...) = !isleft(args...)

isleft(::Continuous, x, z) = x ≤ z

isleft(::Categorical, x, z) = x == z

function split(xs, ys, z)
  left = eltype(ys)[]
  right = eltype(ys)[]
  for (i, x) in enumerate(xs)
    push!(isleft(vareltype(xs), x, z) ? left : right, ys[i])
  end
  return left, right
end

split(xs, z) = split(xs, 1:length(xs), z)::NTuple{2, Vector{Int}}

function score(xs, ys, z)
  left, right = split(xs, ys, z)
  improvement(ys, left, right)
end

function bestsplit(xs, ys)
  best, imp = first(xs), -Inf
  for x in unique(xs)
    if (i = score(xs, ys, x)) > imp
      best = x
      imp = i
    end
  end
  return best, imp
end

function bestsplit(data::DataSet, y)
  ys = data[y]
  col, z, score = nothing, nothing, -Inf
  for name in names(data)
    name == Symbol(y) && continue
    z′, score′ = bestsplit(data[name], ys)
    score′ > score && ((col, z, score) = (name, z′, score′))
  end
  return col, z, score
end

function split(data::DataSet, x, z)
  left, right = split(data[x], z)
  return data[left], data[right]
end

immutable Branch
  col::Symbol
  val
  left::Nullable{Branch}
  right::Nullable{Branch}
end

@gensym leaf

Leaf(val) = Branch(leaf, val, nothing, nothing)

isleaf(b::Branch) = b.col == leaf

isstop(data) = length(data) ≤ 10

final(xs) = final(vareltype(xs), xs)

final(::Categorical, xs) = mode(xs)

final(::Continuous, xs) = mean(xs)

function tree(data, y)
  isstop(data) && @goto leaf
  col, val, imp = bestsplit(data, y)
  imp ≤ 0 && @goto leaf
  left, right = split(data, col, val)
  return Branch(col, val, tree(left, y), tree(right, y))

  @label leaf
  return Leaf(final(data[y]))
end

function classify(data::DataSet, tree::Branch, row::Integer)
  isleaf(tree) && return tree.val
  next = get(isleft(data[tree.col, row], tree.val) ? tree.left : tree.right)
  return classify(data::DataSet, next, row)
end

classify(data::DataSet, tree::Branch) =
  map(row -> classify(data, tree, row), 1:length(data))

function accuracy(data::DataSet, y, tree::Branch)
  labels = classify(data, tree)
  ys = data[y]
  sum(ys .== labels) / length(labels)
end
