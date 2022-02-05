# frozen_string_literal: true

require 'recursive_open_struct'
require 'smartcar_error'
require 'smartcar/utils'
require 'smartcar/version'
require 'smartcar/base'
require 'smartcar/auth_client'
require 'smartcar/vehicle'

# Main Smartcar umbrella module
module Smartcar
  # Error raised when a config is not found
  class ConfigNotFound < StandardError; end

  # Host to connect to smartcar
  API_ORIGIN = 'https://api.smartcar.com/'
  PATHS = {
    compatibility: '/compatibility',
    user: '/user',
    vehicles: '/vehicles'
  }.freeze

  # Path for smartcar oauth
  AUTH_ORIGIN = 'https://connect.smartcar.com'
  %w[success code test live force auto metric imperial].each do |constant|
    # Constant to represent the value
    const_set(constant.upcase, constant.freeze)
  end

  # Constant for units
  UNITS = [IMPERIAL, METRIC].freeze

  # Number of seconds to wait for responses
  DEFAULT_REQUEST_TIMEOUT = 310

  # Smartcar API version variable - defaulted to 2.0
  @api_version = '2.0'

  class << self
    # Module method Used to set api version to be used.
    # This method can be used at the top to set the version and any
    # following request will use the version set here unless overridden
    # separately.
    # @param version [String] version to be set without 'v' prefix.
    def set_api_version(version)
      instance_variable_set('@api_version', version)
    end

    # Module method Used to get api version to be used.
    # This is the getter for the class instance variable @api_version
    #
    # @return [String] api version number without 'v' prefix
    def get_api_version
      instance_variable_get('@api_version')
    end

    # Module method Used to check compatiblity for VIN and scope
    #
    # API Documentation - https://smartcar.com/docs/api#connect-compatibility
    # @param vin [String] VIN of the vehicle to be checked
    # @param scope [Array of Strings] - array of scopes
    # @param country [String] An optional country code according to
    # [ISO 3166-1 alpha-2](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2).
    # Defaults to US.
    # @param options [Hash] Other optional parameters including overrides
    # @option options [String] :client_id Client ID that overrides ENV
    # @option options [String] :client_secret Client Secret that overrides ENV
    # @option options [String] :version API version to use, defaults to what is globally set
    # @option options [Hash] :flags A hash of flag name string as key and a string or boolean value.
    # @option options [Boolean] :test_mode Whether to use test mode or not.
    # @option options [String] :test_mode_compatibility_level this is required argument while using
    # test mode with a real vin. For more information refer to docs.
    # @option options [Faraday::Connection] :service Optional connection object to be used for requests
    #
    # @return [OpenStruct] And object representing the JSON response mentioned in https://smartcar.com/docs/api#connect-compatibility
    #  and a meta attribute with the relevant items from response headers.
    def get_compatibility(vin:, scope:, country: 'US', options: {})
      raise InvalidParameterValue.new, 'vin is a required field' if vin.nil?
      raise InvalidParameterValue.new, 'scope is a required field' if scope.nil?

      base_object = Base.new(
        {
          version: options[:version] || Smartcar.get_api_version,
          auth_type: Base::BASIC,
          service: options[:service]
        }
      )

      base_object.token = generate_basic_auth(options, base_object)

      base_object.build_response(*base_object.fetch(
        path: PATHS[:compatibility],
        query_params: build_compatibility_params(vin, scope, country, options)
      ))
    end

    # Module method Used to get user id
    #
    # API Documentation - https://smartcar.com/docs/api#get-user
    # @param token [String] Access token
    # @param version [String] Optional API version to use, defaults to what is globally set
    # @param options [Hash] Other optional parameters including overrides
    # @option options [Faraday::Connection] :service Optional connection object to be used for requests
    #
    # @return [OpenStruct] And object representing the JSON response mentioned in https://smartcar.com/docs/api#get-user
    #  and a meta attribute with the relevant items from response headers.
    def get_user(token:, version: Smartcar.get_api_version, options: {})
      base_object = Base.new(
        {
          token: token,
          version: version,
          service: options[:service]
        }
      )
      base_object.build_response(*base_object.fetch(path: PATHS[:user]))
    end

    # Module method Returns a paged list of all vehicles connected to the application for the current authorized user.
    #
    # API Documentation - https://smartcar.com/docs/api#get-all-vehicles
    # @param token [String] - Access token
    # @param paging [Hash] - Optional filter parameters (check documentation)
    # @param version [String] Optional API version to use, defaults to what is globally set
    # @param options [Hash] Other optional parameters including overrides
    # @option options [Faraday::Connection] :service Optional connection object to be used for requests
    #
    # @return [OpenStruct] And object representing the JSON response mentioned in https://smartcar.com/docs/api#get-all-vehicles
    #  and a meta attribute with the relevant items from response headers.
    def get_vehicles(token:, paging: {}, version: Smartcar.get_api_version, options: {})
      base_object = Base.new(
        {
          token: token,
          version: version,
          service: options[:service]
        }
      )
      base_object.build_response(*base_object.fetch(
        path: PATHS[:vehicles],
        query_params: paging
      ))
    end

    # Module method to generate hash challenge for webhooks. It does HMAC_SHA256(amt, challenge)
    #
    # @param amt [String] - Application Management Token
    # @param challenge [String] - Challenge string
    #
    # @return [String] String representing the hex digest
    def hash_challenge(amt, challenge)
      OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha256'), amt, challenge)
    end

    # Module method used to verify webhook payload with AMT and signature.
    #
    # @param amt [String] - Application Management Token
    # @param signature [String] - sc-signature header value
    # @param body [Object] - webhook response body
    #
    # @return [true, false] - true if signature matches the hex digest of amt and body
    def verify_payload(amt, signature, body)
      hash_challenge(amt, body.to_json) == signature
    end

    private

    def build_compatibility_params(vin, scope, country, options)
      query_params = {
        vin: vin,
        scope: scope.join(' '),
        country: country
      }
      query_params[:flags] = options[:flags].map { |key, value| "#{key}:#{value}" }.join(' ') if options[:flags]
      query_params[:mode] = options[:test_mode].is_a?(TrueClass) ? 'test' : 'live' unless options[:test_mode].nil?

      if options[:test_mode_compatibility_level]
        query_params[:test_mode_compatibility_level] =
          options[:test_mode_compatibility_level]
        query_params[:mode] = 'test'
      end

      query_params
    end

    # returns auth token for Basic auth
    #
    # @return [String] Base64 encoding of CLIENT:SECRET
    def generate_basic_auth(options, base_object)
      client_id = options[:client_id] || base_object.get_config('SMARTCAR_CLIENT_ID')
      client_secret = options[:client_secret] || base_object.get_config('SMARTCAR_CLIENT_SECRET')
      Base64.strict_encode64("#{client_id}:#{client_secret}")
    end
  end
end
