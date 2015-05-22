local BasePlugin = require "kong.plugins.base_plugin"
local access = require "kong.plugins.sigfapauth.access"

local SigfapAuthHandler = BasePlugin:extend()

function SigfapAuthHandler:new()
  SigfapAuthHandler.super.new(self, "sigfapauth")
end

function SigfapAuthHandler:access(conf)
  SigfapAuthHandler.super.access(self)
  access.execute(conf)
end

SigfapAuthHandler.PRIORITY = 1000

return SigfapAuthHandler
