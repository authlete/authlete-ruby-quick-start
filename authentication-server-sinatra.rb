#!/usr/bin/env ruby
#
# Copyright (C) 2014 Authlete, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


require 'authlete'
require 'sinatra'


# The API credentials to access the authentication callback endpoint.
$API_KEY    = 'authentication-api-key'
$API_SECRET = 'authentication-api-secret'


# The authentication server
class AuthenticationServer < Sinatra::Base
  # Authentication for API calls to the authentication callback endpoint.
  use Rack::Auth::Basic, "Authentication Callback Endpoint" do |api_key, api_secret|
    api_key == $API_KEY && api_secret == $API_SECRET
  end

  # The Authentication Callback Endpoint.
  post '/authentication' do
    # Parse the authentication callback request.
    req = Authlete::Request::AuthenticationCallbackRequest.parse(request.body.read)

    # Authenticate the end-user.
    authenticated = req.id == req.password

    # Build an authentication callback response.
    res = Authlete::Response::AuthenticationCallbackResponse.new
    res.authenticated = authenticated
    res.subject       = authenticated ? req.id : nil

    # Return the response to Authlete.
    return res.to_rack_response
  end
end


# Start the authentication server.
AuthenticationServer.run!
