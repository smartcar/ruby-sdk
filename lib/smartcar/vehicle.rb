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
  # @attr flags [Hash] Object of flags where key is the name of the flag and value is string or boolean value.
  # @attr service [Faraday::Connection] An optional connection object to be used for requests.
  class Vehicle < Base
    attr_reader :id

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
      service_history: {
        path: proc { |id, start_date = nil, end_date = nil|
          base_path = "/vehicles/#{id}/service/history"
          query_params = []
          query_params << "start_date=#{start_date}" unless start_date.nil?
          query_params << "end_date=#{end_date}" unless end_date.nil?
          "#{base_path}?#{query_params.join('&')}" unless query_params.empty?
        },
        skip: true
      },
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
      get_charge_limit: { path: proc { |id| "/vehicles/#{id}/charge/limit" } },
      disconnect!: { type: :delete, path: proc { |id| "/vehicles/#{id}/application" } },
      lock_status: {
        path: proc { |id| "/vehicles/#{id}/security" },
        aliases: {
          'isLocked' => 'is_locked',
          'chargingPort' => 'charging_port'
        }
      },
      lock!: { type: :post, path: proc { |id| "/vehicles/#{id}/security" }, body: { action: 'LOCK' } },
      unlock!: { type: :post, path: proc { |id| "/vehicles/#{id}/security" }, body: { action: 'UNLOCK' } },
      start_charge!: { type: :post, path: proc { |id| "/vehicles/#{id}/charge" }, body: { action: 'START' } },
      stop_charge!: { type: :post, path: proc { |id| "/vehicles/#{id}/charge" }, body: { action: 'STOP' } },
      set_charge_limit!: {
        type: :post,
        path: proc { |id| "/vehicles/#{id}/charge/limit" },
        body: proc { |limit| { limit: limit } },
        skip: true
      },
      send_destination!: {
        type: :post,
        path: proc { |id| "/vehicles/#{id}/navigation/destination" },
        body: proc { |latitude, longitude| { latitude: latitude, longitude: longitude } },
        skip: true
      },
      subscribe!: {
        type: :post,
        path: proc { |id, webhook_id| "/vehicles/#{id}/webhooks/#{webhook_id}" },
        aliases: {
          'webhookId' => 'webhook_id',
          'vehicleId' => 'vehicle_id'
        },
        skip: true
      },
      unsubscribe!: { type: :post, path: proc { |id, webhook_id|
                                           "/vehicles/#{id}/webhooks/#{webhook_id}"
                                         }, skip: true }
    }.freeze

    def initialize(token:, id:, options: {})
      super
      @token = token
      @id = id
      @unit_system = options[:unit_system] || METRIC
      @version = options[:version] || Smartcar.get_api_version
      @service = options[:service]
      @query_params = { flags: stringify_params(options[:flags]) }

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

    # @!method lock_status()
    # Returns the lock status for a vehicle and the open status of its doors, windows, storage units,
    # sunroof and charging port where available. The open status array(s) will be empty if a vehicle
    # has partial support. The request will error if lock status can not be retrieved from the vehicle or
    # the brand is not supported.
    #
    # API Documentation https://smartcar.com/docs/api#get-security
    #
    # @return [OpenStruct] And object representing the JSON response mentioned in https://smartcar.com/docs/api#get-security
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
                          post(item[:path].call(id), @query_params, item[:body])
                        when :delete
                          delete(item[:path].call(id), @query_params)
                        else
                          get(item[:path].call(id), @query_params)
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
      response, headers = get(METHODS.dig(:permissions, :path).call(id), @query_params.merge(paging))
      build_response(response, headers)
    end

    # Retrieves a list of service records for the vehicle, optionally filtered by a specified date range.
    # If no dates are specified, the method defaults to returning records from the last year.
    #
    # This method calls the Smartcar API to fetch the vehicle's service history and processes the
    # response to return structured data.
    #
    # @param start_date [String, nil] the start date of the period from which records are retrieved (inclusive).
    #                                 Expected in 'YYYY-MM-DD' format. If nil, defaults to one year ago from today.
    # @param end_date [String, nil] the end date of the period until which records are retrieved (inclusive).
    #                               Expected in 'YYYY-MM-DD' format. If nil, defaults to today's date.
    #
    # @return [OpenStruct] An object representing the parsed JSON response from the API, with service history
    #         data and metadata extracted from the response headers.
    #
    # Example usage:
    #   vehicle.service_history('2021-01-01', '2021-12-31')
    #
    # Note: This method assumes that the necessary error handling is embedded within the `get` method or handled
    #       externally when exceptions arise due to network issues, API limitations, or data encoding problems.
    def service_history(start_date = nil, end_date = nil)
      start_date, end_date = default_date_range if start_date.nil? || end_date.nil?

      path = METHODS[:service_history][:path].call(id, start_date, end_date)
      body, headers = get(path, @query_params)
      build_response(body, headers)
    end

    # Utility method to provide default dates
    def default_date_range
      end_date = DateTime.now.new_offset(0).to_date
      start_date = end_date - 365
      [start_date.to_s, end_date.to_s]
    end

    # Subscribe the vehicle to given webhook Id.
    #
    # @param webhook_id [String] Webhook id to subscribe to
    #
    # @return [OpenStruct] An object representing the JSON response and a meta attribute
    #   with the relevant items from response headers.
    def subscribe!(webhook_id)
      response, headers = post(METHODS.dig(:subscribe!, :path).call(id, webhook_id), @query_params)
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
      response, headers = delete(METHODS.dig(:unsubscribe!, :path).call(id, webhook_id),
                                 @query_params)
      self.token = access_token
      build_response(response, headers)
    end

    # Set the charge limit for a given vehicle
    #
    # @param limit [float] A value between 0 and 1 denoting the charge limit to be set.
    #
    # @return [OpenStruct] Meta attribute with the relevant items from response headers.
    def set_charge_limit!(limit)
      path = METHODS.dig(:set_charge_limit!, :path).call(id)
      body = METHODS.dig(:set_charge_limit!, :body).call(limit)

      response, headers = post(path, {}, body)
      build_response(response, headers)
    end

    # Send coordinates to the vehicle's navigation system
    #
    # @param latitude [float] value representing the destination's latitude
    # @param longitude [float] value representing the destination's longitude

    # @return [OpenStruct] Meta attribute with the relevant items from response headers
    def send_destination!(latitude, longitude)
      method_config = METHODS[:send_destination!]

      response, headers = post(method_config[:path].call(id), @query_params,
                               method_config[:body].call(latitude, longitude))
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
      response, headers = post("/vehicles/#{id}/batch", @query_params, request_body)
      process_batch_response(response, headers)
    end

    # General purpose method to make requests to the Smartcar API - can be
    # used to make requests to brand specific endpoints.
    #
    # @param method [String] The HTTP request method to use.
    # @param path [String] The path to make the request to.
    # @param body [Hash] The request body.
    # @param headers [Hash] The headers to inlcude in the request.
    #
    # @return [OpenStruct] An object with a "body" attribute that contains the
    #   response body and a "meta" attribute with the relevant items from response headers.
    def request(method, path, body = {}, headers = {})
      path = "/vehicles/#{id}/#{path}"
      raw_response, headers = send(method.downcase, path, @query_params, body, headers)
      meta = build_meta(headers)
      json_to_ostruct({ body: raw_response, meta: meta })
    end
  end
end
