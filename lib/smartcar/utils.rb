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

    def build_response(body, meta)
      JSON.parse(body.merge(meta: meta).to_json, object_class: OpenStruct)
    end

    def build_aliases(response, aliases)
      (aliases || []).each do |original_name, alias_name|
        response.send("#{alias_name}=".to_sym, response.send(original_name.to_sym))
      end

      response
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

    def process_batch_response(response)
      response_object = OpenStruct.new
      response['responses'].each do |item|
        attribute_name = item['path'][1..-1]
        aliases = Vehicle::METHODS[attribute_name.to_sym][:aliases]
        response_body = build_aliases(build_response(item['body'], item['headers']), aliases)
        response_object.define_singleton_method attribute_name do
          if response_body.error || response_body.statusCode
            raise Smartcar::ExternalServiceError,
                  "API error - #{response_body}"
          end

          response_body
        end
      end
      response_object
    end

    def get_batch_request_body(paths)
      attributes = validated_attributes(paths)
      requests = attributes.each_with_object([]) do |item, all_requests|
        all_requests << { path: get_path(item) }
      end
      { requests: requests }
    end

    def get_path(attribute)
      path = Vehicle::METHODS[attribute][:path].call(id)
      path.split("/vehicles/#{id}").last
    end

    def validated_attributes(paths)
      attributes = paths.map { |path| path[1..-1].to_sym }
      unsupported_attributes = (attributes - Vehicle::BATCH_SUPPORTED_METHODS) || []
      unless unsupported_attributes.empty?
        message = "Unsupported attribute(s) requested in batch  - #{unsupported_attributes.join(',')}"
        raise Smartcar::Base::InvalidParameterValue.new, message
      end
      attributes
    end
  end
end
