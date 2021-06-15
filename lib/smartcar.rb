# frozen_string_literal: true

require 'smartcar/utils'
require 'smartcar/version'
require 'smartcar/base'
require 'smartcar/auth_client'
require 'smartcar/permissions'
require 'smartcar/battery'
require 'smartcar/battery_capacity'
require 'smartcar/charge'
require 'smartcar/engine_oil'
require 'smartcar/fuel'
require 'smartcar/location'
require 'smartcar/odometer'
require 'smartcar/tire_pressure'
require 'smartcar/vin'
require 'smartcar/vehicle_attributes'
require 'smartcar/vehicle_utils/batch'
require 'smartcar/vehicle_utils/data'
require 'smartcar/vehicle_utils/actions'
require 'smartcar/vehicle'

# Main Smartcar umbrella module
module Smartcar
  # Error raised when a config is not found
  class ConfigNotFound < StandardError; end

  # Error raised when Smartcar returns non 400, 404, 401, 200 or 204 response
  class ExternalServiceError < StandardError; end

  # Error raised when Smartcar returns 404
  class ServiceUnavailableError < ExternalServiceError; end

  # Error raised when Smartcar returns Authentication Error with status 401
  class AuthenticationError < ExternalServiceError; end

  # Error raised when Smartcar returns 400 response
  class BadRequestError < ExternalServiceError; end

  # Host to connect to smartcar
  SITE = 'https://api.smartcar.com/'
  PATHS = {
    compatibility: '/compatibility',
    user: '/user',
    vehicles: '/vehicles'
  }.freeze

  # Path for smartcar oauth
  OAUTH_HOST = 'https://connect.smartcar.com'
  %w[success code test live force auto metric imperial].each do |constant|
    # Constant to represent the value
    const_set(constant.upcase, constant.freeze)
  end

  # Lock value sent in request body
  LOCK = 'LOCK'
  # Unlock value sent in request body
  UNLOCK = 'UNLOCK'
  # Start charge value sent in request body
  START_CHARGE = 'START'
  # Stop charge value sent in request body
  STOP_CHARGE = 'STOP'
  # Constant for units
  UNITS = [IMPERIAL, METRIC].freeze

  # Smartcar API version variable - defaulted to 1.0
  @api_version = '1.0'

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
    #
    # @return [OpenStruct] And object representing the JSON response mentioned in https://smartcar.com/docs/api#connect-compatibility
    #  and a meta attribute with the response headers
    def get_compatibility(vin:, scope:, country: 'US', options: {})
      raise InvalidParameterValue.new, 'vin is a required field' if vin.nil?
      raise InvalidParameterValue.new, 'scope is a required field' if scope.nil?

      base_params = {
        token: generate_basic_auth(options),
        version: options[:version] || Smartcar.get_api_version,
        auth_type: Base::BASIC
      }

      build_response(*base_object(base_params).fetch(
        path: PATHS[:compatibility],
        options: {
          vin: vin,
          scope: scope.join(' '),
          country: country
        }
      ))
    end

    # Module method Used to get user id
    #
    # API Documentation - https://smartcar.com/docs/api#get-user
    # @param token [String] Access token
    #
    # @return [OpenStruct] And object representing the JSON response mentioned in https://smartcar.com/docs/api#get-user
    #  and a meta attribute with the response headers
    def get_user(token:, version: Smartcar.get_api_version)
      base_params = {
        token: token,
        version: version
      }
      build_response(*base_object(base_params).fetch(
        path: PATHS[:user]
      ))
    end

    # Module method Used to get all the vehicles in the app. This only returns ids of the vehicles.
    #
    # API Documentation - https://smartcar.com/docs/api#get-all-vehicles
    # @param token [String] - Access token
    # @param options [Hash] - Optional filter parameters (check documentation)
    #
    # @return [OpenStruct] And object representing the JSON response mentioned in https://smartcar.com/docs/api#get-all-vehicles
    #  and a meta attribute with the response headers
    def get_vehicles(token:, options: {}, version: Smartcar.get_api_version)
      base_params = {
        token: token,
        version: version
      }
      build_response(*base_object(base_params).fetch(
        path: PATHS[:vehicles],
        options: options
      ))
    end

    # Module method to generate hash challenege for webhooks. It does HMAC_SHA256(amt, challenge)
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
    # @param body [String] - Stringified JSON of the webhook response body
    #
    # @return [true, false] - true if signature matches the hex digest of amt and body
    def verify_payload(amt, signature, body)
      hash_challenge(amt, body) == signature
    end

    private

    def build_response(response, meta)
      # TODO: (2021-06-18) Use this as default for parsing data in base class
      JSON.parse(response.merge(meta: meta).to_json, object_class: OpenStruct)
    end

    def base_object(*args)
      Base.new(*args)
    end

    # returns auth token for BASIC auth
    #
    # @return [String] Base64 encoding of CLIENT:SECRET
    def generate_basic_auth(options)
      client_id = options[:client_id] || base_object.get_config('SMARTCAR_CLIENT_ID')
      client_secret = options[:client_secret] || base_object.get_config('SMARTCAR_CLIENT_SECRET')
      Base64.strict_encode64("#{client_id}:#{client_secret}")
    end
  end
end
