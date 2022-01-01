handle_conn_step(client::Client, evt::Nothing) = nothing

function handle_conn_step(client::Client, evt)
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
                    "api_id" => client.auth_parameters.api_id,
                    "api_hash" => client.auth_parameters.api_hash,
                    "system_language_code" => "en",
                    "device_model" => "Desktop",
                    "system_version" => "Linux",
                    "application_version" => "1.0",
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
