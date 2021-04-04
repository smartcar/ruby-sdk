# frozen_string_literal: true

module Smartcar
  module VehicleUtils
    # Batch module , has all the batch related methods here to declutter Vehicle class
    module Batch
      DATA_CLASSES = {
        battery: Smartcar::Battery,
        charge: Smartcar::Charge,
        engine_oil: Smartcar::EngineOil,
        fuel: Smartcar::Fuel,
        location: Smartcar::Location,
        odometer: Smartcar::Odometer,
        permissions: Smartcar::Permissions,
        tire_pressure: Smartcar::TirePressure,
        vin: Smartcar::Vin
      }.freeze
      # Method to get batch requests
      # API - https://smartcar.com/docs/api#post-batch-request
      # @param attributes [Array] Array of strings or symbols of attributes to be fetched together
      #
      # @return [Hash] Hash with key as requested attribute(symbol)
      # and value as Error OR Object of the requested attribute
      def batch(attributes = [])
        raise InvalidParameterValue.new, 'vin is a required field' if attributes.nil?

        request_body = get_batch_request_body(attributes)
        response, _meta = post("#{Smartcar::Vehicle::PATH.call(id)}/batch", request_body)
        process_batch_response(response)
      end

      private

      def allowed_attributes
        @allowed_attributes ||= DATA_CLASSES.transform_values { |klass| get_path(klass) }
      end

      def path_to_class
        @path_to_class ||= DATA_CLASSES.transform_keys { |key| get_path(DATA_CLASSES[key]) }
      end

      # @private
      BatchItemResponse = Struct.new(:body, :status, :headers) do
        def body_with_meta
          body.merge(meta: headers)
        end
      end

      def get_batch_request_body(attributes)
        attributes = validated_attributes(attributes)
        requests = attributes.each_with_object([]) do |item, all_requests|
          all_requests << { path: allowed_attributes[item] }
        end
        { requests: requests }
      end

      def process_batch_response(responses)
        inverted_map = allowed_attributes.invert
        responses['responses'].each_with_object({}) do |response, result|
          item_response = BatchItemResponse.new(response['body'], response['code'], response['headers'])
          error = get_error(item_response)
          path = response['path']
          result[inverted_map[path]] = error || path_to_class[path].new(item_response.body_with_meta)
        end
      end

      def validated_attributes(attributes)
        attributes.map!(&:to_sym)
        unsupported_attributes = (attributes - allowed_attributes.keys) || []
        unless unsupported_attributes.empty?
          message = "Unsupported attribute(s) requested in batch  - #{unsupported_attributes.join(',')}"
          raise Smartcar::Base::InvalidParameterValue.new, message
        end
        attributes
      end

      def get_path(klass)
        path = klass::PATH.call(id)
        path.split("/vehicles/#{id}").last
      end
    end
  end
end
