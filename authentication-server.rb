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


# The API credentials to access the authentication callback endpoint.
# The values must match the values of 'authenticationCallbackApiKey'
# and 'authenticationCallbackApiSecret' of your service.
$API_KEY    = 'authentication-api-key'
$API_SECRET = 'authentication-api-secret'


# The authentication server.
class AuthenticationServer < Authlete::AuthenticationServer
  # Authenticate the API call to the authentication callback endpoint.
  def authenticate_api_call(api_key, api_secret)
    return api_key == $API_KEY && api_secret == $API_SECRET
  end

  # Authenticate the end-user. The argument is an instance of
  # Authlete::Request::AuthenticationCallbackRequest. This method
  # must return a unique identifier (= subject) of the end-user
  # when he/she was authenticated successfully.
  def authenticate_user(req)
    # This method is the main part of this authentication server.

    # TODO: Support social login. The current implementation supports
    #       only the simple 'ID & Password' authentication. Authlete
    #       server has not supported social login yet.

    # This demo implementation regards the credentials of the end-user
    # as valid when the value of ID and that of password are equal.
    if req.id == req.password
      # Use the ID as the unique identifier (subject) of the end-user.
      # Note that this is not always true on actual services.
      return req.id
    end

    # The credentials of the end-user are invalid.
    nil
  end

  # Collect values of the requested claims for the subject. 'req' is
  # an instance of Authlete::Request::AuthenticationCallbackRequest.
  # 'subject' is the value which was returned by the preceding call of
  # authenticate_user method. The value returned from this method has
  # to be formatted in JSON.
  def collect_claims(req, subject)
    # req.claims contains names of requested claims. req.claimsLocales
    # contains the value of 'claims_locales' request parameter of the
    # authorization request which has triggered this authentication
    # callback request.

    # If no claims are requested.
    if req.claims == nil
      return nil
    end

    # Hash for claim values.
    values = {}

    # This demo implementation supports only 'given_name' claim.
    if req.claims.include?('given_name')
      # Use the value of 'subject' as a given name.
      values['given_name'] = subject
    end

    # Format to JSON.
    JSON.generate(values)
  end

  # Get the path of the authentication callback endpoint. Subclasses
  # can change the path by overriding this method.
  def authentication_callback_endpoint_path
    # Use the default path, '/authentication'.
    super
  end
end
