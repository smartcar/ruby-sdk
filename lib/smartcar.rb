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


module Smartcar
  class ConfigNotFound < StandardError; end
  class ExternalServiceError < StandardError; end
  class ServiceUnavailableError < ExternalServiceError; end
  class AuthenticationError < ExternalServiceError; end
  class ParserError < ExternalServiceError; end
  class BadRequestError < ExternalServiceError; end
  API_VERSION = "v1.0".freeze
  SITE = "https://api.smartcar.com/".freeze

  # Path for smartcar oauth
  OAUTH_PATH = "https://connect.smartcar.com/oauth/authorize".freeze
  %w(success code test live force auto metric imperial).each do |constant|
    const_set(constant.upcase, constant.freeze)
  end
  LOCK = "LOCK".freeze
  UNLOCK = "UNLOCK".freeze
  UNITS = [IMPERIAL,METRIC]
end
