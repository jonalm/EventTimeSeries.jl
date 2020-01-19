
struct Event{T, V}
    timestamp::T
    value::V
end

Base.show(io::IO, e::Event) = print(io, "time: $(e.timestamp), val: $(e.value)")
