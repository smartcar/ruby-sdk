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

    def build_meta(headers)
      meta_hash = {
        'SC-Data-Age' => :data_age,
        'SC-Unit-System' => :unit_system,
        'SC-Request-Id' => :request_id
      }.each_with_object({}) do |(header_name, key), meta|
        meta[key] = headers[header_name] if headers[header_name]
      end
      meta = JSON.parse(meta_hash.to_json, object_class: OpenStruct)
      meta.data_age &&= DateTime.parse(meta.data_age)

      meta
    end

    def build_response(body, headers)
      response = JSON.parse(body.to_json, object_class: OpenStruct)
      response.meta = build_meta(headers)
      response
    end

    def build_aliases(response, aliases)
      (aliases || []).each do |original_name, alias_name|
        response.send("#{alias_name}=".to_sym, response.send(original_name.to_sym))
      end

      response
    end

    def build_error(status, body_string, headers)
      content_type = headers['content-type'] || ''
      return SmartcarError.new(status, body_string, headers) unless content_type.include?('application/json')

      begin
        parsed_body = JSON.parse(body_string, { symbolize_names: true })
      rescue StandardError => e
        return SmartcarError.new(
          status,
          {
            message: e.message,
            type: 'SDK_ERROR'
          },
          headers
        )
      end

      return SmartcarError.new(status, parsed_body, headers) if parsed_body[:error] || parsed_body[:type]

      SmartcarError.new(status, parsed_body.merge({ type: 'SDK_ERROR' }), headers)
    end

    # Given the response from smartcar API, throws an error if needed
    # @param response [Object] response Object with status and body
    def handle_error(response)
      status = response.status
      return nil if [200, 204].include?(status)

      raise build_error(response.status, response.body, response.headers)
    end

    def process_batch_response(response_body, response_headers)
      response_object = OpenStruct.new
      response_body['responses'].each do |item|
        attribute_name = convert_path_to_attribute(item['path'])
        aliases = Vehicle::METHODS[attribute_name.to_sym][:aliases]
        # merging the top level request headers and separate headers for each item of batch
        headers = response_headers.merge(item['headers'])
        response = if [200, 204].include?(item['code'])
                     build_aliases(build_response(item['body'], headers), aliases)
                   else
                     build_error(item['code'], item['body'].to_json, headers)
                   end
        response_object.define_singleton_method attribute_name do
          raise response if response.is_a?(SmartcarError)

          response
        end
      end
      response_object
    end

    # takes a path and converts it to the keys we use.
    # EX - '/charge' -> :charge, '/battery/capacity' -> :battery_capacity
    def convert_path_to_attribute(path)
      return :attributes if path == '/'

      path.split('/').reject(&:empty?).join('_').to_sym
    end
  end
end
