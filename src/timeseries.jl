
struct EventTS{T, V, U}
    series::Vector{Event{T, V}}
    tag::U
    function EventTS(series::Vector{Event{T, V}}, tag::U) where {T, V, U}
        new{T, V, U}(series, tag)
    end
end

function EventTS(;timestamps, values, tag)
    @assert issorted(timestamps)
    @assert length(timestamps) == length(values)
    series = [Event(ts, v) for (ts, v) in zip(timestamps, values)]
    _validate_tag(series, tag)
    EventTS(series, tag)
end

_validate_tag(series, tag) = _validate_tag(series, tag, tagtype(tag))
_validate_tag(series, tag, ::EventTag) = nothing
function _validate_tag(series, tag, ::SeriesTag)
    @assert length(series) == length(tag)
    @assert tagtype(first(tag)) == EventTag()
end





tagtype(s::EventTS) = tagtype(s.tag)
rows(ts::EventTS) = @inbounds (ts[i] for i in 1:length(ts))
timestamps(ts::EventTS) = (e.time for e in rows(ts))
tags(ts::EventTS) = tags(ts::EventTS, tagtype(ts))
tags(ts::EventTS, ::EventTag) = repeated(ts.tag, length(ts))
tags(ts::EventTS, ::SeriesTag) = ts.tag
Base.values(ts::EventTS) = (e.val for e in rows(ts))
duration(ts::EventTS) =  ts.series.timestamps[end] - ts.series.timestamps[1]

Base.IndexStyle(::EventTS) = LinearIndices()
Base.length(ts::EventTS) = length(ts.series)
Base.iterate(ts::EventTS, (el, i)=(ts[1], 0)) = i == length(ts) ? nothing : (el, (ts[i+1], i+1))
Base.getindex(ts::EventTS, i) = _getindex(ts, i, tagtype(ts))

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
        return EventTS(series[perm], ts1.tag)
    else
        tag = flatten((repeated(ts1.tag, length(ts1)), repeated(ts2.tag, length(ts2)))) |> collect
        return  EventTS(series[perm], tag[perm])
    end
end

_merge(ts1, ::EventTag, ts2, ::SeriesTag) = _merge(ts2, tagtype(ts2), ts1, tagtype(ts1))
function _merge(ts1, ::SeriesTag, ts2, ::EventTag)
    series, perm = _series_sortperm(ts1, ts2)
    tag2 = repeated(ts2.tag, length(ts2)) |> collect
    tag = [ts1.tag; tag2]
    EventTS(series[perm], tag[perm])
end

function _merge(ts1, ::SeriesTag, ts2, ::SeriesTag)
    series, perm = _series_sortperm(ts1, ts2)
    tag = vcat(ts1.tag, ts2.tag)
    EventTS(series[perm], tag[perm])
end
