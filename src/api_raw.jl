""" Call TDLib `execute` function, converting the input to JSON and the result from JSON. """
function execute(query::Dict)::JSON3.Object
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

""" Call TDLib `send` function, converting the input to JSON. Doesn't return anything. """
function send(client::Client, query::Dict)
    @debug "Sending" query
    query_str = JSON3.write(query)
    @ccall libtdjson.td_send(client.tdlib_id::Int32, query_str::Cstring)::Cvoid
    @debug "Sent"
end

""" Call TDLib `receive` function with the specified `timeout`, converting the result from JSON.

Note that `receive` may return an event for any `Client`, if multiple are created. Either check this yourself, or use the `receive(client)` method."""
function receive(; timeout::Real)::JSON3.Object
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

""" Call TDLib `receive` function with the specified `timeout`, converting the result from JSON.

Compared to the `receive()` method, this raises an error when the response doesn't correspond to the provided `client`."""
function receive(client::Client; kwargs...)::JSON3.Object
    res = receive(; kwargs...)
    if !isnothing(res) && res["@client_id"] != client.tdlib_id
        throw(TDError("Received event for wrong client id: $(res["@client_id"]), expected $(client.tdlib_id)", res))
    end
    return res
end

""" Convenience function: calls `execute` with `"@type"=method` added to provided params. """
execute_method(method::Symbol, params::Dict) = execute(Dict("@type" => method, params...))
execute_method(method::Symbol; params...) = execute_method(method, Dict(params))

""" Convenience function: calls `send_method` with `"@type"=method` added to provided params. """
send_method(client::Client, method::Symbol, params::Dict) = send(client, Dict("@type" => method, params...))
send_method(client::Client, method::Symbol; params...) = send_method(client, method, Dict(params))
