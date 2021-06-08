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
    # Path for hitting compatibility end point
    COMPATIBLITY_PATH = '/compatibility'

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

    # Class method Used to get all the vehicles in the app. This only returns
    # API - https://smartcar.com/docs/api#get-all-vehicles
    # @param token [String] - Access token
    # @param options [Hash] - Optional filter parameters (check documentation)
    #
    # @return [Array] of vehicle IDs(Strings)
    def self.all_vehicle_ids(token:, options: {}, version: Smartcar.get_api_version)
      response, = new(token: token, id: 'none', version: version).fetch(
        path: PATH.call(''),
        options: options
      )
      response['vehicles']
    end

    # Class method Used to check compatiblity for VIN and scope
    # API - https://smartcar.com/docs/api#connect-compatibility
    # @param vin [String] VIN of the vehicle to be checked
    # @param scope [Array of Strings] - array of scopes
    # @param country [String] An optional country code according to
    # [ISO 3166-1 alpha-2](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2).
    # Defaults to US.
    #
    # @return [Boolean] true or false
    def self.compatible?(vin:, scope:, country: 'US', version: Smartcar.get_api_version)
      raise InvalidParameterValue.new, 'vin is a required field' if vin.nil?
      raise InvalidParameterValue.new, 'scope is a required field' if scope.nil?

      response, = new(token: 'none', id: 'none', version: version).fetch(
        path: COMPATIBLITY_PATH,
        options: {
          vin: vin,
          scope: scope.join(' '),
          country: country
        },
        auth: BASIC
      )
      response['compatible']
    end

    private

    def get_object(klass, data)
      klass.new(data)
    end
  end
end
