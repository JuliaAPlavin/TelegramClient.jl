import TelegramClient as TG
import JSON3
using Test

# using Logging; ConsoleLogger(stdout, Logging.Debug) |> global_logger

auth_file = joinpath(@__DIR__, "auth_params.json")
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
    isfile(auth_file) || @info """For testing real log in, create a JSON file "auth_params.json" in the test folder and fill it with your details:
    {
        "api_id": ***,
        "api_hash": "***",
        "phone_number": "***"
    }"""

    if isfile(auth_file)
        params = JSON3.read(read(auth_file, String), TG.AuthParameters)

        TG.Client(auth_parameters=params) do client
            events = TG.connect_authorize(client, timeout_each=1)
            @test length(events) > 5
            @test TG.is_ready(client)
        end
    end
end

import CompatHelperLocal as CHL
CHL.@check()

# # doctests don't work together with tests above
# using Documenter, DocumenterMarkdown
# makedocs(format=Markdown(), modules=[TG], root="../docs")
# mv("../docs/build/README.md", "../README.md", force=true)
# rm("../docs/build", recursive=true)
