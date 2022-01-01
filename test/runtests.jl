import TelegramClient as TG
import JSON3
using Test


@testset "client basic" begin
    TG.Client() do client
        @test TG.is_created(client)
        @test !TG.is_ready(client)
        @test TG.execute_method(client, :getLogVerbosityLevel)["@type"] == "logVerbosityLevel"
        @test TG.execute_method(client, :setLogVerbosityLevel, new_verbosity_level=1)["@type"] == "ok"
        @test TG.execute_method(client, :getLogVerbosityLevel)["verbosity_level"] == 1
        @test TG.receive(client, timeout=1)["@type"] == "updateOption"
        @test !TG.is_ready(client)
    end
end

@testset "client destroy" begin
    client = TG.Client()
    @test TG.is_created(client)
    TG.destroy(client)
    @test !TG.is_created(client)
    TG.destroy(client)
    TG.destroy(client)
    TG.destroy(client)
    TG.destroy(client)
    @test !TG.is_created(client)
end

@testset "real login" begin
    auth_file = joinpath(@__DIR__, "auth_params.json")
    if isfile(auth_file)
        params = JSON3.read(read(auth_file, String), TG.AuthParameters)
        client = TG.Client()
        while !TG.is_ready(client)
            TG.handle_conn_step(client, params, TG.receive(client, timeout=10))
        end
        @test TG.is_ready(client)
    end
end

import CompatHelperLocal as CHL
CHL.@check()
