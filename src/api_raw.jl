function execute(query::Dict)
    @debug "Executing" query
    query_str = JSON3.write(query)
    res_ptr = @ccall libtdjson.td_execute(query_str::Cstring)::Cstring
    res_ptr == C_NULL && return nothing
    res_str = unsafe_string(res_ptr)
    res = JSON3.read(res_str)
    @debug "Executed" res
    res["@type"] == "error" && throw(TDError("Error $(res["code"]): $(res["message"])", query))
    return res
end

function send(client::Client, query::Dict)
    @debug "Sending" query
    query_str = JSON3.write(query)
    @ccall libtdjson.td_send(client.tdlib_id::Int32, query_str::Cstring)::Cvoid
    @debug "Sent"
end

function receive(; timeout::Real)
    @debug "Receiving" timeout
    res_ptr = @ccall libtdjson.td_receive(timeout::Float64)::Cstring
    if res_ptr == C_NULL
        @debug "Received nothing"
        return nothing
    end
    res_str = unsafe_string(res_ptr)
    res = JSON3.read(res_str)
    @debug "Received" res
    res["@type"] == "error" && throw(TDError("Error $(res["code"]): $(res["message"])", res))
    return res
end

function receive(client::Client; kwargs...)
    res = receive(; kwargs...)
    res["@client_id"] == client.tdlib_id || throw(TDError("Received event for wrong client id: $(res["@client_id"]), expected $(client.id)", res))
    return res
end

execute_method(method::Symbol, params::Dict) = execute(Dict("@type" => method, params...))
execute_method(method::Symbol; params...) = execute_method(method, Dict(params))
send_method(client::Client, method::Symbol, params::Dict) = send(client, Dict("@type" => method, params...))
send_method(client::Client, method::Symbol; params...) = send_method(client, method, Dict(params))
