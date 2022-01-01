using Setfield

Base.@kwdef struct AuthParameters
    api_id::Int
    api_hash::String
    phone_number::String
end
JSON.StructTypes.StructType(::Type{AuthParameters}) = JSON.StructTypes.Struct()

handle_conn_step(client::Client, params::AuthParameters, evt::Nothing) = nothing
function handle_conn_step(client::Client, params::AuthParameters, evt)
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
                parameters=Dict(
                    "database_directory" => "tdlib",
                    "use_file_database" => false,
                    "use_chat_info_database" => false,
                    "use_message_database" => false,
                    "enable_storage_optimizer" => true,
                    "use_secret_chats" => false,
                    "api_id" => params.api_id,
                    "api_hash" => params.api_hash,
                    "system_language_code" => "en",
                    "device_model" => "Desktop",
                    "system_version" => "Linux",
                    "application_version" => "1.0",
                )
            )
        elseif typ == "authorizationStateWaitEncryptionKey"
            send_method(client, :checkDatabaseEncryptionKey, key="")
        elseif typ == "authorizationStateWaitPhoneNumber"
            send_method(client, :setAuthenticationPhoneNumber, phone_number=params.phone_number)
        elseif typ == "authorizationStateWaitCode"
            send_method(client, :checkAuthenticationCode, code=Base.prompt("Authentication code"))
        elseif typ == "authorizationStateWaitPassword"
            send_method(client, :checkAuthenticationPassword, password=Base.prompt("Password"))
        else
            error("Unsupported authorization state received: $typ")
        end
        client.last_state = typ
    end
end

is_ready(client::Client) = client.is_authorized && client.is_connected
