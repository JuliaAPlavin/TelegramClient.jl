handle_conn_auth_step(client::Client, evt::Nothing) = nothing

function handle_conn_auth_step(client::Client, evt)
    type = evt["@type"]
    if type == "ok"
        client.last_state = "$(client.last_state): ok"
    elseif type == "updateConnectionState"
        typ = evt["state"]["@type"]
        if typ == "connectionStateConnecting"
            client.is_connected = false
        elseif typ == "connectionStateUpdating"
            client.is_connected = false
        elseif typ == "connectionStateReady"
            client.is_connected = true
        else
            error("Unsupported connection state received: $typ")
        end
        client.last_state = typ
    elseif type == "updateAuthorizationState"
        typ = evt["authorization_state"]["@type"]
        if typ == "authorizationStateClosed"
            client.is_authorized = false
        elseif typ == "authorizationStateReady"
            client.is_authorized = true
        elseif typ == "authorizationStateWaitTdlibParameters"
            send_method(
                client,
                :setTdlibParameters,
                parameters=merge(
                    Dict(client.settings),
                    Dict("api_id" => client.auth_parameters.api_id, "api_hash" => client.auth_parameters.api_hash),
                )
            )
        elseif typ == "authorizationStateWaitEncryptionKey"
            send_method(client, :checkDatabaseEncryptionKey, key=client.auth_parameters.encryption_key)
        elseif typ == "authorizationStateWaitPhoneNumber"
            send_method(client, :setAuthenticationPhoneNumber, phone_number=client.auth_parameters.phone_number)
        elseif typ == "authorizationStateWaitCode"
            send_method(client, :checkAuthenticationCode, code=client.auth_parameters.get_authentication_code())
        elseif typ == "authorizationStateWaitPassword"
            send_method(client, :checkAuthenticationPassword, password=client.auth_parameters.get_password())
        else
            error("Unsupported authorization state received: $typ")
        end
        client.last_state = typ
    end
end

function connect_authorize(client; timeout_each)
    events = []
    send_method(client, :getAuthorizationState)
    while !is_ready(client)
        evt = receive(client, timeout=timeout_each)
        push!(events, evt)
        handle_conn_auth_step(client, evt)
    end
    return events
end
