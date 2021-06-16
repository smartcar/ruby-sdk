# frozen_string_literal: true

module Smartcar
  # Vehicle class to connect to vehicle basic info,disconnect, lock unlock and get all vehicles API
  # For ease of use, this also has methods define to be able to call other resources on a vehicle object
  # For Ex. Vehicle object will be treate as an entity and doing vehicle_object.
  # Battery should return Battery object.
  #
  # @attr [String] token Access token used to connect to Smartcar API.
  # @attr [String] id Smartcar vehicle ID.
  # @attr [Hash] options
  # @attr unit_system [String] Unit system to represent the data in, defaults to Imperial
  # @attr version [String] API version to be used.
  class Vehicle < Base
    attr_reader :id

    # Lock value sent in request body
    LOCK = 'LOCK'
    # Unlock value sent in request body
    UNLOCK = 'UNLOCK'
    # Start charge value sent in request body
    START_CHARGE = 'START'
    # Stop charge value sent in request body
    STOP_CHARGE = 'STOP'

    # @private
    METHODS = {
      permissions: { type: :get, path: proc { |id| "/vehicles/#{id}/permissions" } },
      vehicle_attributes: { type: :get, path: proc { |id| "/vehicles/#{id}" } },
      battery: {
        type: :get,
        path: proc { |id| "/vehicles/#{id}/battery" },
        aliases: { 'percentRemaining' => 'percentage_remaining' }
      },
      battery_capacity: { type: :get, path: proc { |id| "/vehicles/#{id}/battery/capacity" } },
      charge: {
        type: :get,
        path: proc { |id| "/vehicles/#{id}/charge" },
        aliases: { 'isPluggedIn' => 'is_plugged_in?' }
      },
      engine_oil: {
        type: :get,
        path: proc { |id| "/vehicles/#{id}/engine/oil" },
        aliases: { 'lifeRemaining' => 'life_remaining' }
      },
      fuel: {
        type: :get,
        path: proc { |id| "/vehicles/#{id}/fuel" },
        aliases: {
          'amountRemaining' => 'amount_remaining',
          'percentRemaining' => 'percent_remaining'
        }
      },
      location: { type: :get, path: proc { |id| "/vehicles/#{id}/location" } },
      odometer: { type: :get, path: proc { |id| "/vehicles/#{id}/odometer" } },
      tire_pressure: {
        type: :get,
        path: proc { |id| "/vehicles/#{id}/tires/pressure" },
        aliases: {
          'backLeft' => 'back_left',
          'backRight' => 'back_right',
          'frontLeft' => 'front_left',
          'frontRight' => 'front_right'
        }
      },
      vin: { type: :get, path: proc { |id| "/vehicles/#{id}/vin" }, skip: true },
      disconnect!: { type: :delete, path: proc { |id| "/vehicles/#{id}/application" } },
      lock!: { type: :post, path: proc { |id| "/vehicles/#{id}/security" }, body: { action: LOCK } },
      unlock!: { type: :post, path: proc { |id| "/vehicles/#{id}/security" }, body: { action: UNLOCK } },
      start_charge!: { type: :post, path: proc { |id| "/vehicles/#{id}/charge" }, body: { action: START_CHARGE } },
      stop_charge!: { type: :post, path: proc { |id| "/vehicles/#{id}/charge" }, body: { action: STOP_CHARGE } }
    }.freeze

    # List of methods supported by batch endpoint
    BATCH_SUPPORTED_METHODS = %i[
      battery_capacity
      battery
      charge
      engine_oil
      fuel
      location
      odometer
      permissions
      tire_pressure
      vin
    ].freeze

    def initialize(token:, id:, options: { unit_system: IMPERIAL, version: Smartcar.get_api_version })
      super
      @token = token
      @id = id
      @unit_system = options[:unit_system]
      @version = options[:version]

      raise InvalidParameterValue.new, "Invalid Units provided : #{@unit_system}" unless UNITS.include?(@unit_system)
      raise InvalidParameterValue.new, 'Vehicle ID (id) is a required field' if id.nil?
      raise InvalidParameterValue.new, 'Access Token(token) is a required field' if token.nil?
    end

    # @!method permissions(options = {})
    # Fetch the list of permissions that this application has been granted for this vehicle
    #
    # API Documentation - https://smartcar.com/docs/api#get-application-permissions
    # @param options [Hash] Optional filter parameters (check documentation)
    #
    # @return [OpenStruct] And object representing the JSON response mentioned in https://smartcar.com/docs/api#get-application-permissions
    #  and a meta attribute with the response headers

    # @!method vehicle_attributes()
    # Returns make model year and id of the vehicle
    #
    # API Documentation - https://smartcar.com/api#get-vehicle-attributes
    #
    # @return [OpenStruct] And object representing the JSON response mentioned in https://smartcar.com/api#get-vehicle-attributes
    #  and a meta attribute with the response headers

    # @!method battery()
    # Returns the state of charge (SOC) and remaining range of an electric or plug-in hybrid vehicle's battery.
    #
    # API Documentation https://smartcar.com/docs/api#get-ev-battery
    #
    # @return [OpenStruct] And object representing the JSON response mentioned in https://smartcar.com/docs/api#get-ev-battery
    #  and a meta attribute with the response headers

    # @!method battery_capacity()
    # Returns the capacity of an electric or plug-in hybrid vehicle's battery.
    #
    # API Documentation https://smartcar.com/docs/api#get-ev-battery-capacity
    #
    # @return [OpenStruct] And object representing the JSON response mentioned in https://smartcar.com/docs/api#get-ev-battery-capacity
    #  and a meta attribute with the response headers

    # @!method charge()
    # Returns the current charge status of the vehicle.
    #
    # API Documentation https://smartcar.com/docs/api#get-ev-battery
    #
    # @return [OpenStruct] And object representing the JSON response mentioned in https://smartcar.com/docs/api#get-ev-battery
    #  and a meta attribute with the response headers

    # @!method engine_oil()
    # Returns the remaining life span of a vehicle's engine oil
    #
    # API Documentation https://smartcar.com/docs/api#get-engine-oil-life
    #
    # @return [OpenStruct] And object representing the JSON response mentioned in https://smartcar.com/docs/api#get-engine-oil-life
    #  and a meta attribute with the response headers

    # @!method fuel()
    # Returns the status of the fuel remaining in the vehicle's gas tank.
    #
    # API Documentation https://smartcar.com/docs/api#get-fuel-tank
    #
    # @return [OpenStruct] And object representing the JSON response mentioned in https://smartcar.com/docs/api#get-fuel-tank
    #  and a meta attribute with the response headers

    # @!method location()
    # Returns the last known location of the vehicle in geographic coordinates.
    #
    # API Documentation https://smartcar.com/docs/api#get-location
    #
    # @return [OpenStruct] And object representing the JSON response mentioned in https://smartcar.com/docs/api#get-location
    #  and a meta attribute with the response headers

    # @!method odometer()
    # Returns the vehicle's last known odometer reading.
    #
    # API Documentation https://smartcar.com/docs/api#get-odometer
    #
    # @return [OpenStruct] And object representing the JSON response mentioned in https://smartcar.com/docs/api#get-odometer
    #  and a meta attribute with the response headers

    # @!method tire_pressure()
    # Returns the air pressure of each of the vehicle's tires.
    #
    # API Documentation https://smartcar.com/docs/api#get-tire-pressure
    #
    # @return [OpenStruct] And object representing the JSON response mentioned in https://smartcar.com/docs/api#get-tire-pressure
    #  and a meta attribute with the response headers

    # @!method vin()
    # Returns the vehicle's manufacturer identifier (VIN).
    #
    # API Documentation https://smartcar.com/docs/api#get-vin
    #
    # @return [OpenStruct] And object representing the JSON response mentioned in https://smartcar.com/docs/api#get-vin
    #  and a meta attribute with the response headers

    METHODS.each do |method, item|
      define_method method do |options = {}|
        next if item[:skip]

        body, meta = case item[:type]
                     when :get
                       fetch(path: item[:path].call(id), options: options)
                     when :post
                       post(item[:path].call(id), item[:body])
                     when :delete
                       delete(item[:path].call(id))
                     else
                       next
                     end
        build_aliases(build_response(body, meta), item[:aliases])
      end
    end

    # Returns the vehicle's manufacturer identifier (VIN).
    # API - https://smartcar.com/docs/api#get-vin
    #
    # @return [String] Vin of the vehicle.
    def vin
      response, = fetch(path: METHODS[:vin][:path].call(id))
      response['vin']
    end

    # Method to get batch requests.
    # API - https://smartcar.com/docs/api#post-batch-request
    # @param paths [Array] Array of paths as strings. Ex ['/battery', '/odometer']
    #
    # @return [OpenStruct] Object with one attribute per requested path that returns
    #  an OpenStruct object of the requested attribute or taises if it is an error.
    def batch(paths)
      request_body = get_batch_request_body(paths)
      response, = post("/vehicles/#{id}/batch", request_body)
      process_batch_response(response)
    end
  end
end
