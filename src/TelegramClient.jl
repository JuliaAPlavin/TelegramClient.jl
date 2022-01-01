module TelegramClient

using DocStringExtensions
@template (FUNCTIONS, METHODS, MACROS) = """
$(TYPEDSIGNATURES)
$(DOCSTRING)
"""
@template TYPES = """
$(TYPEDFIELDS)
$(DOCSTRING)
"""


include("client.jl")
include("api_raw.jl")
include("connect_auth.jl")

end
