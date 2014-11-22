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
require 'json'
require 'sinatra'


$AUTHLETE_HOST      = ENV['AUTHLETE_HOST'] || Authlete::Host::EVALUATION
$SERVICE_API_KEY    = ENV['SERVICE_API_KEY']
$SERVICE_API_SECRET = ENV['SERVICE_API_SECRET']


# The resource server
class ResourceServer < Sinatra::Base
  # Configuration
  configure do
    # Create an Authlete client.
    client = Authlete::Client.new(
      :host               => $AUTHLETE_HOST,
      :service_api_key    => $SERVICE_API_KEY,
      :service_api_secret => $SERVICE_API_SECRET
    )

    # Make the Authlete client accessible as settings.authlete_client.
    set :authlete_client, client
  end

  # Helpers
  helpers do
    # Ensure that the presented access token is valid.
    def protect_resource(request, scopes = nil, subject = nil)
      # Introspect the presented access token.
      result = settings.authlete_client.protect_resource(request, scopes, subject)

      # If the access token does not satisfy the conditions to access
      # the protected resource.
      if result.action != 'OK'
        # Return an error response to the client with WWW-Authenticate
        # HTTP header. It satisfies the requirements of RFC 6750.
        halt result.to_rack_response
      end

      return result
    end

    # Build a successful JSON response.
    def to_json_response(hash)
      [
        200,
        {
          'Content-Type'  => 'application/json;charset=UTF-8',
          'Cache-Control' => 'no-store',
          'Pragma'        => 'no-cache'
        },
        [
          JSON.generate(hash)
        ]
      ]
    end
  end

  # A protected resource endpoint, '/me'.
  get '/me' do
    # Require 'profile' scope.
    token = protect_resource(request, ['profile'])

    # Just returns the subject associated with the access token.
    return to_json_response(:subject => token.subject)
  end

  # A protected resource endpoint, '/saying'.
  get '/saying' do
    # Require 'saying' scope.
    token = protect_resource(request, ['saying'])

    # Pick up a saying randomly.
    saying = [
      { :person => 'Albert Einstein',
        :saying => 'A person who never made a mistake never tried anything new.' },
      { :person => 'John F. Kennedy',
        :saying => 'My fellow Americans, ask not what your country can do for you, ask what you can do for your country.' },
      { :person => 'Steve Jobs',
        :saying => 'Stay hungry, stay foolish.' },
      { :person => 'Walt Disney',
        :saying => 'If you can dream it, you can do it.' },
      { :person => 'Peter Drucker',
        :saying => 'Whenever you see a successful business, someone once made a courageous decision.' },
      { :person => 'Thomas A. Edison',
        :saying => 'Genius is one percent inspiration and ninety-nine percent perspiration.' }
    ].sample

    # Return the saying.
    return to_json_response(saying)
  end
end


# Start the resource server.
ResourceServer.run!
