module EventTimeSeries

export Event,
       EventTS,
       duration,
       events,
       timestamps,
       values,
       tags,
       drop_repeated,
       fill_forward_group_tags,
       split_tags


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
### Single Event
###

struct Event{S, T, U}
    timestamp::S
    tag::T
    value::U
end

Base.show(io::IO, e::Event) = print(io, "time: $(e.timestamp), tag: $(e.tag), val: $(e.value)")


###
### Event Time Series
###

struct EventTS{V}
    series::V
    function EventTS(series::V; validate=true) where {V}
        if validate
            timestamps = getfield.(series, :timestamp)
            @assert issorted(timestamps)
            eltypes = typeof.(series)
            @assert all(hasfield.(eltypes, :value))
            @assert all(hasfield.(eltypes, :tag))
        end
        new{V}(series)
    end
end

EventTS(timestamps, tags, values) = EventTS([Event(ts, tag, v) for (ts, tag, v) in zip(timestamps, tags, values)])
EventTS(timestamps, values; tag)  = EventTS([Event(ts, tag, v) for (ts, v) in zip(timestamps, values)])

Base.IndexStyle(::EventTS)             = LinearIndices()
Base.length(ts::EventTS)               = length(ts.series)
Base.setindex!(ts::EventTS, v, i)      = setindex!(ts.series, v, i)
Base.getindex(ts::EventTS, i::Integer) = getindex(ts.series, i)
Base.getindex(ts::EventTS, i)          = EventTS(getindex(ts.series, i))
Base.iterate(ts::EventTS, el)          = iterate(ts.series, el)
Base.filter(f, ts::EventTS)            = filter(f, ts.series)

function Base.merge(ts1::EventTS, ts2::EventTS)
    merged = vcat(ts1.series, ts2.series)
    sort!(merged, by=x->x.timestamp)
    EventTS(merged, validate=false)
end

events(ts::EventTS)     = (e for e in ts.series)
timestamps(ts::EventTS) = (e.timestamp for e in events(ts))
tags(ts::EventTS)       = (e.tag for e in events(ts))
values(ts::EventTS)     = (e.value for e in events(ts))
duration(ts::EventTS)   = ts.series.timestamps[end] - ts.series.timestamps[1]

function drop_repeated(ts::EventTS, keep_tail=true)
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

split_tags(ts::EventTS) = (t => filter(x->x.tag==t, ts) for t in unique(tags(ts)))



end
