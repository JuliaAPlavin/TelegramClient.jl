import TDLib_jll: libtdjson
import JSON3
import StructTypes


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


Base.@kwdef mutable struct Client
    settings::Settings = Settings()
    auth_parameters::AuthParameters
    tdlib_ptr::Ptr{Cvoid} = (ptr = @ccall libtdjson.td_json_client_create()::Ptr{Cvoid}; @assert ptr != C_NULL; ptr)
    is_authorized::Bool = false
    is_connected::Bool = false
    last_state::Union{Nothing,String} = nothing
end

function Client(f::Function, args...; kwargs...)
    client = Client(args...; kwargs...)
    try
        f(client)
    finally
        destroy(client)
    end
end

is_created(c::Client) = c.tdlib_ptr != C_NULL
is_ready(client::Client) = client.is_authorized && client.is_connected

Base.@kwdef struct TDError <: Exception
    desc::String
    data::Any
end
