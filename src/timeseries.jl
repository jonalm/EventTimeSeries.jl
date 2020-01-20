
struct ValidInput end

struct EventTS{T, U, V}
    timestamps::T
    tag::U
    values::V
    function EventTS(timestamps::T, tag::U, values::V, ::ValidInput) where {T, U, V}
        new{T,U,V}(timestamps, tag, values)
    end
end

function EventTS(;timestamps, tag, values)
    @assert issorted(timestamps)
    @assert length(timestamps) == length(values)
    _validate_tag(timestamps, tag)
    EventTS(timestamps, tag, values, ValidInput())
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
timestamps(ts::EventTS, tag) = (e.time for e in rows(ts) if e.tag==tag)

tag(ts::EventTS) = ts.tag

tags(ts::EventTS) = _tags(ts::EventTS, tagtype(ts))

_tags(ts::EventTS, ::EventTag) = repeated(ts.tag, length(ts))
_tags(ts::EventTS, ::SeriesTag) = ts.tag

duration(ts::EventTS) =  ts.series.timestamps[end] - ts.series.timestamps[1]

Base.values(ts::EventTS) = (e.val for e in rows(ts))
Base.values(ts::EventTS, tag) = (e.val for e in rows(ts) if e.tag==tag)

Base.IndexStyle(::EventTS) = LinearIndices()

Base.length(ts::EventTS) = length(ts.timestamps)

function Base.iterate(ts::EventTS, (el, i)=(ts[1], 0))
    i == length(ts) ? nothing : (el, (ts[i+1], i+1))
end

Base.getindex(ts::EventTS, i) = _getindex(ts, i, tagtype(ts))

_getindex(ts::EventTS, s, ::EventTag) = EventTS(ts.timestamps[s], ts.tag, ts.values[s], ValidInput())
_getindex(ts::EventTS, s, ::SeriesTag) = EventTS(ts.timestamps[s], ts.tag[s], ts.values[s], ValidInput())
function _getindex(ts::EventTS, i::Integer, ::EventTag)
    (time=ts.timestamps[i], tag=ts.tag, val=ts.values[i])
end
function _getindex(ts::EventTS, i::Integer, ::SeriesTag)
    (time=ts.timestamps[i], tag=ts.tag[i], val=ts.values[i])
end


Base.merge(ts::EventTS{T}...) where {T} = foldl(_merge, ts)

_merge(ts1::EventTS, ts2::EventTS) = _merge(ts1, tagtype(ts1), ts2, tagtype(ts2))

function _timestamps_values_sortperm(ts1, ts2)
    timestamps = flatten((ts1.timestamps, ts2.timestamps)) |> collect
    values = flatten((ts1.values, ts2.values)) |> collect
    perm = sortperm(timestamps)
    timestamps[perm], values[perm], perm
end

function _merge(ts1, ::EventTag, ts2, ::EventTag)
    timestamps, values, perm = _timestamps_values_sortperm(ts1, ts2)
    if ts1.tag == ts2.tag
        return EventTS(timestamps, ts1.tag, values, ValidInput())
    else
        tag = flatten((repeated(ts1.tag, length(ts1)), repeated(ts2.tag, length(ts2)))) |> collect
        return EventTS(timestamps, tag[perm], values, ValidInput())
    end
end
_merge(ts1, ::EventTag, ts2, ::SeriesTag) = _merge(ts2, tagtype(ts2), ts1, tagtype(ts1))
function _merge(ts1, ::SeriesTag, ts2, ::EventTag)
    timestamps, values, perm = _timestamps_values_sortperm(ts1, ts2)
    tag2 = repeated(ts2.tag, length(ts2)) |> collect
    tag = [ts1.tag; tag2]
    EventTS(timestamps, tag[perm], values, ValidInput())
end
function _merge(ts1, ::SeriesTag, ts2, ::SeriesTag)
    timestamps, values, perm = _timestamps_values_sortperm(ts1, ts2)
    tag = vcat(ts1.tag, ts2.tag)
    EventTS(timestamps, tag[perm], values, ValidInput())
end


Base.split(ts::EventTS) = split(ts, tagtype(ts))
Base.split(ts::EventTS, ::EventTag) = [ts,]
function Base.split(ts::EventTS, ::SeriesTag)
    tags_ =  tags(ts) |> unique |> sort
    [EventTS(timestamps(ts, t) |> collect, t,
             values(ts,t) |> collect, ValidInput()) for t in tags_]
end

drop_repeated(ts::EventTS; keep_end=true) = drop_repeated(ts, tagtype(ts), keep_end=keep_end)
function drop_repeated(ts::EventTS, ::SeriesTag; keep_end)
    merge([drop_repeated(ts_, keep_end=keep_end && tag(ts_)==ts.tag[end])
           for ts_ in split(ts)]...)
end
function drop_repeated(ts::EventTS, ::EventTag; keep_end)
    select = [true; [a!=b for (a,b) in neighbors(ts.values)]]
    keep_end && (select[end] = true)
    EventTS(ts.timestamps[select], ts.tag, ts.values[select], ValidInput())
end
