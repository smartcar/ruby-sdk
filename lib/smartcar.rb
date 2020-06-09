require "smartcar/utils"
require "smartcar/version"
require "smartcar/base"
require "smartcar/oauth"
require "smartcar/permissions"
require "smartcar/battery"
require "smartcar/charge"
require "smartcar/engine_oil"
require "smartcar/fuel"
require "smartcar/location"
require "smartcar/odometer"
require "smartcar/tire_pressure"
require "smartcar/vin"
require "smartcar/vehicle"
require "smartcar/user"


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
  # Smartcar API version being used
  API_VERSION = "v1.0".freeze
  # Host to connect to smartcar
  SITE = "https://api.smartcar.com/".freeze

  # Path for smartcar oauth
  OAUTH_PATH = "https://connect.smartcar.com/oauth/authorize".freeze
  %w(success code test live force auto metric imperial).each do |constant|
    # Constant to represent the value
    const_set(constant.upcase, constant.freeze)
  end

  # Lock value sent in request body
  LOCK = "LOCK".freeze
  # Unlock value sent in request body
  UNLOCK = "UNLOCK".freeze
  # Start charge value sent in request body
  START_CHARGE = "START".freeze
  # Stop charge value sent in request body
  STOP_CHARGE = "STOP".freeze
  # Constant for units
  UNITS = [IMPERIAL,METRIC]
end
