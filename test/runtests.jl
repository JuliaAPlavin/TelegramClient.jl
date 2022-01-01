import TelegramClient as TG
import JSON3
using Test

# using Logging; ConsoleLogger(stdout, Logging.Debug) |> global_logger

auth_params_empty = TG.AuthParameters(api_id=0, api_hash="", phone_number="")

@testset "client basic" begin
    @test TG.execute_method(:getLogVerbosityLevel)["@type"] == "logVerbosityLevel"
    @test TG.execute_method(:setLogVerbosityLevel, new_verbosity_level=1)["@type"] == "ok"
    @test TG.execute_method(:getLogVerbosityLevel)["verbosity_level"] == 1
    TG.Client(auth_parameters=auth_params_empty) do client
        @test !TG.is_ready(client)
        TG.send_method(client, :getOption, name="version")
        @test TG.receive(client, timeout=1)["name"] == "version"
        @test TG.receive(timeout=1)["@type"] == "updateAuthorizationState"
        @test !TG.is_ready(client)
    end
end

@testset "real login" begin
    auth_file = joinpath(@__DIR__, "auth_params.json")
    if isfile(auth_file)
        params = JSON3.read(read(auth_file, String), TG.AuthParameters)
        TG.Client(auth_parameters=params) do client
            TG.send_method(client, :getAuthorizationState)
            while !TG.is_ready(client)
                TG.handle_conn_step(client, TG.receive(client, timeout=1))
            end
            @test TG.is_ready(client)
        end
    else
        @info """For testing real log in, create a JSON file "auth_params.json" in the test folder and fill it with your details:
        {
            "api_id": ***,
            "api_hash": "***",
            "phone_number": "***"
        }"""
    end
end

import CompatHelperLocal as CHL
CHL.@check()
