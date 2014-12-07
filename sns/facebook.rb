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


require 'date'
require 'rest-client'


module Sns
  module Facebook
    private

    # Mapping claim names (OpenID Connect) to field names (Facebook).
    CLAIM_TO_FIELD_HASH = {
      'name'        => 'name',
      'given_name'  => 'first_name',
      'family_name' => 'last_name',
      'middle_name' => 'middle_name',
      'profile'     => 'link',
      'website'     => 'website',
      'email'       => 'email',
      'gender'      => 'gender',
      'birthdate'   => 'birthday',
      'locale'      => 'locale',
      'address'     => 'location',
      'updated_at'  => 'updated_time'
    }

    public

    def self.collect_claims(req)
      # Normalize claim names.
      claim_name_set = normalize_claim_names(req.claims)

      if claim_name_set.nil?
        return nil
      end

      # Get claim values.
      claim_value_hash = get_claim_values(req.access_token, claim_name_set)

      if claim_value_hash.nil?
        return nil
      end

      # Format claims.
      return format_claims(claim_name_set, claim_value_hash)
    end

    private

    def self.normalize_claim_names(claims)
      claim_name_set = Set.new

      # For each requested claim
      claims.each do |claim|
        # Remove the trailing '#locale', if any.
        claim = claim.split('#')[0]

        # If there exists a field which corresponds to the claim.
        if CLAIM_TO_FIELD_HASH.has_key?(claim)
          claim_name_set.add(claim)
        end
      end

      if claim_name_set.size == 0
        return nil
      end

      return claim_name_set
    end

    def self.get_claim_values(access_token, claim_name_set)
      # Prepare the value of 'fields' request parameter.
      fields = build_fields(claim_name_set)

      begin
        response = RestClient.get('https://graph.facebook.com/v2.2/me', {
          :params => {
            :access_token => access_token,
            :fields       => fields
          }
        })
      rescue => e
        puts e.message
        e.backtrace.each do |entry|
          puts "  #{entry}"
        end
        return nil
      end

      return JSON.parse(response.to_str)
    end

    def self.build_fields(claim_name_set)
      fields = Array.new

      claim_name_set.each do |claim_name|
        fields.push(CLAIM_TO_FIELD_HASH[claim_name])
      end

      return fields.join(',')
    end

    def self.format_claims(claim_name_set, claim_value_hash)
      claims = {}

      claim_name_set.each do |claim_name|
        # Field name (Facebook) which corresponds to the claim name
        # (OpenID Connect)
        field_name = CLAIM_TO_FIELD_HASH[claim_name]

        # The value of the field.
        value = claim_value_hash[field_name]

        # If the response from Facebook does not contain the field.
        if value.nil?
          next
        end

        # Adjust the format as necessary.
        value = format_claim_value(claim_name, value)

        if value.nil?
          next
        end

        claims[claim_name] = value
      end

      if claims.size == 0
        return nil
      end

      return JSON.generate(claims)
    end

    def self.format_claim_value(claim_name, value)
      case claim_name
      when 'birthdate'
        return format_birthdate(value)
      when 'locale'
        return format_locale(value)
      when 'address'
        return format_address(value)
      when 'updated_at'
        return format_updated_at(value)
      else
        return value
      end
    end

    def self.format_birthdate(value)
      # Convert MM/DD/YYYY to YYYY-MM-DD
      matched = %r{(\d{2})/(\d{2})/(\d{4})}.match(value)
      "#{matched[3]}-#{matched[1]}-#{matched[2]}"
    end

    def self.format_locale(value)
      # Convert "xx_XX" to "xx-XX"
      value.gsub('_', '-')
    end

    def self.format_address(value)
      # Convert {"id":"ID","name":"NAME"} to {"formatted":"NAME"}.
      { 'formatted' => value['name'] }
    end

    def self.format_updated_at(value)
      # Convert yyyy-MM-ddTHH:mm:ssZ to an integer that represents
      # seconds since Unix epoch.
      DateTime.parse(value).to_time.to_i
    end
  end
end
