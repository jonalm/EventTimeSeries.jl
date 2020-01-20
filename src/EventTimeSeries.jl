
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
    split,
    drop_repeated,
    fill_forward


include("helpers.jl")
include("tagtype.jl")
include("timeseries.jl")

end
