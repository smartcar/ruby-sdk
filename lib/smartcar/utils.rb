# frozen_string_literal: true

module Smartcar
  # Utils module , provides utility methods to underlying classes
  module Utils
    # A constructor to take a hash and assign it to the instance variables
    # @param options = {} [Hash] Could by any class's hash, but the first level keys should be defined in the class
    #
    # @return [Subclass os Base] Returns object of any subclass like Report
    def initialize(options = {})
      options.each do |attribute, value|
        instance_variable_set("@#{attribute}", value)
      end
    end

    # Utility method to return a hash of the isntance variables
    #
    # @return [Hash] hash of all instance variables
    def to_hash
      instance_variables.each_with_object({}) do |attribute, hash|
        hash[attribute.to_s.delete('@').to_sym] = instance_variable_get(attribute)
      end
    end

    # gets a given env variable, checks for existence and throws exception if not present
    # @param config_name [String] key of the env variable
    #
    # @return [String] value of the env variable
    def get_config(config_name)
      # ENV.MODE is set to test by e2e tests.
      config_name = "E2E_#{config_name}" if ENV['MODE'] == 'test'
      raise Smartcar::ConfigNotFound, "Environment variable #{config_name} not found !" unless ENV[config_name]

      ENV[config_name]
    end

    # Given the response from smartcar API, returns an error object if needed
    # @param response [Object] response Object with status and body
    #
    # @return [Object] nil OR Error object
    def get_error(response)
      status = response.status
      return nil if [200, 204].include?(status)
      return Smartcar::ServiceUnavailableError.new("Service Unavailable - #{response.body}") if status == 404
      return Smartcar::BadRequestError.new("Bad Request - #{response.body}") if status == 400
      return Smartcar::AuthenticationError.new('Authentication error') if status == 401

      Smartcar::ExternalServiceError.new("API error - #{response.body}")
    end

    def handle_errors(response)
      error = get_error(response)
      raise error if error
    end
  end
end
