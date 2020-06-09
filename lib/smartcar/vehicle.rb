module Smartcar
  # Vehicle class to connect to vehicle basic info,disconnect, lock unlock and get all vehicles API
  # For ease of use, this also has methods define to be able to call other resources on a vehicle object
  # For Ex. Vehicle object will be treate as an entity and doing vehicle_object.
  # Battery should return Battery object.
  #
  #@attr [String] token Access token used to connect to Smartcar API.
  #@attr [String] id Smartcar vehicle ID.
  #@attr [String] unit_system unit system to represent the data in.
  class Vehicle < Base
    include Utils


    # Path for hitting compatibility end point
    COMPATIBLITY_PATH = '/compatibility'.freeze

    # Path for hitting vehicle ids end point
    PATH = Proc.new{|id| "/vehicles/#{id}"}

    attr_reader :id
    attr_accessor :token, :unit_system

    def initialize(token:, id:, unit_system: IMPERIAL)
      raise InvalidParameterValue.new, "Invalid Units provided : #{unit_system}" unless UNITS.include?(unit_system)
      raise InvalidParameterValue.new, "Vehicle ID (id) is a required field" if id.nil?
      raise InvalidParameterValue.new, "Access Token(token) is a required field" if token.nil?
      @token = token
      @id = id
      @unit_system = unit_system
    end

    # Class method Used to get all the vehicles in the app. This only returns
    # API - https://smartcar.com/docs/api#get-all-vehicles
    # @param token [String] - Access token
    # @param options [Hash] - Optional filter parameters (check documentation)
    #
    # @return [Array] of vehicle IDs(Strings)
    def self.all_vehicle_ids(token:, options: {})
      response, meta = new(token: token, id: 'none').fetch(
        path: PATH.call(''),
        options: options
      )
      response['vehicles']
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

      response, meta = new(token: 'none', id: 'none').fetch(path: COMPATIBLITY_PATH,
        options: {
          vin: vin,
          scope: scope.join(' ')
        },
        auth: BASIC
      )
      response['compatible']
    end

    # Method to get batch requests
    # API - https://smartcar.com/docs/api#post-batch-request
    # @param attributes [Array] Array of strings or symbols of attributes to be fetched together
    #
    # @return [Hash] Hash wth key as requested attribute(symbol) and value as Error OR Object of the requested attribute
    def batch(attributes = [])
      raise InvalidParameterValue.new, "vin is a required field" if attributes.nil?
      request_body = get_batch_request_body(attributes)
      response, _meta = post(PATH.call(id) + "/batch", request_body)
      process_batch_response(response)
    end

    # Fetch the list of permissions that this application has been granted for
    # this vehicle
    # EX : Smartcar::Vehicle.new(token: token, id: id).permissions
    # @param options [Hash] - Optional filter parameters (check documentation)
    #
    # @return [Array] of permissions (Strings)
    def permissions(options: {})
      get_attribute(Permissions)
    end

    #  Method Used toRevoke access for the current requesting application
    # API - https://smartcar.com/docs/api#delete-disconnect
    #
    # @return [Boolean] true if success
    def disconnect!
      response = delete(PATH.call(id) + "/application")
      response['status'] == SUCCESS
    end

    # Methods Used to lock car
    # API - https://smartcar.com/docs/api#post-security
    #
    # @return [Boolean] true if success
    def lock!
      lock_or_unlock!(action: Smartcar::LOCK)
    end

    # Methods Used to unlock car
    # API - https://smartcar.com/docs/api#post-security
    #
    # @return [Boolean] true if success
    def unlock!
      lock_or_unlock!(action: Smartcar::UNLOCK)
    end

    # Method used to start charging a car
    #
    #
    # @return [Boolean] true if success
    def start_charge!
      start_or_stop_charge!(action: Smartcar::START_CHARGE)
    end

    # Method used to stop charging a car
    #
    #
    # @return [Boolean] true if success
    def stop_charge!
      start_or_stop_charge!(action: Smartcar::STOP_CHARGE)
    end

    # Returns make model year and id of the vehicle
    # API - https://smartcar.com/api#get-vehicle-attributes
    #
    # @return [VehicleAttributes] object
    def vehicle_attributes
      get_attribute(VehicleAttributes)
    end

    # Returns the state of charge (SOC) and remaining range of an electric or
    # plug-in hybrid vehicle's battery.
    # API - https://smartcar.com/docs/api#get-ev-battery
    #
    # @return [Battery] object
    def battery
      get_attribute(Battery)
    end

    # Returns the current charge status of the vehicle.
    # API - https://smartcar.com/docs/api#get-ev-battery
    #
    # @return [Charge] object
    def charge
      get_attribute(Charge)
    end

    # Returns the remaining life span of a vehicle's engine oil
    # API - https://smartcar.com/docs/api#get-engine-oil-life
    #
    # @return [EngineOil] object
    def engine_oil
      get_attribute(EngineOil)
    end

    # Returns the status of the fuel remaining in the vehicle's gas tank.
    # API - https://smartcar.com/docs/api#get-fuel-tank
    #
    # @return [Fuel] object
    def fuel
      get_attribute(Fuel)
    end

    # Returns the last known location of the vehicle in geographic coordinates.
    # API - https://smartcar.com/docs/api#get-location
    #
    # @return [Location] object
    def location
      get_attribute(Location)
    end

    # Returns the vehicle's last known odometer reading.
    # API - https://smartcar.com/docs/api#get-odometer
    #
    # @return [Odometer] object
    def odometer
      get_attribute(Odometer)
    end

    # Returns the air pressure of each of the vehicle's tires.
    # API - https://smartcar.com/docs/api#get-tire-pressure
    #
    # @return [TirePressure] object
    def tire_pressure
      get_attribute(TirePressure)
    end

    # Returns the vehicle's manufacturer identifier (VIN).
    # API - https://smartcar.com/docs/api#get-vin
    #
    # @return [String] Vin of the vehicle.
    def vin
      _object = get_attribute(Vin)
      @vin ||= _object.vin
    end

    private

    def allowed_attributes
      @allowed_attributes ||= {
        battery: get_path(Battery),
        charge: get_path(Charge),
        engine_oil: get_path(EngineOil),
        fuel: get_path(Fuel),
        location: get_path(Location),
        odometer: get_path(Odometer),
        permissions: get_path(Permissions),
        tire_pressure: get_path(TirePressure),
        vin: get_path(Vin),
      }
    end

    def path_to_class
      @path_to_class ||= {
        get_path(Battery) => Battery,
        get_path(Charge) => Charge,
        get_path(EngineOil) => EngineOil,
        get_path(Fuel) => Fuel,
        get_path(Location) => Location,
        get_path(Odometer) => Odometer,
        get_path(Permissions) => Permissions,
        get_path(TirePressure) => TirePressure,
        get_path(Vin) => Vin,
      }
    end

    # @private
    BatchItemResponse = Struct.new(:body, :status, :headers) do
      def body_with_meta
        body.merge(meta: headers)
      end
    end

    def get_batch_request_body(attributes)
      attributes = validated_attributes(attributes)
      requests = attributes.each_with_object([]) do |item, requests|
        requests << { path: allowed_attributes[item] }
      end
      { requests: requests }
    end

    def process_batch_response(responses)
      inverted_map = allowed_attributes.invert
      responses["responses"].each_with_object({}) do |response, result|
        item_response = BatchItemResponse.new(response["body"], response["code"], response["headers"])
        error = get_error(item_response)
        path = response["path"]
        result[inverted_map[path]] = error || get_object(path_to_class[path], item_response.body_with_meta)
      end
    end

    def validated_attributes(attributes)
      attributes.map!(&:to_sym)
      unsupported_attributes = (attributes - allowed_attributes.keys) || []
      unless unsupported_attributes.empty?
        message = "Unsupported attribute(s) requested in batch  - #{unsupported_attributes.join(',')}"
        raise InvalidParameterValue.new, message
      end
      attributes
    end

    def get_attribute(klass)
      body, meta =  fetch(
        path: klass::PATH.call(id)
      )
      get_object(klass, body.merge(meta: meta))
    end

    def get_object(klass, data)
      klass.new(data)
    end

    def get_path(klass)
      path = klass::PATH.call(id)
      path.split("/vehicles/#{id}").last
    end

    def lock_or_unlock!(action:)
      response, meta = post(PATH.call(id) + "/security", { action: action })
      response['status'] == SUCCESS
    end

    def start_or_stop_charge!(action:)
      response, meta = post(PATH.call(id) + "/charge", { action: action })
      response['status'] == SUCCESS
    end
  end
end
