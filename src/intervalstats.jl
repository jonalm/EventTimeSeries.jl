using Statistics

struct Interval{T}
    previous::Union{Event{T}, Nothing}
    main::Event{T}
    next::Event{T}
end
duration(I::Interval) = I.next.time - I.main.time

intervals(ts::EventTS) =  (Interval(i==1 ? nothing : ts[i-1], ts[i], ts[i+1]) for i in 1:(length(ts)-1))
intervals(ts::EventTS, value) = (Interval(i==1 ? nothing : ts[i-1], ts[i], ts[i+1]) for i in 1:(length(ts)-1) if ts[i].val == value)

previous_current_next_value(I::Interval) = (I.previous == nothing ? nothing : I.previous.val, I.main.val, I.next.val)

function interval_duration_stats(ts, val; groupby=previous_current_next_value)
    groups = Dict()
    for I in intervals(ts, val)
        k,v = groupby(I), duration(I)
        if haskey(groups,k)
            push!(groups[k],v)
        else
            groups[k]=[v]
        end
    end
    Dict(k=>(count=length(v), duration_mean=mean(v), duration_std=std(v, corrected=false)) for (k,v) in groups)
end
