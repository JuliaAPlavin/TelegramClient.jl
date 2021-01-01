module TelegramClient

__precompile__(false)  # I override a constructor from Base.@kwdef

include("client_raw.jl")
include("helpers.jl")

end
