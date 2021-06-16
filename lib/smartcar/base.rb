# frozen_string_literal: true

require 'oauth2'
require 'base64'
module Smartcar
  # The Base class for all of the other class.
  # Let other classes inherit from here and put common methods here.
  class Base
    include Smartcar::Utils

    # Error raised when an invalid parameter is passed.
    class InvalidParameterValue < StandardError; end
    # Constant for Basic auth type
    BASIC = 'BASIC'
    # Number of seconds to wait for response
    REQUEST_TIMEOUT = 310

    attr_accessor :token, :error, :unit_system, :version, :auth_type

    %i[get post patch put delete].each do |verb|
      # meta programming and define all Restful methods.
      # @param path [String] the path to hit for the request.
      # @param data [Hash] request body if needed.
      #
      # @return [Hash] The response Json parsed as a hash.
      define_method verb do |path, data = nil|
        response = service.send(verb) do |request|
          request.headers['Authorization'] = auth_type == BASIC ? "BASIC #{token}" : "BEARER #{token}"
          request.headers['sc-unit-system'] = unit_system if unit_system
          request.headers['Content-Type'] = 'application/json'
          complete_path = "/v#{version}#{path}"
          if verb == :get
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
    def fetch(path:, options: {})
      path += "?#{URI.encode_www_form(options)}" unless options.empty?
      get(path)
    end

    private

    # gets a smartcar API service/client
    #
    # @return [OAuth2::AccessToken] An initialized AccessToken instance that acts as service client
    def service
      @service ||= Faraday.new(url: SITE, request: { timeout: REQUEST_TIMEOUT })
    end
  end
end
