# frozen_string_literal: true

module Smartcar
  # Vehicle class to connect to vehicle basic info,disconnect, lock unlock and get all vehicles API
  # For ease of use, this also has methods define to be able to call other resources on a vehicle object
  # For Ex. Vehicle object will be treate as an entity and doing vehicle_object.
  # Battery should return Battery object.
  #
  # @attr [String] token Access token used to connect to Smartcar API.
  # @attr [String] id Smartcar vehicle ID.
  # @attr [String] unit_system unit system to represent the data in.
  class Vehicle < Base
    include VehicleUtils::Data
    include VehicleUtils::Actions
    include VehicleUtils::Batch
    # Path for hitting vehicle ids end point
    PATH = proc { |id| "/vehicles/#{id}" }

    attr_reader :id

    def initialize(token:, id:, unit_system: IMPERIAL, version: Smartcar.get_api_version)
      super
      raise InvalidParameterValue.new, "Invalid Units provided : #{unit_system}" unless UNITS.include?(unit_system)
      raise InvalidParameterValue.new, 'Vehicle ID (id) is a required field' if id.nil?
      raise InvalidParameterValue.new, 'Access Token(token) is a required field' if token.nil?

      @token = token
      @id = id
      @unit_system = unit_system
      @version = version
    end

    private

    def get_object(klass, data)
      klass.new(data)
    end
  end
end
