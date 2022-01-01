import TDLib_jll: libtdjson
import JSON3
import StructTypes


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
    tdlib_ptr::Ptr{Cvoid}
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
