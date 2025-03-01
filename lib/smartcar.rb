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
  MANAGEMENT_API_ORIGIN = 'https://management.smartcar.com'
  PATHS = {
    compatibility: '/compatibility',
    user: '/user',
    vehicles: '/vehicles',
    connections: '/management/connections'
  }.freeze

  # Path for smartcar oauth
  CONNECT_ORIGIN = 'https://connect.smartcar.com'
  AUTH_ORIGIN = 'https://auth.smartcar.com'
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
    include Smartcar::Utils
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
    # API Documentation - https://smartcar.com/docs/api#compatibility-api. Options Hash
    # @param vin [String] VIN of the vehicle to be checked
    # @param scope [Array of Strings] - array of scopes
    # @param country [String] An optional country code according to
    # [ISO 3166-1 alpha-2](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2). Defaults to US.
    # @param options [Hash] Other optional parameters including overrides (only valid for Smartcar API v1.0)
    # @option options [String] :client_id Client ID that overrides ENV
    # @option options [String] :client_secret Client Secret that overrides ENV
    # @option options [String] :version API version to use, defaults to what is globally set
    # @option options [Hash] :flags A hash of flag name string as key and a string or boolean value.
    # @option options[Boolean] :test_mode [DEPRECATED], please use `mode` instead.
    # Launch Smartcar Connect in test mode(https://smartcar.com/docs/guides/testing/).
    # @option options [String] :mode Determine what mode Smartcar Connect should be launched in.
    # Should be one of test, live or simulated.
    # @option options [String] :test_mode_compatibility_level this is required argument while using
    # test mode with a real vin. For more information refer to docs.
    # @option options [Faraday::Connection] :service Optional connection object to be used for requests
    #
    # @return [OpenStruct] And object representing the JSON response mentioned in https://smartcar.com/docs/api#compatibility-api
    #  and a meta attribute with the relevant items from response headers.
    def get_compatibility(vin:, scope:, country: 'US', options: {})
      raise Base::InvalidParameterValue.new, 'vin is a required field' if vin.nil?
      raise Base::InvalidParameterValue.new, 'scope is a required field' if scope.nil? || scope.empty?

      base_object = Base.new(
        {
          version: options[:version] || Smartcar.get_api_version,
          auth_type: Base::BASIC,
          service: options[:service]
        }
      )

      base_object.token = generate_basic_auth(options, base_object)

      base_object.build_response(*base_object.get(
        PATHS[:compatibility],
        build_compatibility_params(vin, scope, country, options)
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
      base_object = base_initializer(token, version, options)
      base_object.build_response(*base_object.get(PATHS[:user]))
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
      base_object = base_initializer(token, version, options)
      base_object.build_response(*base_object.get(
        PATHS[:vehicles],
        paging
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

    # Module method Returns a paged list of all vehicle connections connected to the application.
    #
    # API Documentation - https://smartcar.com/docs/api#get-connections
    # @param amt [String] - Application Management token
    # @param filters [Hash] - Optional filter parameters (check documentation)
    # @param paging [Hash] - Pass a cursor for paginated results
    # @param options [Hash] Other optional parameters including overrides
    # @option options [Faraday::Connection] :service Optional connection object to be used for requests
    # @option options [String] :version Optional API version to use, defaults to what is globally set
    #
    # @return [OpenStruct] And object representing the JSON response mentioned in https://smartcar.com/docs/api#get-connections
    #  and a meta attribute with the relevant items from response headers.
    def get_connections(amt:, filter: {}, paging: {}, options: {})
      paging[:limit] ||= 10
      base_object = Base.new(
        token: generate_basic_management_auth(amt, options),
        version: options[:version] || Smartcar.get_api_version,
        service: options[:service],
        auth_type: Base::BASIC,
        url: ENV['SMARTCAR_MANAGEMENT_API_ORIGIN'] || MANAGEMENT_API_ORIGIN
      )
      query_params = filter.merge(paging).compact

      base_object.build_response(*base_object.get(
        PATHS[:connections],
        query_params
      ))
    end

    def delete_connections(amt:, filter: {}, options: {})
      user_id = filter[:user_id]
      vehicle_id = filter[:vehicle_id]
      error_message = nil
      error_message = 'Filter can contain EITHER user_id OR vehicle_id, not both.' if user_id && vehicle_id
      error_message = 'Filter needs one of user_id OR vehicle_id.' unless user_id || vehicle_id

      raise Base::InvalidParameterValue.new, error_message if error_message

      query_params = {}
      query_params['user_id'] = user_id if user_id
      query_params['vehicle_id'] = vehicle_id if vehicle_id

      base_object = Base.new(
        url: ENV['SMARTCAR_MANAGEMENT_API_ORIGIN'] || MANAGEMENT_API_ORIGIN,
        auth_type: Base::BASIC,
        token: generate_basic_management_auth(amt, options),
        version: options[:version] || Smartcar.get_api_version,
        service: options[:service]
      )

      base_object.build_response(*base_object.delete(
        PATHS[:connections],
        query_params
      ))
    end

    # returns auth token for Basic vehicle management auth
    #
    # @return [String] Base64 encoding of default:amt
    def generate_basic_management_auth(amt, options = {})
      username = options[:username] || 'default'
      Base64.strict_encode64("#{username}:#{amt}")
    end

    private

    def build_compatibility_params(vin, scope, country, options)
      query_params = {
        vin: vin,
        scope: scope.join(' '),
        country: country
      }
      query_params[:flags] = stringify_params(options[:flags])

      mode = determine_mode(options[:test_mode], options[:mode])

      unless options[:test_mode_compatibility_level].nil?
        query_params[:test_mode_compatibility_level] = options[:test_mode_compatibility_level]
        mode = 'test'
      end
      query_params[:mode] = mode unless mode.nil?
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

    def base_initializer(token, version, options)
      Base.new(
        {
          token: token,
          version: version,
          service: options[:service]
        }
      )
    end
  end
end
