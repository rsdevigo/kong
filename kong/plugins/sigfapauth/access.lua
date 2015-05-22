local cache = require "kong.tools.database_cache"
local stringy = require "stringy"
local Multipart = require "multipart"
local responses = require "kong.tools.responses"
local constants = require "kong.constants"

local CONTENT_TYPE = "content-type"
local CONTENT_LENGTH = "content-length"
local FORM_URLENCODED = "application/x-www-form-urlencoded"
local MULTIPART_DATA = "multipart/form-data"

local _M = {}

local function get_key_from_query(key_name, request, conf)
  local key, parameters
  local found_in = {}

  -- First, try with querystring
  parameters = request.get_uri_args()

  -- Find in querystring
  if parameters[key_name] ~= nil then
    found_in.querystring = true
    key = parameters[key_name]
  -- If missing from querystring, try to get it from the body
  elseif request.get_headers()[CONTENT_TYPE] then
    -- Lowercase content-type for easier comparison
    local content_type = stringy.strip(string.lower(request.get_headers()[CONTENT_TYPE]))
    if stringy.startswith(content_type, FORM_URLENCODED) then
      -- Call ngx.req.read_body to read the request body first
      -- or turn on the lua_need_request_body directive to avoid errors.
      request.read_body()
      parameters = request.get_post_args()

      found_in.form = parameters[key_name] ~= nil
      key = parameters[key_name]
    elseif stringy.startswith(content_type, MULTIPART_DATA) then
      -- Call ngx.req.read_body to read the request body first
      -- or turn on the lua_need_request_body directive to avoid errors.
      request.read_body()

      local body = request.get_body_data()
      parameters = Multipart(body, content_type)

      local parameter = parameters:get(key_name)
      found_in.body = parameter ~= nil
      key = parameter and parameter.value or nil
    end
  end

  if conf.hide_credentials then
    if found_in.querystring then
      parameters[key_name] = nil
      request.set_uri_args(parameters)
    elseif found_in.form then
      parameters[key_name] = nil
      local encoded_args = ngx.encode_args(parameters)
      request.set_header(CONTENT_LENGTH, string.len(encoded_args))
      request.set_body_data(encoded_args)
    elseif found_in.body then
      parameters:delete(key_name)
      local new_data = parameters:tostring()
      request.set_header(CONTENT_LENGTH, string.len(new_data))
      request.set_body_data(new_data)
    end
  end

  return key
end

-- Fast lookup for credential retrieval depending on the type of the authentication
--
-- All methods must respect:
--
-- @param request ngx request object
-- @param {table} conf Plugin configuration (value property)
-- @return {string} public_key
-- @return {string} private_key
local retrieve_credentials = {
  [constants.AUTHENTICATION.HEADER] = function(request, conf)
    local key
    local headers = request.get_headers()

    if conf.key_names then
      for _,key_name in ipairs(conf.key_names) do
        if headers[key_name] ~= nil then
          key = headers[key_name]

          if conf.hide_credentials then
            request.clear_header(key_name)
          end

          return key
        end
      end
    end
  end,
  [constants.AUTHENTICATION.QUERY] = function(request, conf)
    local key

    if conf.key_names then
      for _,key_name in ipairs(conf.key_names) do
        key = get_key_from_query(key_name, request, conf)

        if key then
          return key
        end

      end
    end
  end
}

-- Fast lookup for credential retrieval depending on the type of the authentication
--
-- All methods must respect:
--
-- @param request ngx request object
-- @param {table} conf Plugin configuration (value property)
-- @return {string} public_key
-- @return {string} private_key

local function get_infos(request, responses, headers)
  local signature = request.get_headers()[headers[1]]
  local key = request.get_headers()[headers[2]]
  if (signature == nil or key == nil) then
    ngx.ctx.stop_phases = true -- interrupt other phases of this request
    return responses.send_HTTP_FORBIDDEN(table.concat(headers, ' or ') .. ' not found')
  end
  return signature, key
end

local retrieve_headers = {
  [1] = function(request, responses)
    return {get_infos(request, responses, {'x-sigfap-auth-app-signature', 'x-sigfap-auth-app-key'})}
  end,
  [2] = function(request, responses)
    local app_sign, app_key = get_infos(request, responses, {'x-sigfap-auth-app-signature', 'x-sigfap-auth-app-key'})
    local user_sign, user_key = get_infos(request, responses, {'x-sigfap-auth-user-signature', 'x-sigfap-auth-user-key'})

    return {app_sign, app_key}, {user_sign, user_key}
  end
}

local function get_credentials( key )
  credential_info = cache.get_and_set('sigfapauth_credentials/'..key, function()
    local credentials, err = dao.keyauth_credentials:find_by_keys { consumer_id = key }
    local result
    if err then
      return responses.send_HTTP_INTERNAL_SERVER_ERROR(err)
    elseif #credentials > 0 then
      result = credentials[1]
    end
    return result
  end)
  if not credential_info then
    ngx.ctx.stop_phases = true -- interrupt other phases of this request
    return responses.send_HTTP_FORBIDDEN("Invalid authentication credentials with consumer_id = "..key)
  end
  return credential_info
end

function _M.execute(conf)
  if not conf then return end
  local app
  local user
  local time, level = get_infos(ngx.req, responses, {'x-sigfap-auth-api-time', 'x-sigfap-auth-api-level'})
  if level == '1' then
    app = retrieve_headers[1](ngx.req, responses)
  elseif level == '2' then
    app, user = retrieve_headers[2](ngx.req, responses)
  else
    ngx.ctx.stop_phases = true -- interrupt other phases of this request
    return responses.send_HTTP_FORBIDDEN('Api level: '..level .. ' not allowed')
  end

  local app_credentials = get_credentials(app[2])
  local user_credentials
  if level == '2' then
    user_credentials = get_credentials(user[2])
  end
  
  
end

return _M

-- 1. Verificar se existe header contendo o level da requisição e o timestamp da requisição
-- 2. Se existe os headers coleta os headers baseado no level:
--    2.1 Se o level for 1: Haverá apenas o header da aplicação
--    2.2 Se o level for 2: Haverá o header de usuário e de aplicação
-- 3. Realiza a busca pela chave o consumidor e pega suas informações
-- 4. Concatena o token e o timestamp e então assina
-- 5. 
