
[![Build Status](https://travis-ci.com/jonalm/EventTimeSeries.jl.svg?branch=master)](https://travis-ci.com/jonalm/EventTimeSeries.jl)


# EventTimeSeries.jl

Implements some functionality to handle event time series where each row/entry conforms to a triplet which consist of a timestamp, a tag and a value.

Contains partly overlapping functionality with [TimeSeries.jl](https://github.com/JuliaStats/TimeSeries.jl).

The package exports the type `EventTS`, which holds the time series. It should be constructed by named arguments `EventTS(;timestamps, tag, values)` where
 - The `timestamps` must be sorted and contain the same number of elements as `values`.
- The tag need to have a `tagtype(tag)` trait.

If `tagtype(tag) == EventTag` then `tag` is unique and applied to each entry in the series.

If `tagtype(tag) == SeriesTag` and `tagtype(eltype(tag)) == EventTag`, then `tag` holds a (potentially different) tag for each entry in the series.

By default `tagtype(tag::T) == SeriesTag()` if `T<:AbstractVector` or `T<:AbstractRange`, and `tagtype(tag::T) == EventTag()` for when `T` is any of `Symbol, Char, String, Tuple, NamedTuple, Number`.

`tagtype(ts::EventTS)` returns the tagtype of the tag used to construct the time series.

## Main functionality

`merge(ts::EventTS...)` splices together an arbitrary number of `EventTS` and returns a single `EventTS` where all entries are sorted with respect to timestamps.

`split(ts::EventTS)` splits the timeseries and returns an array of `EventTS`, where each `EventTS` element has a unique tag.

`drop_repeated(ts::EventTS; keep_end=true)` returns an `EventTS`, where entries of (`timestamp, tag, value`) are dropped if the it contains a repeating  `value` for a given `tag`. If `keep_end=true` then the entry with the largest timestamp is kept regardless.

`fill_forward(ts::EventTS)` returns a new `EventTS`. If `tagtype(ts)==EventTag()` it simply returns `ts`. If `tagtype(ts)==SeriesTag()` then the returned time series has:
- One entry for each timestamp in the input.
- Each value contains a tuple of values for each tag in the input. Values for each tag are filled forward.
- The tag is a sorted tuple of all unqiue tags in the input series.




## Install

```
julia> ]
pkg> add "https://github.com/jonalm/EventTimeSeries.jl.git"
```

## Todo

- implement `Table.jl` interface
- implement `TableTraits.jl` interface
