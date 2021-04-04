# frozen_string_literal: true

require 'smartcar/utils'
require 'smartcar/version'
require 'smartcar/base'
require 'smartcar/oauth'
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
require 'smartcar/user'

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

  # Path for smartcar oauth
  OAUTH_PATH = 'https://connect.smartcar.com/oauth/authorize'
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

  # rubocop:disable Naming/AccessorMethodName
  # Module method Used to set api version to be used.
  # This method can be used at the top to set the version and any
  # following request will use the version set here unless overridden
  # separately.
  # @param version [String] version to be set without 'v' prefix.
  def self.set_api_version(version)
    instance_variable_set('@api_version', version)
  end

  # Module method Used to get api version to be used.
  # This is the getter for the class instance variable @api_version
  #
  # @return [String] api version number without 'v' prefix
  def self.get_api_version
    instance_variable_get('@api_version')
  end
  # rubocop:enable Naming/AccessorMethodName
end
