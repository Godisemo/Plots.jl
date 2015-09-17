
# Compose pseudo-forms for simple symbols, all parameterized by center and size

# using Compose: x_measure, y_measure


function createGadflyAnnotation(d::Dict)
  sz = [d[:markersize] * Gadfly.px]

  x, y = d[:x], d[:y]
  marker = d[:marker]

  if d[:linetype] == :ohlc
    shape = ohlcshape(x, y, d[:markersize])
    d[:y] = Float64[z[1] for z in y]
    d[:linetype] = :none
    return Gadfly.Guide.annotation(Gadfly.compose(Gadfly.context(), shape, Gadfly.fill(nothing), Gadfly.stroke(d[:color])))  

  elseif marker == :rect
    shape = square(x, y, sz)

  elseif marker == :diamond
    shape = diamond(x, y, sz)

  elseif marker == :cross
    shape = cross(x, y, sz)

  else
    # make circles
    sz = 0.8 * d[:markersize] * Gadfly.px
    xs = collect(float(d[:x]))
    ys = collect(float(d[:y]))
    shape = Gadfly.circle(xs,ys,[sz])
  end

  Gadfly.Guide.annotation(Gadfly.compose(Gadfly.context(), shape, Gadfly.fill(d[:markercolor]), Gadfly.stroke(nothing)))  
end


function square(xs::AbstractArray, ys::AbstractArray, rs::AbstractArray)
  n = max(length(xs), length(ys), length(rs))

  rect_xs = Vector{Compose.Measure}(n)
  rect_ys = Vector{Compose.Measure}(n)
  rect_ws = Vector{Compose.Measure}(n)
  s = 1/sqrt(2)
  for i in 1:n
    x = Compose.x_measure(xs[1 + i % length(xs)])
    y = Compose.y_measure(ys[1 + i % length(ys)])
    r = rs[1 + i % length(rs)]

    rect_xs[i] = x - s*r
    rect_ys[i] = y + s*r
    rect_ws[i] = 2*s*r
  end

  return Gadfly.rectangle(rect_xs, rect_ys, rect_ws, rect_ws)
end


function diamond(xs::AbstractArray, ys::AbstractArray, rs::AbstractArray)
  n = max(length(xs), length(ys), length(rs))

  polys = Vector{Vector{Tuple{Compose.Measure, Compose.Measure}}}(n)
  for i in 1:n
    x = Compose.x_measure(xs[1 + i % length(xs)])
    y = Compose.y_measure(ys[1 + i % length(ys)])
    r = rs[1 + i % length(rs)]
    polys[i] = Tuple{Compose.Measure, Compose.Measure}[(x, y - r), (x + r, y), (x, y + r), (x - r, y)]
  end

  return Gadfly.polygon(polys)
end


function cross(xs::AbstractArray, ys::AbstractArray, rs::AbstractArray)
  n = max(length(xs), length(ys), length(rs))

  polys = Vector{Vector{Tuple{Compose.Measure, Compose.Measure}}}(n)
  s = 1/sqrt(5)
  for i in 1:n
    x = Compose.x_measure(xs[1 + i % length(xs)])
    y = Compose.y_measure(ys[1 + i % length(ys)])
    r = rs[1 + i % length(rs)]
    u = s*r
    polys[i] = Tuple{Compose.Measure, Compose.Measure}[
        (x, y - u), (x + u, y - 2u), (x + 2u, y - u),
        (x + u, y), (x + 2u, y + u), (x + u, y + 2u),
        (x, y + u), (x - u, y + 2u), (x - 2u, y + u),
        (x - u, y), (x - 2u, y - u), (x - u, y - 2u) ]
  end

  return Gadfly.polygon(polys)
end


# Base.isfinite{T<:Real}(x::Tuple{T,T,T,T}) = isfinite(x[1]) && isfinite(x[2]) && isfinite(x[3]) && isfinite(x[4])

function ohlcshape{T}(xs::AVec, ys::AVec{Tuple{T,T,T,T}}, tickwidth::Real)
  @assert length(xs) == length(ys)
  n = length(xs)
  u = tickwidth * Compose.px
  polys = Vector{Vector{Tuple{Compose.Measure, Compose.Measure}}}(n)
  for i in 1:n
    x = Compose.x_measure(xs[i])
    o,h,l,c = map(Compose.y_measure, ys[i])
    polys[i] = Tuple{Compose.Measure, Compose.Measure}[
      (x, o), (x - u, o), (x, o),   # open tick
      (x, l), (x, h), (x, c),       # high/low bar
      (x + u, c), (x, c)            # close tick
    ]
  end
  return Gadfly.polygon(polys)
end
