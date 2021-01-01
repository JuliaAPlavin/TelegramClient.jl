import TelegramClient as TG
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
