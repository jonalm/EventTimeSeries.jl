
module EventTimeSeries

using Base.Iterators: flatten, repeated

using PrettyTables: pretty_table, simple

export
    # types
    Event,
    EventTS,
    # extract
    timestamps,
    tags,
    values,
    # combine
    split,
    splice,
    merge_tags,
    drop_repeated,
    pretty_print

include("helpers.jl")
include("tagtype.jl")
include("timeseries.jl")

end
