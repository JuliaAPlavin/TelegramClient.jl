
<a id='Overview'></a>

<a id='Overview-1'></a>

# Overview


Julia wrapper for the Telegram library [TDLib](https://core.telegram.org/tdlib):


> TDLib (Telegram Database Library) is a cross-platform, fully functional Telegram client. We designed it to help third-party developers create their own custom apps using the Telegram platform.



Relies on `TDLib_jll` package to provide TDLib binaries.


<a id='Usage'></a>

<a id='Usage-1'></a>

# Usage


```julia-repl
julia> cd(joinpath(@__DIR__, "../test/")) # assuming tdlib already run in test dir, it won't ask for auth code again
```


`TelegramClient.jl` doesn't export anything, so simply import the package and use qualified function names:


```julia-repl
julia> import TelegramClient as TG
```


Some methods can be executed without even creating a `Client`:


```julia-repl
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


```julia-repl
julia> import JSON3

julia> auth_file = "auth_params.json";

julia> auth_parameters = JSON3.read(read(auth_file, String), TG.AuthParameters);
```


Create a client with these auth parameters:


```julia-repl
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


```julia-repl
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


```julia-repl
julia> TG.send_method(tg, :getOption, name="version")
```


and receive its result:


```julia-repl
julia> TG.receive(tg, timeout=1) |> copy
Dict{Symbol, Any} with 4 entries:
  :value               => Dict{Symbol, Any}(:value=>"1.7.4", Symbol("@type")=>"…
  :name                => "version"
  Symbol("@client_id") => 1
  Symbol("@type")      => "updateOption"
```


Timeouts are always specified in seconds.


The created `Client` is not ready to use yet:


```julia-repl
julia> TG.is_ready(tg)
false
```


Having created a `Client`, perform its connection and authorization workflow:


```julia-repl
julia> TG.connect_authorize(tg, timeout_each=1);
```


This may ask for the authentication code if connecting for the first time. By default, the code is asked interactively via `Base.prompt()`. This can be changed in an  `AuthParameters` field: `AuthParameters(..., get_authentication_code=() -> Base.prompt("Authentication code"))`.


The client is finally ready:


```julia-repl
julia> TG.is_ready(tg)
true
```


Now, one can call any API methods with `send`, `send_method`, `execute`, `execute_method`, and receive responses or updates with `receive`.


```julia-repl
julia> cd(joinpath(@__DIR__, "../docs/")) # restore current dir
```


<a id='Reference'></a>

<a id='Reference-1'></a>

# Reference

<a id='TelegramClient.connect_authorize-Tuple{Any}' href='#TelegramClient.connect_authorize-Tuple{Any}'>#</a>
**`TelegramClient.connect_authorize`** &mdash; *Method*.



```julia
connect_authorize(client::Any; timeout_each)

```

Perform the TDLib connection and authorization sequence.

`client` must contain valid authorization parameters. `timeout_each` is the timeout for each internal `receive` call. Returns all events received in the process, in case they are useful for the application.


<a target='_blank' href='https://github.com/aplavin/TelegramClient.jl/blob/b677a4debe657ce6b14cced0ba37062093ba5898/src/connect_auth.jl#L49' class='documenter-source'>source</a><br>

<a id='TelegramClient.execute-Tuple{Dict}' href='#TelegramClient.execute-Tuple{Dict}'>#</a>
**`TelegramClient.execute`** &mdash; *Method*.



```julia
execute(query::Dict) -> JSON3.Object

```

Call TDLib `execute` function, converting the input to JSON and the result from JSON. 


<a target='_blank' href='https://github.com/aplavin/TelegramClient.jl/blob/b677a4debe657ce6b14cced0ba37062093ba5898/src/api_raw.jl#L1' class='documenter-source'>source</a><br>

<a id='TelegramClient.execute_method-Tuple{Symbol, Dict}' href='#TelegramClient.execute_method-Tuple{Symbol, Dict}'>#</a>
**`TelegramClient.execute_method`** &mdash; *Method*.



```julia
execute_method(method::Symbol, params::Dict) -> JSON3.Object

```

Convenience function: calls `execute` with `"@type"=method` added to provided params. 


<a target='_blank' href='https://github.com/aplavin/TelegramClient.jl/blob/b677a4debe657ce6b14cced0ba37062093ba5898/src/api_raw.jl#L50' class='documenter-source'>source</a><br>

<a id='TelegramClient.is_ready-Tuple{TelegramClient.Client}' href='#TelegramClient.is_ready-Tuple{TelegramClient.Client}'>#</a>
**`TelegramClient.is_ready`** &mdash; *Method*.



```julia
is_ready(client::TelegramClient.Client) -> Bool

```

Returns whether the client is ready to use: connected and authorized. 


<a target='_blank' href='https://github.com/aplavin/TelegramClient.jl/blob/b677a4debe657ce6b14cced0ba37062093ba5898/src/client.jl#L52' class='documenter-source'>source</a><br>

<a id='TelegramClient.receive-Tuple{TelegramClient.Client}' href='#TelegramClient.receive-Tuple{TelegramClient.Client}'>#</a>
**`TelegramClient.receive`** &mdash; *Method*.



```julia
receive(client::TelegramClient.Client; kwargs...)

```

Call TDLib `receive` function with the specified `timeout`, converting the result from JSON.

Compared to the `receive()` method, this raises an error when the response doesn't correspond to the provided `client`.


<a target='_blank' href='https://github.com/aplavin/TelegramClient.jl/blob/b677a4debe657ce6b14cced0ba37062093ba5898/src/api_raw.jl#L39' class='documenter-source'>source</a><br>

<a id='TelegramClient.receive-Tuple{}' href='#TelegramClient.receive-Tuple{}'>#</a>
**`TelegramClient.receive`** &mdash; *Method*.



```julia
receive(; timeout)

```

Call TDLib `receive` function with the specified `timeout`, converting the result from JSON.

Note that `receive` may return an event for any `Client`, if multiple are created. Either check this yourself, or use the `receive(client)` method.


<a target='_blank' href='https://github.com/aplavin/TelegramClient.jl/blob/b677a4debe657ce6b14cced0ba37062093ba5898/src/api_raw.jl#L22' class='documenter-source'>source</a><br>

<a id='TelegramClient.send-Tuple{TelegramClient.Client, Dict}' href='#TelegramClient.send-Tuple{TelegramClient.Client, Dict}'>#</a>
**`TelegramClient.send`** &mdash; *Method*.



```julia
send(client::TelegramClient.Client, query::Dict)

```

Call TDLib `send` function, converting the input to JSON. Doesn't return anything. 


<a target='_blank' href='https://github.com/aplavin/TelegramClient.jl/blob/b677a4debe657ce6b14cced0ba37062093ba5898/src/api_raw.jl#L14' class='documenter-source'>source</a><br>

<a id='TelegramClient.send_method-Tuple{TelegramClient.Client, Symbol, Dict}' href='#TelegramClient.send_method-Tuple{TelegramClient.Client, Symbol, Dict}'>#</a>
**`TelegramClient.send_method`** &mdash; *Method*.



```julia
send_method(client::TelegramClient.Client, method::Symbol, params::Dict)

```

Convenience function: calls `send_method` with `"@type"=method` added to provided params. 


<a target='_blank' href='https://github.com/aplavin/TelegramClient.jl/blob/b677a4debe657ce6b14cced0ba37062093ba5898/src/api_raw.jl#L54' class='documenter-source'>source</a><br>

<a id='TelegramClient.AuthParameters' href='#TelegramClient.AuthParameters'>#</a>
**`TelegramClient.AuthParameters`** &mdash; *Type*.



  * `api_id::Int64`
  * `api_hash::String`
  * `phone_number::String`
  * `encryption_key::String`
  * `get_authentication_code::Function`
  * `get_password::Function`

TDLib authentication parameters.

Obtain the API ID and hash from Telegram, and put it here together with your account phone number. 


<a target='_blank' href='https://github.com/aplavin/TelegramClient.jl/blob/b677a4debe657ce6b14cced0ba37062093ba5898/src/client.jl#L20' class='documenter-source'>source</a><br>

<a id='TelegramClient.Client' href='#TelegramClient.Client'>#</a>
**`TelegramClient.Client`** &mdash; *Type*.



  * `settings::TelegramClient.Settings`
  * `auth_parameters::TelegramClient.AuthParameters`
  * `tdlib_id::Int64`
  * `is_authorized::Bool`
  * `is_connected::Bool`
  * `last_state::Union{Nothing, String}`

Telegram client struct.

Contains TDLib settings, authentication parameters, and its current state. 


<a target='_blank' href='https://github.com/aplavin/TelegramClient.jl/blob/b677a4debe657ce6b14cced0ba37062093ba5898/src/client.jl#L35' class='documenter-source'>source</a><br>

<a id='TelegramClient.Settings' href='#TelegramClient.Settings'>#</a>
**`TelegramClient.Settings`** &mdash; *Type*.



  * `database_directory::String`
  * `use_file_database::Bool`
  * `use_chat_info_database::Bool`
  * `use_message_database::Bool`
  * `enable_storage_optimizer::Bool`
  * `use_secret_chats::Bool`
  * `system_language_code::String`
  * `device_model::String`
  * `system_version::String`
  * `application_version::String`

TDLib settings. They are sent to the library as-is. 


<a target='_blank' href='https://github.com/aplavin/TelegramClient.jl/blob/b677a4debe657ce6b14cced0ba37062093ba5898/src/client.jl#L5' class='documenter-source'>source</a><br>

