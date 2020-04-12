module Smartcar
  # Vehicle class to connect to vehicle basic info,disconnect, lock unlock and get all vehicles API
  # For ease of use, this also has methods define to be able to call other resources on a vehicle object
  # For Ex. Vehicle object will be treate as an entity and doing vehicle_object.
  # Battery should return Battery object.
  #
  # @author [ashwin]
  #
  class Vehicle < Base

    COMPATIBLITY_PATH = '/compatibility'.freeze
    PATH = Proc.new{|id| "/vehicles/#{id}"}
    attr_accessor :token, :id, :unit_system


    def initialize(token:, id:, unit_system: IMPERIAL)
      raise InvalidParameterValue.new, "Invalid Units provided : #{unit_system}" unless UNITS.include?(unit_system)
      raise InvalidParameterValue.new, "Vehicle ID (id) is a required field" if id.nil?
      raise InvalidParameterValue.new, "Access Token(token) is a required field" if token.nil?
      @token = token
      @id = id
      @unit_system = unit_system
    end

    # Accessor method for vehicle attributes.
    %I(make model year).each do |method_name|
      define_method method_name do
        vehicle_attributes.send(method_name)
      end
    end

    # Class method Used to get all the vehicles in the app. This only returns
    # API - https://smartcar.com/docs/api#get-all-vehicles
    # @param token [String] - Access token
    # @param options [Hash] - Optional filter parameters (check documentation)
    #
    # @return [Array] of vehicle IDs(Strings)
    def self.all_vehicle_ids(token:, options: {})
      new(token: token, id: 'none').fetch(
        path: PATH.call(''),
        options: options
      )['vehicles']
    end

    # Class method Used to check compatiblity for VIN and scope
    # API - https://smartcar.com/docs/api#connect-compatibility
    # @param vin [String] VIN of the vehicle to be checked
    # @param scope [Array of Strings] - array of scopes
    #
    # @return [Boolean] true or false
    def self.compatible?(vin:, scope:)
      raise InvalidParameterValue.new, "vin is a required field" if vin.nil?
      raise InvalidParameterValue.new, "scope is a required field" if scope.nil?

      new(token: 'none', id: 'none').fetch(path: COMPATIBLITY_PATH,
        options: {
          vin: vin,
          scope: scope.join(' ')
        },
        auth: BASIC
      )['compatible']
    end

    # Fetch the list of permissions that this application has been granted for
    # this vehicle
    # EX : Smartcar::Vehicle.new(token: token, id: id).permissions
    # @param options [Hash] - Optional filter parameters (check documentation)
    #
    # @return [Array] of permissions (Strings)
    def permissions(options: {})
      Permissions.new(fetch(
        path: Permissions::PATH.call(id),
        options: options
      )).permissions
    end

    #  Method Used toRevoke access for the current requesting application
    # API - https://smartcar.com/docs/api#delete-disconnect
    #
    # @return [Boolean] true if success
    def disconnect!
      response = delete(PATH.call(id) + "/application")
      response['status'] == SUCCESS
    end

    # Methods Used lock or unlock car
    # API - https://smartcar.com/docs/api#post-security
    #
    # @return [Boolean] true if success
    %w(lock unlock).each do |method_name|
      define_method "#{method_name}!" do
        lock_or_unlock!(action: Smartcar.const_get(method_name.upcase))
      end
    end

    # Following section defined methods using meta programing to fetch various
    # details of a vehicle. The key is the method name, and value is Class that
    # wraps the data.
    {
      # Returns the state of charge (SOC) and remaining range of an electric or
      # plug-in hybrid vehicle's battery.
      # API - https://smartcar.com/docs/api#get-ev-battery
      #
      # @return [Battery] object
      battery: Battery,
      # Returns the current charge status of the vehicle.
      # API - https://smartcar.com/docs/api#get-ev-battery
      #
      # @return [Charge] object
      charge: Charge,
      # Returns the remaining life span of a vehicle's engine oil
      # API - https://smartcar.com/docs/api#get-engine-oil-life
      #
      # @return [EngineOil] object
      engine_oil: EngineOil,
      # Returns the status of the fuel remaining in the vehicle's gas tank.
      # API - https://smartcar.com/docs/api#get-fuel-tank
      #
      # @return [Fuel] object
      fuel: Fuel,
      # Returns the last known location of the vehicle in geographic coordinates.
      # API - https://smartcar.com/docs/api#get-location
      #
      # @return [Location] object
      location: Location,
      # Returns the vehicle's last known odometer reading.
      # API - https://smartcar.com/docs/api#get-odometer
      #
      # @return [Odometer] object
      odometer: Odometer,
      # Returns the air pressure of each of the vehicle's tires.
      # API - https://smartcar.com/docs/api#get-tire-pressure
      #
      # @return [TirePressure] object
      tire_pressure: TirePressure,
    }.each do |method_name, klass|
      define_method method_name do
        klass.new(
          fetch(
            path: klass::PATH.call(id)
          )
        )
      end
    end

    #NOTE : The following two also could be defined by metaprogramming,
    # But these are items that dont change and hence can be cached in the
    # vehicle object.

    # Returns the vehicle's manufacturer identifier.
    # API - https://smartcar.com/docs/api#get-vin
    #
    # @return [Vin] object
    def vin
      @vin ||= Vin.new(
        fetch(
          path: Vin::PATH.call(id)
        )
      ).vin
    end

    # Returns the vehicle's model make and year.
    # API - https://smartcar.com/docs/api#get-vehicle-attributes
    #
    # @return [VehicleAttributes] object
    def vehicle_attributes
      @vehicle_attributes ||= VehicleAttributes.new(
        fetch(
          path: PATH.call(id)
        )
      )
    end

    private

    def lock_or_unlock!(action:)
      response = post(PATH.call(id) + "/security", {action: action}.to_json)
      response['status'] == SUCCESS
    end

    class VehicleAttributes
      include Utils
      attr_accessor :id, :make, :model, :year
    end
  end
end
