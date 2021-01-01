import tdlib_jll: libtdjson
import JSON3 as JSON


Base.@kwdef mutable struct Client
    tdlib_ptr::Ptr{Cvoid}
    is_authorized::Bool = false
    is_connected::Bool = false
    last_state::Union{Nothing,String} = nothing
end

Base.@kwdef struct TDError <: Exception
    desc::String
    data::Any
end

is_created(c::Client) = c.tdlib_ptr != C_NULL

function Client()
    ptr = @ccall libtdjson.td_json_client_create()::Ptr{Cvoid}
    @assert ptr != C_NULL
    return Client(tdlib_ptr=ptr)
end

function Client(f::Function, args...; kwargs...)
    client = Client(args...; kwargs...)
    try
        f(client)
    finally
        destroy(client)
    end
end

function destroy(client::Client)
    @debug "Destroying"
    @ccall libtdjson.td_json_client_destroy(client.tdlib_ptr::Ptr{Cvoid})::Cvoid
    client.tdlib_ptr = C_NULL
end

function execute(client::Client, query::Dict)
    @debug "Executing" query
    query_str = JSON.write(query)
    res_ptr = @ccall libtdjson.td_json_client_execute(client.tdlib_ptr::Ptr{Cvoid}, query_str::Cstring)::Cstring
    res_ptr == C_NULL && return nothing
    res_str = unsafe_string(res_ptr)
    res = JSON.read(res_str)
    @debug "Executed" res
    res["@type"] == "error" && throw(TDError("Error $(res["code"]): $(res["message"])", query))
    return res
end

function send(client::Client, query::Dict)
    @debug "Sending" query
    query_str = JSON.write(query)
    @ccall libtdjson.td_json_client_send(client.tdlib_ptr::Ptr{Cvoid}, query_str::Cstring)::Cvoid
    @debug "Sent"
end

function receive(client::Client; timeout::Real)
    @debug "Receiving" timeout
    res_ptr = @ccall libtdjson.td_json_client_receive(client.tdlib_ptr::Ptr{Cvoid}, timeout::Float64)::Cstring
    if res_ptr == C_NULL
        @info "Received nothing"
        return nothing
    end
    res_str = unsafe_string(res_ptr)
    res = JSON.read(res_str)
    @debug "Received" res
    res["@type"] == "error" && throw(TDError("Error $(res["code"]): $(res["message"])", query))
    return res
end

execute_method(client::Client, method::Symbol, params::Dict) = execute(client, Dict("@type" => method, params...))
execute_method(client::Client, method::Symbol; params...) = execute_method(client, method, Dict(params))
send_method(client::Client, method::Symbol, params::Dict) = send(client, Dict("@type" => method, params...))
send_method(client::Client, method::Symbol; params...) = send_method(client, method, Dict(params))
