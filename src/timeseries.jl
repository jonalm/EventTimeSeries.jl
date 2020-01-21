using Base.Iterators: flatten, repeated
using PrettyTables: pretty_table, simple

struct Event{T, U, V}
    time::T
    tag::U
    val::V
end

Base.show(io::IO, e::Event) = print(io, "time: $(e.time),\ttag:$(e.tag),\tvalue:$(e.val)")

struct SkipValidation end # indicates no validation of data in EventTS constructor

struct EventTS{T, U, V} <: AbstractVector{Event{T}}
    timestamps::Vector{T}
    tag::U
    values::V
    function EventTS(timestamps::Vector{T}, tag::U, values::V, ::SkipValidation) where {T, U, V}
        new{T,U,V}(timestamps, tag, values)
    end
end

function EventTS(;timestamps, tag, values)
    @assert issorted(timestamps)
    @assert length(timestamps) == length(values)
    _validate_tag(timestamps, tag)
    EventTS(timestamps, tag, values, SkipValidation())
end

_validate_tag(timestamps, tag) = _validate_tag(timestamps, tag, tagtype(tag))
_validate_tag(timestamps, tag, ::EventTag) = nothing
function _validate_tag(timestamps, tag, ::SeriesTag)
    @assert length(timestamps) == length(tag)
    @assert tagtype(first(tag)) == EventTag()
end

timestamps(ts::EventTS) = (e.time for e in ts)
timestamps(ts::EventTS, tag) = (e.time for e in ts if e.tag==tag)

Base.values(ts::EventTS) = (e.val for e in ts)
Base.values(ts::EventTS, tag) = (e.val for e in ts if e.tag==tag)

tag(ts::EventTS) = ts.tag
tags(ts::EventTS) = _tags(ts::EventTS, tagtype(ts))
_tags(ts::EventTS, ::EventTag) = repeated(ts.tag, length(ts))
_tags(ts::EventTS, ::SeriesTag) = ts.tag

tagtype(s::EventTS) = tagtype(s.tag)
duration(ts::EventTS) =  ts.timestamps[end] - ts.timestamps[1]

function _2matrix(ts::EventTS)
    mat = Matrix{Any}(undef, length(ts), 3)
    mat[:,1] .= timestamps(ts)
    mat[:,2] .= tags(ts)
    mat[:,3] .= ts.values
    mat
end

pretty_print(ts::EventTS) = pretty_table(_2matrix(ts), [:time, :tag, :value]; tf=simple)

###
### Abstract array Interface
###

Base.IndexStyle(::EventTS) = IndexLinear()
Base.size(ts::EventTS) = size(ts.timestamps)
Base.setindex!(::EventTS, v, i) = @error "EventTS does not support set_index!"
Base.getindex(ts::EventTS, I) = _getindex(ts, I, tagtype(ts))

function _getindex(ts::EventTS, s, ::EventTag)
    EventTS(ts.timestamps[s], ts.tag, ts.values[s], SkipValidation())
end
function _getindex(ts::EventTS, s, ::SeriesTag)
    EventTS(ts.timestamps[s], ts.tag[s], ts.values[s], SkipValidation())
end
function _getindex(ts::EventTS, i::Integer, ::EventTag)
    Event(ts.timestamps[i], ts.tag, ts.values[i])
end
function _getindex(ts::EventTS, i::Integer, ::SeriesTag)
    Event(ts.timestamps[i], ts.tag[i], ts.values[i])
end


splice(ts::EventTS{T}...) where {T} = foldl(_splice, ts)

function _timestamps_values_sortperm(ts1, ts2)
    timestamps = flatten((ts1.timestamps, ts2.timestamps)) |> collect
    values = flatten((ts1.values, ts2.values)) |> collect
    perm = sortperm(timestamps)
    timestamps[perm], values[perm], perm
end

_splice(ts1::EventTS, ts2::EventTS) = _splice(ts1, tagtype(ts1), ts2, tagtype(ts2))
function _splice(ts1, ::EventTag, ts2, ::EventTag)
    timestamps, values, perm = _timestamps_values_sortperm(ts1, ts2)
    if ts1.tag == ts2.tag
        return EventTS(timestamps, ts1.tag, values, SkipValidation())
    else
        tag = flatten((repeated(ts1.tag, length(ts1)), repeated(ts2.tag, length(ts2)))) |> collect
        return EventTS(timestamps, tag[perm], values, SkipValidation())
    end
end
_splice(ts1, ::EventTag, ts2, ::SeriesTag) = _splice(ts2, tagtype(ts2), ts1, tagtype(ts1))
function _splice(ts1, ::SeriesTag, ts2, ::EventTag)
    timestamps, values, perm = _timestamps_values_sortperm(ts1, ts2)
    tag2 = repeated(ts2.tag, length(ts2)) |> collect
    tag = [ts1.tag; tag2]
    EventTS(timestamps, tag[perm], values, SkipValidation())
end
function _splice(ts1, ::SeriesTag, ts2, ::SeriesTag)
    timestamps, values, perm = _timestamps_values_sortperm(ts1, ts2)
    tag = vcat(ts1.tag, ts2.tag)
    EventTS(timestamps, tag[perm], values, SkipValidation())
end

Base.split(ts::EventTS) = split(ts, tagtype(ts))
Base.split(ts::EventTS, ::EventTag) = [ts,]
function Base.split(ts::EventTS, ::SeriesTag)
    tags_ =  tags(ts) |> unique |> sort
    [EventTS(timestamps(ts, t) |> collect, t,
             values(ts,t) |> collect, SkipValidation()) for t in tags_]
end

drop_repeated(ts::EventTS; keep_end=true) = drop_repeated(ts, tagtype(ts), keep_end=keep_end)
function drop_repeated(ts::EventTS, ::SeriesTag; keep_end)
    splice([drop_repeated(ts_, keep_end=keep_end && tag(ts_)==ts.tag[end])
           for ts_ in split(ts)]...)
end
function drop_repeated(ts::EventTS, ::EventTag; keep_end)
    select = [true; [a!=b for (a,b) in neighbors(ts.values)]]
    keep_end && (select[end] = true)
    EventTS(ts.timestamps[select], ts.tag, ts.values[select], SkipValidation())
end

function _combined_val(tag, val, utags, vals)
    idx = searchsortedfirst(utags, tag)
    out = Tuple(i==idx ? val : v for (i,v) in enumerate(vals))
    vals[idx] = val
    out
end

merge_tags(ts::EventTS) = merge_tags(ts, tagtype(ts))

merge_tags(ts::EventTS, ::EventTag) = ts
function merge_tags(ts::EventTS, ::SeriesTag)
    utags =  tags(ts) |> unique |> sort
    vals = Any[nothing for i in  1:length(utags)]
    values = [_combined_val(t, v, utags, vals) for (t,v) in zip(ts.tag, ts.values)]
    EventTS(ts.timestamps, Tuple(utags), values, SkipValidation())
end
