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

      ENV.fetch(config_name, nil)
    end

    # Converts a hash to RecursiveOpenStruct (a powered up OpenStruct object).
    # NOTE - Do not replace with the more elegant looking
    # JSON.parse(meta_hash.to_json, object_class: OpenStruct)
    # this is because we had an app using OJ as their json parser which led to an issue using the
    # above mentioned method. Source : https://github.com/ohler55/oj/issues/239
    # @param hash [Hash] json object as hash
    #
    # @return [RecursiveOpenStruct]
    def json_to_ostruct(hash)
      convert_to_ostruct_recursively(hash)
    end

    # Helper method to recursively convert hashes and arrays to RecursiveOpenStruct
    def convert_to_ostruct_recursively(obj)
      case obj
      when Array
        obj.map { |el| convert_to_ostruct_recursively(el) }
      when Hash
        RecursiveOpenStruct.new(
          obj.transform_values { |value| convert_to_ostruct_recursively(value) },
          recurse_over_arrays: true
        )

      else
        obj
      end
    end

    def build_meta(headers)
      meta_hash = {
        'sc-data-age' => :data_age,
        'sc-unit-system' => :unit_system,
        'sc-request-id' => :request_id,
        'sc-fetched-at' => :fetched_at
      }.each_with_object({}) do |(header_name, key), meta|
        meta[key] = headers[header_name] if headers[header_name]
      end
      meta = json_to_ostruct(meta_hash)
      if meta.data_age
        begin
          meta.data_age = DateTime.parse(meta.data_age)
        rescue ArgumentError
          meta.data_age = nil
        end
      end
      if meta.fetched_at
        begin
          meta.fetched_at = DateTime.parse(meta.fetched_at)
        rescue ArgumentError
          meta.fetched_at = nil
        end
      end
      meta
    end

    def build_response(body, headers)
      # Check if body is already parsed (i.e., a Hash) or if it needs parsing (i.e., a String)
      body_data = body.is_a?(String) ? JSON.parse(body) : body
      if body_data.is_a?(Array)
        response = OpenStruct.new(items: json_to_ostruct(body), meta: build_meta(headers))
      else
        response = json_to_ostruct(body)
        response.meta = build_meta(headers)
      end
      response
    end

    def build_aliases(response, aliases)
      (aliases || []).each do |original_name, alias_name|
        # rubocop:disable Lint/SymbolConversion
        response.send("#{alias_name}=".to_sym, response.send(original_name.to_sym))
        # rubocop:enable Lint/SymbolConversion
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
        aliases = (Vehicle::METHODS[attribute_name.to_sym] || {})[:aliases]
        # merging the top level request headers and separate headers for each item of batch
        headers = response_headers.merge(item['headers'] || {})
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

      # Adding this because else it would become tires_pressure
      return :tire_pressure if path == '/tires/pressure'

      return :lock_status if path == '/security'

      return :diagnostic_system_status if path == '/diagnostics/system_status'
      return :diagnostic_trouble_codes if path == '/diagnostics/dtcs'

      path.split('/').reject(&:empty?).join('_').to_sym
    end

    # takes query parameters and returns them as a string
    # EX - {'country': 'DE', 'flags': true} -> "county:DE flags:true"
    def stringify_params(query_params)
      query_params&.map { |key, value| "#{key}:#{value}" }&.join(' ')
    end

    def determine_mode(test_mode, mode)
      unless mode.nil?
        unless %w[test live simulated].include? mode
          raise 'The "mode" parameter MUST be one of the following: \'test\', \'live\', \'simulated\''
        end

        return mode
      end
      return if test_mode.nil?

      warn '[DEPRECATION] The "test_mode" parameter is deprecated, please use the "mode" parameter instead.'
      test_mode.is_a?(TrueClass) ? 'test' : 'live'
    end
  end
end
