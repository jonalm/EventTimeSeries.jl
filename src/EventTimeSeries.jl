
module EventTimeSeries

using Base.Iterators: flatten, repeated

using PrettyTables: pretty_table, simple

export
    # types
    Event,
    EventTS,
    # EventTS methods
    duration,
    rows,
    timestamps,
    tags,
    split,
    merge_tags,
    drop_repeated,
    pretty_print


include("helpers.jl")
include("tagtype.jl")
include("timeseries.jl")

end
