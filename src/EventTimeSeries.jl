module EventTimeSeries

using Base.Iterators: flatten, repeated

export
    # types
    Event,
    EventTS,
    # EventTS methods
    duration,
    rows,
    timestamps,
    tags,
    values,
    drop_repeated,
    split,
    merge,
    fill_forward_group_tags


###
### Helpers
###

"""
    neighbors(iterator)

returns an iterator over neighboring pairs

```julia
julia> neighbors([1,2,3]) |> collect
2-element Array{Tuple{Int64,Int64},1}:
 (1, 2)
 (2, 3)
 ```
 """
function neighbors(iterator)
    first  = @view iterator[1:end-1]
    second = @view iterator[2:end]
    zip(first, second)
end


###
### Tag
###

abstract type TagType end
struct SeriesTag <: TagType end
struct EventTag <: TagType end

for T in [Symbol, Char, String, Tuple, NamedTuple, Number]
    @eval tagtype(::$T) = EventTag()
end

for T in [AbstractVector, AbstractRange]
    @eval tagtype(::$T) = SeriesTag()
end

tagtype(v::T) where {T} = @error """
In order to use $v as a tag, define the 'tagtype' trait:
'EventTimeSeries.tagtype(::$T) = EventTag()' or
'EventTimeSeries.tagtype(::$T) = SeriesTag()'
"""


###
### Event
###

struct Event{T, V}
    timestamp::T
    value::V
end

Base.show(io::IO, e::Event) = print(io, "time: $(e.timestamp), val: $(e.value)")


###
### Event Time Series
###

struct EventTS{T, V, U}
    series::Vector{Event{T, V}}
    tag::U
    function EventTS(series::Vector{Event{T, V}}, tag::U) where {T, V, U}
        validate_tag && _validate_tag(series, tag)
        new{T, V, U}(series, tag)
    end
end

_validate_tag(series, tag) = validate_tag(series, tag, tagtype(tag))
_validate_tag(series, tag, ::EventTag) = nothing
function _validate_tag(series, tag, ::SeriesTag)
    @assert length(series) == length(tag)
    @assert tagtype(eltype(tag)) == EventTag
end

function EventTS(;timestamps, values, tag)
    @assert issorted(timestamps)
    @assert length(timestamps) == length(values)
    series = [Event(ts, v) for (ts, v) in zip(timestamps, values)]
    _validate_tag(series, tag)
    EventTS(series, tag)
end

tagtype(s::EventTS) = tagtype(s.tag)
rows(ts::EventTS) = @inbounds (ts[i] for i in 1:length(ts))
timestamps(ts::EventTS) = (e.time for e in rows(ts))
tags(ts::EventTS) = tags(ts::EventTS, tagtype(ts))
tags(ts::EventTS, ::EventTag) = repeated(ts.tag, length(ts))
tags(ts::EventTS, ::SeriesTag) = ts.tag
values(ts::EventTS) = (e.val for e in rows(ts))
duration(ts::EventTS) =  ts.series.timestamps[end] - ts.series.timestamps[1]

Base.IndexStyle(::EventTS) = LinearIndices()
Base.length(ts::EventTS) = length(ts.series)
Base.getindex(ts::EventTS, i) = _getindex(ts.series, i, tagtype(ts))

# returns a new EventTS containing subset of values defined by s
_getindex(ts::EventTS, s, ::EventTag) = EventTS(ts.tag, ts.series[s])
_getindex(ts::EventTS, s, ::SeriesTag) = EventTS(ts.tag[s], ts.series[s])

# return a single (timestamp, tag, value) triple
function _getindex(ts::EventTS, i::Integer, ::EventTag)
    (time=ts.series[i].timestamp, tag=ts.tag, val=ts.series[i].value)
end

function _getindex(ts::EventTS, i::Integer, ::SeriesTag)
    (time=ts.series[i].timestamp, tag=ts.tag[i], val=ts.series[i].value)
end

# timestamps must have equal types
function Base.merge(ts1::EventTS{T}, ts2::EventTS{T}) where {T}
    _merge(ts1, tagtype(ts1), ts2, tagtype(ts2))
end

function _series_sortperm(ts1, ts2)
    series = flatten((ts1.series, ts2.series)) |> collect
    series, sortperm(series, by=x->x.timestamp)
end

function _merge(ts1, ::EventTag, ts2, ::EventTag)
    series, perm = _series_sortperm(ts1, ts2)
    if ts1.tag == ts2.tag
        return EventTs(series[perm], t1)
    else
        tag = flatten((repeated(ts1.tag, length(t1)), repeated(ts2.tag, length(t2))))
        return  EventTs(series[perm], tag[perm])
    end
end

_merge(ts1, ::EventTag, tag2::SeriesTag) = _merge(ts2, tagtype(ts2), ts1, tagtype(ts1))
function _merge(ts1, ::SeriesTag, ts2, ::EventTag)
    series, perm = _series_sortperm(ts1, ts2)
    tag = flatten()
end

function Base.merge(ts1::EventTS{T}, ts2::EventTS{T}) where {T}
    series, perm = _series_sortperm(ts1, ts2)
end

_merge()


drop_repeated(ts::EventTS; kwargs...) = drop_repeated(ts, tagtype(ts); kwargs...)

function drop_repeated(ts::EventTS, ::TSingle; keep_tail=true)
    keep = BitVector(undef, length(ts))
    fill!(keep, false)

    tags_ = tags(ts) |> collect
    vals_ = values(ts) |> collect
    indices = 1:length(ts)

    for tag in unique(tags_)
        tag_indices = indices[tags_ .== tag]
        keep_indices = [
            tag_indices[1];
            [j for (i,j) in neighbors(tag_indices) if vals_[i]!=vals_[j]]
        ]
        keep[keep_indices] .= true
    end
    keep_tail && (keep[end] = true)
    ts[keep]
end

function _next_grouped_value!(tag, value, unique_tags, previous_vals)
    idx = findfirst(t->t==tag, unique_tags)
    out = Tuple(tag==t ? value : previous_vals[i]  for (i,t) in enumerate(unique_tags))
    previous_vals[idx] = value
    out
end

function fill_forward_group_tags(ts::EventTS; skip_initial_missing=false)
    unique_tags = Tuple(sort(unique(tags(ts))))
    previous_vals = Any[missing for _ in unique_tags]

    grouped = (
        Event(e.timestamp,
              unique_tags,
              _next_grouped_value!(e.tag, e.value, unique_tags, previous_vals))
        for e in events(ts)
    )

    out = [g for g in grouped if ~(any(ismissing.(g.value)) && skip_initial_missing)]
    EventTS(out, validate=false)
end

#split_tags(ts::EventTS) = (t => filter(x->x.tag==t, ts) for t in unique(tags(ts)))



end
