require 'oauth2'
require 'base64'
module Smartcar
  # The Base class for all of the other class.
  # Let other classes inherit from here and put common methods here.
  #
  # @author [ashwin]
  #
  class Base
    class InvalidParameterValue < StandardError; end
    BEARER = 'BEARER'.freeze
    BASIC = 'BASIC'.freeze

    attr_accessor :token
    # meta programming and define all Restful methods.
    # @param path [String] the path to hit for the request.
    # @param token [String] the access token to be used.
    #
    # @return [Hash] The response Json parsed as a hash.
    %i{get post patch put delete}.each do |verb|
      define_method verb do |path, data=nil|
        response = service.send(verb) do |request|
          request.headers['Authorization'] = "BEARER #{token}"
          request.headers['Authorization'] = "BASIC #{get_basic_auth}" if data[:auth] == BASIC
          request.headers['sc-unit-system'] = unit_system
          request.headers['Content-Type'] = "application/json"
          complete_path = "/#{API_VERSION}#{path}"
          if verb==:get
            request.url complete_path, data
          else
            request.url complete_path
            request.body = data if data
          end
        end
        status = response.status
        raise ServiceUnavailableError.new, "Service Unavailable - #{response.body}" if status == 404
        raise BadRequestError.new, "Bad Request - #{response.body}" if status == 400
        raise AuthenticationError.new, "Authentication error" if status == 401
        raise ExternalServiceError.new, "API error - #{response.body}" unless [200,204].include?(status)
        JSON.parse(response.body)
      end
    end

    # This requires a proc 'PATH' to be defined in the class
    # @param token [String] Access token
    # @param token [String] Vechicle ID
    #
    # @return [Object]
    def fetch(path: , options: {}, auth: 'BEARER')
      _path = path
      _path += "?#{URI.encode_www_form(options)}" unless options.empty?
      get(_path, {auth: auth})
    end

    private

    # returns auth token for BASIC auth
    #
    # @return [String] Base64 encoding of CLIENT:SECRET
    def get_basic_auth
      Base64.strict_encode64("#{ENV['SMARTCAR_CLIENT_ID']}:#{ENV['SMARTCAR_SECRET']}")
    end

    # gets a smartcar API service/client
    # @param token [String] Access token.
    #
    # @return [OAuth2::AccessToken] An initialized AccessToken instance that acts as service client
    def service
      @service ||= Faraday.new(url: SITE)
    end
  end
end