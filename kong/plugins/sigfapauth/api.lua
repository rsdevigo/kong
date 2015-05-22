-- Copyright (C) Mashape, Inc.

local BaseController = require "kong.api.routes.base_controller"

local SigfapAuthCredentials = BaseController:extend()

function SigfapAuthCredentials:new()
  SigfapAuthCredentials.super.new(self, dao.keyauth_credentials, "sigfapauth_credentials")
end

return SigfapAuthCredentials
