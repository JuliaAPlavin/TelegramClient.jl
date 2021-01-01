using Setfield

module Internal
import ..Client, ..send_method

struct Event{T}
    data
end

step(::Client, _, ::Event) = nothing
step(c::Client, _, e::Event{:ok}) = c.last_state = "$(c.last_state): ok"

function step(c::Client, params, e::Union{Event{:updateConnectionState},Event{:updateAuthorizationState}})
    typ = e.data[e.data["@type"] == "updateConnectionState" ? "state" : "authorization_state"]["@type"]
    process_connecting(c, params, Event{Symbol(typ)}(e))
    c.last_state = typ
end

process_connecting(c::Client, _, ::Event{:connectionStateConnecting}) = c.is_connected = false
process_connecting(c::Client, _, ::Event{:connectionStateUpdating}) = c.is_connected = false
process_connecting(c::Client, _, ::Event{:connectionStateReady}) = c.is_connected = true

process_connecting(c::Client, _, ::Event{:authorizationStateClosed}) = c.is_authorized = false
process_connecting(c::Client, _, ::Event{:authorizationStateReady}) = c.is_authorized = true
process_connecting(c::Client, params, ::Event{:authorizationStateWaitTdlibParameters}) = send_method(
    c,
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
process_connecting(c::Client, params, ::Event{:authorizationStateWaitEncryptionKey}) = send_method(c, :checkDatabaseEncryptionKey, key="")
process_connecting(c::Client, params, ::Event{:authorizationStateWaitPhoneNumber}) = send_method(c, :setAuthenticationPhoneNumber, phone_number=params.phone_number)
process_connecting(c::Client, params, ::Event{:authorizationStateWaitCode}) = send_method(c, :checkAuthenticationCode, code=Base.prompt("Authentication code"))
process_connecting(c::Client, params, ::Event{:authorizationStateWaitPassword}) = send_method(c, :checkAuthenticationPassword, password=Base.prompt("Password"))

end


Base.@kwdef struct AuthParameters
    api_id::Int
    api_hash::String
    phone_number::String
end
JSON.StructTypes.StructType(::Type{AuthParameters}) = JSON.StructTypes.Struct()

handle_conn_step(client::Client, params::AuthParameters, evt::Nothing) = nothing
handle_conn_step(client::Client, params::AuthParameters, evt) = Internal.step(client, params, Internal.Event{Symbol(evt["@type"])}(evt))

is_ready(client::Client) = client.is_authorized && client.is_connected
