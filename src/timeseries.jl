
struct EventTS{T, U, V}
    timestamps::T
    tag::U
    values::V
    #function EventTS(timestamps::T, values::U, tag::V) where {T,U, V}
    #    new{T,U,V}(timestamps, tag, values)
    #end
end

function EventTS(;timestamps, tag, values)
    @assert issorted(timestamps)
    @assert length(timestamps) == length(values)
    _validate_tag(timestamps, tag)
    EventTS(timestamps, tag, values)
end

_validate_tag(timestamps, tag) = _validate_tag(timestamps, tag, tagtype(tag))
_validate_tag(timestamps, tag, ::EventTag) = nothing
function _validate_tag(timestamps, tag, ::SeriesTag)
    @assert length(timestamps) == length(tag)
    @assert tagtype(first(tag)) == EventTag()
end

tagtype(s::EventTS) = tagtype(s.tag)

rows(ts::EventTS) = @inbounds (ts[i] for i in 1:length(ts))

timestamps(ts::EventTS) = (e.time for e in rows(ts))

tags(ts::EventTS) = tags(ts::EventTS, tagtype(ts))
tags(ts::EventTS, ::EventTag) = repeated(ts.tag, length(ts))
tags(ts::EventTS, ::SeriesTag) = ts.tag

duration(ts::EventTS) =  ts.series.timestamps[end] - ts.series.timestamps[1]

Base.values(ts::EventTS) = (e.val for e in rows(ts))

Base.IndexStyle(::EventTS) = LinearIndices()

Base.length(ts::EventTS) = length(ts.timestamps)

function Base.iterate(ts::EventTS, (el, i)=(ts[1], 0))
    i == length(ts) ? nothing : (el, (ts[i+1], i+1))
end

Base.getindex(ts::EventTS, i) = _getindex(ts, i, tagtype(ts))

_getindex(ts::EventTS, s, ::EventTag) = EventTS(ts.timestamps[s], ts.tag, ts.values[s])
_getindex(ts::EventTS, s, ::SeriesTag) = EventTS(ts.timestamps[s], ts.tag[s], ts.values[s])
function _getindex(ts::EventTS, i::Integer, ::EventTag)
    (time=ts.timestamps[i], tag=ts.tag, val=ts.values[i])
end
function _getindex(ts::EventTS, i::Integer, ::SeriesTag)
    (time=ts.timestamps[i], tag=ts.tag[i], val=ts.values[i])
end

function Base.merge(ts1::EventTS{T}, ts2::EventTS{T}) where {T}
    _merge(ts1, tagtype(ts1), ts2, tagtype(ts2))
end

function _timestamps_values_sortperm(ts1, ts2)
    timestamps = flatten((ts1.timestamps, ts2.timestamps)) |> collect
    values = flatten((ts1.values, ts2.values)) |> collect
    perm = sortperm(timestamps)
    timestamps[perm], values[perm], perm
end

function _merge(ts1, ::EventTag, ts2, ::EventTag)
    timestamps, values, perm = _timestamps_values_sortperm(ts1, ts2)
    if ts1.tag == ts2.tag
        return EventTS(timestamps, ts1.tag, values)
    else
        tag = flatten((repeated(ts1.tag, length(ts1)), repeated(ts2.tag, length(ts2)))) |> collect
        return EventTS(timestamps, tag[perm], values)
    end
end
_merge(ts1, ::EventTag, ts2, ::SeriesTag) = _merge(ts2, tagtype(ts2), ts1, tagtype(ts1))
function _merge(ts1, ::SeriesTag, ts2, ::EventTag)
    timestamps, values, perm = _timestamps_values_sortperm(ts1, ts2)
    tag2 = repeated(ts2.tag, length(ts2)) |> collect
    tag = [ts1.tag; tag2]
    EventTS(timestamps, tag[perm], values)
end
function _merge(ts1, ::SeriesTag, ts2, ::SeriesTag)
    timestamps, values, perm = _timestamps_values_sortperm(ts1, ts2)
    tag = vcat(ts1.tag, ts2.tag)
    EventTS(timestamps, tag[perm], values)
end


Base.split(ts::EventTS) = split(ts, tagtype(ts))
Base.split(ts::EventTS, ::EventTag) = [ts,]
function Base.split(ts::EventTS, ::SeriesTag)
    splitseries = Dict{eltype(ts.tag), Any}()

    for i in 1:length(ts)
        tag = ts.tag[i]
        el = ts.series[i]
        if haskey(splitseries, tag)
            push!(splitseries[tag], el)
        else
            splitseries[tag] = [el]
        end
    end
    [EventTS(s, t) for (t,s) in splitseries]
end
