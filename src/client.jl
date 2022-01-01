import TDLib_jll: libtdjson
import JSON3
import StructTypes

""" TDLib settings. They are sent to the library as-is. """
Base.@kwdef struct Settings
    database_directory::String = "tdlib"
    use_file_database::Bool = false
    use_chat_info_database::Bool = false
    use_message_database::Bool = false
    enable_storage_optimizer::Bool = true
    use_secret_chats::Bool = false
    system_language_code::String = "en"
    device_model::String = "Desktop"
    system_version::String = "Linux"
    application_version::String = "1.0"
end
Base.Dict(s::Settings) = Dict(k => getfield(s, k) for k in fieldnames(Settings))

""" TDLib authentication parameters.

Obtain the API ID and hash from Telegram, and put it here together with your account phone number. """
Base.@kwdef struct AuthParameters
    api_id::Int
    api_hash::String
    phone_number::String
    encryption_key::String = ""
    get_authentication_code::Function = () -> Base.prompt("Authentication code")
    get_password::Function = () -> Base.prompt("Password")
end
StructTypes.StructType(::Type{AuthParameters}) = StructTypes.DictType()
StructTypes.construct(::Type{AuthParameters}, x::Dict) = AuthParameters(; (k => v for (k, v) in x)...)


""" Telegram client struct.

Contains TDLib settings, authentication parameters, and its current state. """
Base.@kwdef mutable struct Client
    settings::Settings = Settings()
    auth_parameters::AuthParameters
    tdlib_id::Int = @ccall libtdjson.td_create_client_id()::Int32
    is_authorized::Bool = false
    is_connected::Bool = false
    last_state::Union{Nothing,String} = nothing
end

function Client(f::Function, args...; kwargs...)
    client = Client(args...; kwargs...)
    f(client)
end

""" Returns whether the client is ready to use: connected and authorized. """
is_ready(client::Client) = client.is_authorized && client.is_connected

Base.@kwdef struct TDError <: Exception
    desc::String
    data::Any
end
