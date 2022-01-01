# Overview

Julia wrapper for the Telegram library [TDLib](https://core.telegram.org/tdlib):
> TDLib (Telegram Database Library) is a cross-platform, fully functional Telegram client. We designed it to help third-party developers create their own custom apps using the Telegram platform.

Relies on `TDLib_jll` package to provide TDLib binaries.

# Usage

```jldoctest label
julia> cd(joinpath(@__DIR__, "../test/")) # assuming tdlib already run in test dir, it won't ask for auth code again
```

`TelegramClient.jl` doesn't export anything, so simply import the package and use qualified function names:
```jldoctest label
julia> import TelegramClient as TG
```

Some methods can be executed without even creating a `Client`:
```jldoctest label
julia> TG.execute_method(:setLogVerbosityLevel, new_verbosity_level=0) |> copy
Dict{Symbol, Any} with 1 entry:
  Symbol("@type") => "ok"

julia> TG.execute_method(:getLogVerbosityLevel) |> copy
Dict{Symbol, Any} with 2 entries:
  :verbosity_level => 0
  Symbol("@type")  => "logVerbosityLevel"
```

Authentication parameters can be filled in manually in the `AuthParameters` struct or read from a JSON file:
```json
{
    "api_id": ***,
    "api_hash": "***",
    "phone_number": "***"
}
```
Here, we read it from file:
```jldoctest label
julia> import JSON3

julia> auth_file = "auth_params.json";

julia> auth_parameters = JSON3.read(read(auth_file, String), TG.AuthParameters);
```

Create a client with these auth parameters:
```jldoctest label
julia> tg = TG.Client(; auth_parameters);
```
Alternatively, an auto-closing wrapper is provided:
```julia
julia> TG.Client(; auth_parameters) do tg
           ...
       end
```
Currently, this wrapper does nothing in the end as there are no functions to close the client in the TDLib API. However, this may change in the future.

Settings can be set by passing them to the constructor: `TG.Client(settings=TG.Settings(...))`. Default values:
```jldoctest label
julia> Dict(TG.Settings())
Dict{Symbol, Any} with 10 entries:
  :use_message_database     => false
  :database_directory       => "tdlib"
  :system_version           => "Linux"
  :use_secret_chats         => false
  :use_file_database        => false
  :device_model             => "Desktop"
  :application_version      => "1.0"
  :system_language_code     => "en"
  :use_chat_info_database   => false
  :enable_storage_optimizer => true
```

Now we can call an API method:
```jldoctest label
julia> TG.send_method(tg, :getOption, name="version")
```
and receive its result:
```jldoctest label
julia> TG.receive(tg, timeout=1) |> copy
Dict{Symbol, Any} with 4 entries:
  :value               => Dict{Symbol, Any}(:value=>"1.7.4", Symbol("@type")=>"…
  :name                => "version"
  Symbol("@client_id") => 1
  Symbol("@type")      => "updateOption"
```
Timeouts are always specified in seconds.

The created `Client` is not ready to use yet:
```jldoctest label
julia> TG.is_ready(tg)
false
```
Having created a `Client`, perform its connection and authorization workflow:
```jldoctest label
julia> TG.connect_authorize(tg, timeout_each=1);
```
This may ask for the authentication code if connecting for the first time.
By default, the code is asked interactively via `Base.prompt()`. This can be changed in an  `AuthParameters` field: `AuthParameters(..., get_authentication_code=() -> Base.prompt("Authentication code"))`.

The client is finally ready:
```jldoctest label
julia> TG.is_ready(tg)
true
```

Now, one can call any API methods with `send`, `send_method`, `execute`, `execute_method`, and receive responses or updates with `receive`.

```jldoctest label
julia> cd(joinpath(@__DIR__, "../docs/")) # restore current dir
```

# Reference

```@autodocs
Modules = [TG]
Order   = [:function, :type]
```
