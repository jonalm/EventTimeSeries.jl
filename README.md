
[![Build Status](https://travis-ci.com/jonalm/EventTimeSeries.jl.svg?branch=master)](https://travis-ci.com/jonalm/EventTimeSeries.jl)


# EventTimeSeries.jl

This package provides some functionality to handle event time series where each row/entry conforms to a triplet which consist of a timestamp, a tag and a value.

If you are looking for general time series functionality, check out the much more mature [TimeSeries.jl](https://github.com/JuliaStats/TimeSeries.jl) package first.  

This package is motivated by sparse time series (i.e. one tag-value pair per timestamp) which represents state changes (i.e. tag-value pairs are valid until a new value is given for the same tag, and "forward fill" is the natural imputation strategy).

The package exports the type `EventTS` (subtype of `AbstractVector{Event}`) which holds the time series. It should be constructed by named arguments `EventTS(;timestamps, tag, values)` where
 - The `timestamps` must be a sorted vector and contain the same number of elements as `values`.
- The tag need to have a `tagtype(tag)` trait.

If `tagtype(tag) == EventTag` then `tag` is unique and applied to each entry in the series.

If `tagtype(tag) == SeriesTag()` and `tagtype(eltype(tag)) == EventTag()`, then `tag` holds a (potentially different) tag for each entry in the series.

By default `tagtype(tag::T) == SeriesTag()` if `T<:AbstractVector` or `T<:AbstractRange`, and `tagtype(tag::T) == EventTag()` for when `T` is any of `Symbol, Char, String, Tuple, NamedTuple, Number`.

`tagtype(ts::EventTS)` returns the tag type of the tag used to construct the time series.

## Main functionality

`splice(ts::EventTS...)` splices together an arbitrary number of `EventTS` and returns a single `EventTS` where all entries are sorted with respect to timestamps.

`split(ts::EventTS)` splits the time series and returns an array of `EventTS`, where each `EventTS` element has a unique tag.

`drop_repeated(ts::EventTS; keep_end=true)` returns an `EventTS`, where entries of (`timestamp, tag, value`) are dropped if the it contains a repeating  `value` for a given `tag`. If `keep_end=true` then the entry with the largest timestamp is kept regardless.

`merge_tags(ts::EventTS)` returns a new `EventTS`. If `tagtype(ts)==EventTag()` it simply returns `ts`. If `tagtype(ts)==SeriesTag()`, the returned time series has:
- One entry for each timestamp in the input.
- Each value contains a tuple of values for each tag in the input. Values for each tag are filled forward.
- The tag is a sorted tuple of all unique tags in the input series.

## Examples

```julia
julia> using EventTimeSeries
julia> ts1 = EventTS(timestamps=[1,4,10], values=[1, 123.4, "hello"], tag=:A)
julia> ts1 |> pretty_print
======= ===== ========
  time   tag   value  
======= ===== ========
     1     A       1  
     4     A   123.4  
    10     A   hello  
======= ===== ========


julia> ts2 = EventTS(timestamps=[2,3,6], values=[:foo, :bar, :bar], tag=:B)
julia> ts2 |> pretty_print
======= ===== ========
  time   tag   value  
======= ===== ========
     2     B     foo  
     3     B     bar  
     6     B     bar  
======= ===== ========


julia> ts = splice(ts1, ts2)
julia> ts |> pretty_print
======= ===== ========
  time   tag   value  
======= ===== ========
     1     A       1  
     2     B     foo  
     3     B     bar  
     4     A   123.4  
     6     B     bar  
    10     A   hello  
======= ===== ========


julia> ts |> drop_repeated |> pretty_print
======= ===== ========
  time   tag   value  
======= ===== ========
     1     A       1  
     2     B     foo  
     3     B     bar  
     4     A   123.4  
    10     A   hello  
======= ===== ========


julia> ts |> split .|> pretty_print
======= ===== ========
  time   tag   value  
======= ===== ========
     1     A       1  
     4     A   123.4  
    10     A   hello  
======= ===== ========
======= ===== ========
  time   tag   value  
======= ===== ========
     2     B     foo  
     3     B     bar  
     6     B     bar
======= ===== ========


julia> ts2 |> drop_repeated |> merge_tags |> pretty_print
======= ========== ==================
  time        tag             value  
======= ========== ==================
     1   (:A, :B)      (1, nothing)  
     2   (:A, :B)         (1, :foo)  
     3   (:A, :B)         (1, :bar)  
     4   (:A, :B)     (123.4, :bar)  
    10   (:A, :B)   ("hello", :bar)  
======= ========== ==================

```

## Install

```julia
julia> ]
pkg> add "https://github.com/jonalm/EventTimeSeries.jl.git"
```
