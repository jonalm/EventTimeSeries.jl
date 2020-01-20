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
    split,
    drop_repeated,
    merge




include("helpers.jl")
include("tagtype.jl")
include("timeseries.jl")



# split
# drop merged
# statistics
# fill forward


#drop_repeated(ts::EventTS; kwargs...) = drop_repeated(ts, tagtype(ts); kwargs...)
#
#function drop_repeated(ts::EventTS, ::TSingle; keep_tail=true)
#    keep = BitVector(undef, length(ts))
#    fill!(keep, false)
#
#    tags_ = tags(ts) |> collect
#    vals_ = values(ts) |> collect
#    indices = 1:length(ts)
#
#    for tag in unique(tags_)
#        tag_indices = indices[tags_ .== tag]
#        keep_indices = [
#            tag_indices[1];
#            [j for (i,j) in neighbors(tag_indices) if vals_[i]!=vals_[j]]
#        ]
#        keep[keep_indices] .= true
#    end
#    keep_tail && (keep[end] = true)
#    ts[keep]
#end
#
#function _next_grouped_value!(tag, value, unique_tags, previous_vals)
#    idx = findfirst(t->t==tag, unique_tags)
#    out = Tuple(tag==t ? value : previous_vals[i]  for (i,t) in enumerate(unique_tags))
#    previous_vals[idx] = value
#    out
#end
#
#function fill_forward_group_tags(ts::EventTS; skip_initial_missing=false)
#    unique_tags = Tuple(sort(unique(tags(ts))))
#    previous_vals = Any[missing for _ in unique_tags]
#
#    grouped = (
#        Event(e.timestamp,
#              unique_tags,
#              _next_grouped_value!(e.tag, e.value, unique_tags, previous_vals))
#        for e in events(ts)
#    )
#
#    out = [g for g in grouped if ~(any(ismissing.(g.value)) && skip_initial_missing)]
#    EventTS(out, validate=false)
#end
#
##split_tags(ts::EventTS) = (t => filter(x->x.tag==t, ts) for t in unique(tags(ts)))



end
