using EventTimeSeries
using Test

@testset "test neighbor iterator" begin
    @test EventTimeSeries.neighbors([1,2,3]) |> collect == [(1, 2), (2, 3)]
end

@testset "test merge of timeseries with unique and equal tags" begin
    t1 = [1,3]
    v1 = [:a,:c]
    t2 = [2,4]
    v2 = [:b,:d]
    tag = :foo

    ts1 = EventTS(timestamps=t1, values=v1, tag=tag)
    ts2 = EventTS(timestamps=t2, values=v2, tag=tag)

    for (a,b) in ((ts1,ts2), (ts2,ts1))
        ts = merge(a, b)
        @test timestamps(ts) |> collect == [1,2,3,4]
        @test values(ts) |> collect == [:a,:b,:c,:d]
        @test ts.tag == tag
    end
end

@testset "test merge of timeseries with unique but unequal tags" begin
    t1 = [1,3]
    v1 = [:a,:c]
    t2 = [2,4]
    v2 = [:b,:d]
    tag1 = :foo
    tag2 = :bar

    ts1 = EventTS(timestamps=t1, values=v1, tag=tag1)
    ts2 = EventTS(timestamps=t2, values=v2, tag=tag2)

    for (a,b) in ((ts1,ts2), (ts2,ts1))
        ts = merge(a, b)
        @test timestamps(ts) |> collect == [1, 2, 3, 4]
        @test values(ts) |> collect == [:a, :b, :c, :d]
        @test ts.tag == [:foo, :bar, :foo, :bar]
    end
end

@testset "test merge of timeseries with both varying tags" begin
    t1 = [1,3]
    v1 = [:a,:c]
    t2 = [2,4]
    v2 = [:b,:d]
    tag1 = [:foo, :bar]
    tag2 = [:foo, :bar]

    ts1 = EventTS(timestamps=t1, values=v1, tag=tag1)
    ts2 = EventTS(timestamps=t2, values=v2, tag=tag2)

    for (a,b) in ((ts1,ts2), (ts2,ts1))
        ts = merge(a, b)
        @test timestamps(ts) |> collect == [1,2,3,4]
        @test values(ts) |> collect == [:a,:b,:c,:d]
        @test ts.tag == [:foo,:foo,:bar,:bar]
    end
end

@testset "test merge of timeseries with unique and varying tag" begin
    t1 = [1,3]
    v1 = [:a,:c]
    t2 = [2,4]
    v2 = [:b,:d]
    tag1 = [:foo, :bar]
    tag2 = :foobar

    ts1 = EventTS(timestamps=t1, values=v1, tag=tag1)
    ts2 = EventTS(timestamps=t2, values=v2, tag=tag2)

    for (a,b) in ((ts1,ts2), (ts2,ts1))
        ts = merge(a, b)
        @test timestamps(ts) |> collect == [1,2,3,4]
        @test values(ts) |> collect == [:a,:b,:c,:d]
        @test ts.tag == [:foo,:foobar,:bar,:foobar]
    end
end

@testset "merge -> split gives back result" begin
    t1 = [1,3]
    v1 = [:a,:c]
    tag1 = :A
    ts1 = EventTS(timestamps=t1, values=v1, tag=tag1)

    t2 = [2,4]
    v2 = [:b,:d]
    tag2 = :B
    ts2 = EventTS(timestamps=t2, values=v2, tag=tag2)

    ts1_, ts2_ = split(merge(ts1, ts2))

    @test ts1.timestamps == ts1_.timestamps
    @test ts1.tag == ts1_.tag
    @test ts1.values == ts1_.values
end

@testset "split -> merge gives back result" begin
    t = [1,2,3,4]
    v = rand(4)
    tag = [:a,:b,:a,:c]
    ts = EventTS(timestamps=t, values=v, tag=tag)
    ts_ = merge(split(ts)...)

    @test ts_.timestamps == ts.timestamps
    @test ts_.tag == ts.tag
    @test ts_.values == ts.values
end


@testset "drop repeated 1" begin
    t1 = 0:2:10 |> collect
    t2 = 1:2:9 |>  collect
    tag = :tagtag
    val1 = 1:length(t1)
    val2 = 1:length(t2)

    ts1 = EventTS(timestamps=t1, values=val1, tag=tag)
    ts2 = EventTS(timestamps=t2, values=val2, tag=tag)
    tsd = drop_repeated(merge(ts1,ts2))

    @test ts1.timestamps == tsd.timestamps
    @test ts1.tag == tsd.tag
    @test ts1.values == tsd.values
end

@testset "drop repeated 2" begin
    time = 1:6 |> collect
    tag = [i==4 ? :foo : :bar for (i,t) in enumerate(time)]
    values = [:a, :b, :b, :b, :d, :d]
    ts = EventTS(timestamps=time, tag=tag, values=values)
    ts1 = drop_repeated(ts) # keep_end true by default
    ts2 = drop_repeated(ts, keep_end=false)

    @test ts1.timestamps == [1,2,4,5,6]
    @test ts1.values == [:a, :b, :b, :d, :d]

    @test ts2.timestamps == [1,2,4,5]
    @test ts2.values == [:a, :b, :b, :d]
end

@testset "merge tags fill forward" begin
    time   = [0, 1, 2, 3, 4, 5]
    tag    = [:A, :A,:B,:A,:B, :B]
    values = time

    ts  = EventTS(timestamps=time, values=values, tag=tag)
    ts_ = merge_tags(ts)

    @test ts_.values == [(0,nothing),
                         (1,nothing),
                         (1,2),
                         (3,2),
                         (3,4),
                         (3,5)]

    @test ts_.tag == (:A, :B)
end
