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
        @test timestamps(ts) |> collect == [1,2,3,4]
        @test values(ts) |> collect == [:a,:b,:c,:d]
        @test ts.tag == [:foo,:bar,:foo,:bar]
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
