# frozen_string_literal: true

require 'oauth2'
require 'base64'
require 'rbconfig'
module Smartcar
  # The Base class for all of the other class.
  # Let other classes inherit from here and put common methods here.
  class Base
    include Smartcar::Utils

    # Error raised when an invalid parameter is passed.
    class InvalidParameterValue < StandardError; end
    # Constant for Basic auth type
    BASIC = 'Basic'
    # Number of seconds to wait for response
    REQUEST_TIMEOUT = 310

    attr_accessor :token, :error, :unit_system, :version, :auth_type

    %i[get post patch put delete].each do |verb|
      # meta programming and define all Restful methods.
      # @param path [String] the path to hit for the request.
      # @param data [Hash] request body if needed.
      #
      # @return [Hash] The response Json parsed as a hash.
      define_method verb do |path, data = nil, headers = {}|
        response = service.send(verb) do |request|
          request_headers = {}
          request_headers['Authorization'] = auth_type == BASIC ? "Basic #{token}" : "Bearer #{token}"
          request_headers['sc-unit-system'] = unit_system if unit_system
          request_headers['Content-Type'] = 'application/json'
          request_headers['User-Agent'] =
            "Smartcar/#{version} (#{RbConfig::CONFIG['host_os']}; #{RbConfig::CONFIG['arch']}) Ruby v#{RUBY_VERSION}"
          request.headers = request_headers.merge(headers)
          complete_path = "/v#{version}#{path}"
          if verb == :get
            request.url complete_path, data
          else
            request.url complete_path
            request.body = data.to_json if data
          end
        end
        handle_error(response)
        # required to handle unsubscribe response
        body = response.body.empty? ? '{}' : response.body
        [JSON.parse(body), response.headers]
      end
    end

    # This requires a proc 'PATH' to be defined in the class
    # @param path [String] resource path
    # @param query_params [Hash] query params
    # @param auth [String] type of auth
    #
    # @return [Object]
    def fetch(path:, query_params: {})
      path += "?#{URI.encode_www_form(query_params)}" unless query_params.empty?
      get(path)
    end

    private

    # gets a smartcar API service/client
    #
    # @return [OAuth2::AccessToken] An initialized AccessToken instance that acts as service client
    def service
      @service ||= Faraday.new(url: ENV['SMARTCAR_API_ORIGIN'] || API_ORIGIN, request: { timeout: REQUEST_TIMEOUT })
    end
  end
end
