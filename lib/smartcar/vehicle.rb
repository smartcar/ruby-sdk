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
      permissions: { path: proc { |id| "/vehicles/#{id}/permissions" }, skip: true },
      attributes: { path: proc { |id| "/vehicles/#{id}" } },
      battery: {
        path: proc { |id| "/vehicles/#{id}/battery" },
        aliases: { 'percentRemaining' => 'percentage_remaining' }
      },
      battery_capacity: { path: proc { |id| "/vehicles/#{id}/battery/capacity" } },
      charge: {
        path: proc { |id| "/vehicles/#{id}/charge" },
        aliases: { 'isPluggedIn' => 'is_plugged_in?' }
      },
      engine_oil: {
        path: proc { |id| "/vehicles/#{id}/engine/oil" },
        aliases: { 'lifeRemaining' => 'life_remaining' }
      },
      fuel: {
        path: proc { |id| "/vehicles/#{id}/fuel" },
        aliases: {
          'amountRemaining' => 'amount_remaining',
          'percentRemaining' => 'percent_remaining'
        }
      },
      location: { path: proc { |id| "/vehicles/#{id}/location" } },
      odometer: { path: proc { |id| "/vehicles/#{id}/odometer" } },
      tire_pressure: {
        path: proc { |id| "/vehicles/#{id}/tires/pressure" },
        aliases: {
          'backLeft' => 'back_left',
          'backRight' => 'back_right',
          'frontLeft' => 'front_left',
          'frontRight' => 'front_right'
        }
      },
      vin: { path: proc { |id| "/vehicles/#{id}/vin" } },
      disconnect!: { type: :delete, path: proc { |id| "/vehicles/#{id}/application" } },
      lock!: { type: :post, path: proc { |id| "/vehicles/#{id}/security" }, body: { action: LOCK } },
      unlock!: { type: :post, path: proc { |id| "/vehicles/#{id}/security" }, body: { action: UNLOCK } },
      start_charge!: { type: :post, path: proc { |id| "/vehicles/#{id}/charge" }, body: { action: START_CHARGE } },
      stop_charge!: { type: :post, path: proc { |id| "/vehicles/#{id}/charge" }, body: { action: STOP_CHARGE } },
      subscribe!: {
        type: :post,
        path: proc { |id, webhook_id| "/vehicles/#{id}/webhooks/#{webhook_id}" },
        aliases: {
          'webhookId' => 'webhook_id',
          'vehicleId' => 'vehicle_id'
        }
      },
      unsubscribe!: { type: :post, path: proc { |id, webhook_id| "/vehicles/#{id}/webhooks/#{webhook_id}" } }
    }.freeze

    def initialize(token:, id:, options: { unit_system: METRIC, version: Smartcar.get_api_version })
      super
      @token = token
      @id = id
      @unit_system = options[:unit_system]
      @version = options[:version]

      raise InvalidParameterValue.new, "Invalid Units provided : #{@unit_system}" unless UNITS.include?(@unit_system)
      raise InvalidParameterValue.new, 'Vehicle ID (id) is a required field' if id.nil?
      raise InvalidParameterValue.new, 'Access Token(token) is a required field' if token.nil?
    end

    # @!method attributes()
    # Returns make model year and id of the vehicle
    #
    # API Documentation - https://smartcar.com/api#get-vehicle-attributes
    #
    # @return [OpenStruct] And object representing the JSON response mentioned in https://smartcar.com/api#get-vehicle-attributes
    #  and a meta attribute with the relevant items from response headers.

    # @!method battery()
    # Returns the state of charge (SOC) and remaining range of an electric or plug-in hybrid vehicle's battery.
    #
    # API Documentation https://smartcar.com/docs/api#get-ev-battery
    #
    # @return [OpenStruct] And object representing the JSON response mentioned in https://smartcar.com/docs/api#get-ev-battery
    #  and a meta attribute with the relevant items from response headers.

    # @!method battery_capacity()
    # Returns the capacity of an electric or plug-in hybrid vehicle's battery.
    #
    # API Documentation https://smartcar.com/docs/api#get-ev-battery-capacity
    #
    # @return [OpenStruct] And object representing the JSON response mentioned in https://smartcar.com/docs/api#get-ev-battery-capacity
    #  and a meta attribute with the relevant items from response headers.

    # @!method charge()
    # Returns the current charge status of the vehicle.
    #
    # API Documentation https://smartcar.com/docs/api#get-ev-battery
    #
    # @return [OpenStruct] And object representing the JSON response mentioned in https://smartcar.com/docs/api#get-ev-battery
    #  and a meta attribute with the relevant items from response headers.

    # @!method engine_oil()
    # Returns the remaining life span of a vehicle's engine oil
    #
    # API Documentation https://smartcar.com/docs/api#get-engine-oil-life
    #
    # @return [OpenStruct] And object representing the JSON response mentioned in https://smartcar.com/docs/api#get-engine-oil-life
    #  and a meta attribute with the relevant items from response headers.

    # @!method fuel()
    # Returns the status of the fuel remaining in the vehicle's gas tank.
    #
    # API Documentation https://smartcar.com/docs/api#get-fuel-tank
    #
    # @return [OpenStruct] And object representing the JSON response mentioned in https://smartcar.com/docs/api#get-fuel-tank
    #  and a meta attribute with the relevant items from response headers.

    # @!method location()
    # Returns the last known location of the vehicle in geographic coordinates.
    #
    # API Documentation https://smartcar.com/docs/api#get-location
    #
    # @return [OpenStruct] And object representing the JSON response mentioned in https://smartcar.com/docs/api#get-location
    #  and a meta attribute with the relevant items from response headers.

    # @!method odometer()
    # Returns the vehicle's last known odometer reading.
    #
    # API Documentation https://smartcar.com/docs/api#get-odometer
    #
    # @return [OpenStruct] And object representing the JSON response mentioned in https://smartcar.com/docs/api#get-odometer
    #  and a meta attribute with the relevant items from response headers.

    # @!method tire_pressure()
    # Returns the air pressure of each of the vehicle's tires.
    #
    # API Documentation https://smartcar.com/docs/api#get-tire-pressure
    #
    # @return [OpenStruct] And object representing the JSON response mentioned in https://smartcar.com/docs/api#get-tire-pressure
    #  and a meta attribute with the relevant items from response headers.

    # @!method vin()
    # Returns the vehicle's manufacturer identifier (VIN).
    #
    # API Documentation https://smartcar.com/docs/api#get-vin
    #
    # @return [OpenStruct] And object representing the JSON response mentioned in https://smartcar.com/docs/api#get-vin
    #  and a meta attribute with the relevant items from response headers.

    # NOTES :
    # - We only generate the methods where there is no query string or additional options considering thats
    #   the majority, for all the ones that require parameters, write them separately.
    #   Ex. permissions, subscribe, unsubscribe
    # - The following snippet generates methods dynamically , but if we are adding a new item,
    #   make sure we also add the doc for it.
    METHODS.each do |method, item|
      # We add these to the METHODS object to keep it in one place, but mark them to be skipped
      # for dynamic generation
      next if item[:skip]

      define_method method do
        body, headers = case item[:type]
                        when :post
                          post(item[:path].call(id), item[:body])
                        when :delete
                          delete(item[:path].call(id))
                        else
                          fetch(path: item[:path].call(id))
                        end
        build_aliases(build_response(body, headers), item[:aliases])
      end
    end

    # Method to fetch the list of permissions that this application has been granted for this vehicle.
    # API - https://smartcar.com/docs/api#get-application-permissions
    #
    # @param paging [Hash] Optional filter parameters (check documentation)
    #
    # @return [OpenStruct] And object representing the JSON response mentioned in https://smartcar.com/docs/api#get-application-permissions
    #  and a meta attribute with the relevant items from response headers.
    def permissions(paging = {})
      response, headers = fetch(path: METHODS.dig(:permissions, :path).call(id), options: paging)
      build_response(response, headers)
    end

    # Subscribe the vehicle to given webhook Id.
    #
    # @param webhook_id [String] Webhook id to subscribe to
    #
    # @return [OpenStruct] And object representing the JSON response and a meta attribute
    #   with the relevant items from response headers.
    def subscribe!(webhook_id)
      response, headers = post(METHODS.dig(:subscribe!, :path).call(id, webhook_id), {})
      build_aliases(build_response(response, headers), METHODS.dig(:subscribe!, :aliases))
    end

    # Unubscribe the vehicle from given webhook Id.
    #
    # @param amt [String] Application management token
    # @param webhook_id [String] Webhook id to subscribe to
    #
    # @return [OpenStruct] Meta attribute with the relevant items from response headers.
    def unsubscribe!(amt, webhook_id)
      # swapping off the token with amt for unsubscribe.
      access_token = token
      self.token = amt
      response, headers = delete(METHODS.dig(:unsubscribe!, :path).call(id, webhook_id))
      self.token = access_token
      build_response(response, headers)
    end

    # Method to get batch requests.
    # API - https://smartcar.com/docs/api#post-batch-request
    # @param paths [Array] Array of paths as strings. Ex ['/battery', '/odometer']
    #
    # @return [OpenStruct] Object with one attribute per requested path that returns
    #  an OpenStruct object of the requested attribute or taises if it is an error.
    def batch(paths)
      request_body = { requests: paths.map { |path| { path: path } } }
      response, headers = post("/vehicles/#{id}/batch", request_body)
      process_batch_response(response, headers)
    end
  end
end
