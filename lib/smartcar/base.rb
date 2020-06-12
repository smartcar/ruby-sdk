require 'oauth2'
require 'base64'
module Smartcar
  # The Base class for all of the other class.
  # Let other classes inherit from here and put common methods here.
  class Base
    include Utils

    # Error raised when an invalid parameter is passed.
    class InvalidParameterValue < StandardError; end
    # Constant for Bearer auth type
    BEARER = 'BEARER'.freeze
    # Constant for Basic auth type
    BASIC = 'BASIC'.freeze

    attr_accessor :token, :error, :meta

    %i{get post patch put delete}.each do |verb|
      # meta programming and define all Restful methods.
      # @param path [String] the path to hit for the request.
      # @param data [Hash] request body if needed.
      #
      # @return [Hash] The response Json parsed as a hash.
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
            request.body = data.to_json if data
          end
        end
        error = get_error(response)
        raise error if error
        [JSON.parse(response.body), response.headers]
      end
    end

    # This requires a proc 'PATH' to be defined in the class
    # @param path [String] resource path
    # @param options [Hash] query params
    # @param auth [String] type of auth
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
      Base64.strict_encode64("#{get_config('CLIENT_ID')}:#{get_config('CLIENT_SECRET')}")
    end

    # gets a smartcar API service/client
    #
    # @return [OAuth2::AccessToken] An initialized AccessToken instance that acts as service client
    def service
      @service ||= Faraday.new(url: SITE)
    end
  end
end
