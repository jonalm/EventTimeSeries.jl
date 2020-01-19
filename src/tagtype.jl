abstract type TagType end
struct SeriesTag <: TagType end
struct EventTag <: TagType end

for T in [Symbol, Char, String, Tuple, NamedTuple, Number]
    @eval tagtype(::$T) = EventTag()
end

for T in [AbstractVector, AbstractRange]
    @eval tagtype(::$T) = SeriesTag()
end

tagtype(v::T) where {T} = @error """
In order to use $v as a tag, define the 'tagtype' trait:
'EventTimeSeries.tagtype(::$T) = EventTag()' or
'EventTimeSeries.tagtype(::$T) = SeriesTag()'
"""
