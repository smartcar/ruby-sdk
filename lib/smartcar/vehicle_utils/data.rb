# frozen_string_literal: true

module Smartcar
  module VehicleUtils
    # Data module has all the data accessor methods here to declutter Vehicle class
    module Data
      # Fetch the list of permissions that this application has been granted for
      # this vehicle
      # EX : Smartcar::Vehicle.new(token: token, id: id).permissions
      # @param options [Hash] - Optional filter parameters (check documentation)
      #
      # @return [Permissions] object
      def permissions(options: {})
        get_attribute(klass: Permissions, options: options)
      end

      # Returns make model year and id of the vehicle
      # API - https://smartcar.com/api#get-vehicle-attributes
      #
      # @return [VehicleAttributes] object
      def vehicle_attributes
        get_attribute(klass: VehicleAttributes)
      end

      # Returns the state of charge (SOC) and remaining range of an electric or
      # plug-in hybrid vehicle's battery.
      # API - https://smartcar.com/docs/api#get-ev-battery
      #
      # @return [Battery] object
      def battery
        get_attribute(klass: Battery)
      end

      # Returns the capacity of an electric or
      # plug-in hybrid vehicle's battery.
      # API - https://smartcar.com/docs/api#get-ev-battery-capacity
      #
      # @return [Battery] object
      def battery_capacity
        get_attribute(klass: BatteryCapacity)
      end

      # Returns the current charge status of the vehicle.
      # API - https://smartcar.com/docs/api#get-ev-battery
      #
      # @return [Charge] object
      def charge
        get_attribute(klass: Charge)
      end

      # Returns the remaining life span of a vehicle's engine oil
      # API - https://smartcar.com/docs/api#get-engine-oil-life
      #
      # @return [EngineOil] object
      def engine_oil
        get_attribute(klass: EngineOil)
      end

      # Returns the status of the fuel remaining in the vehicle's gas tank.
      # API - https://smartcar.com/docs/api#get-fuel-tank
      #
      # @return [Fuel] object
      def fuel
        get_attribute(klass: Fuel)
      end

      # Returns the last known location of the vehicle in geographic coordinates.
      # API - https://smartcar.com/docs/api#get-location
      #
      # @return [Location] object
      def location
        get_attribute(klass: Location)
      end

      # Returns the vehicle's last known odometer reading.
      # API - https://smartcar.com/docs/api#get-odometer
      #
      # @return [Odometer] object
      def odometer
        get_attribute(klass: Odometer)
      end

      # Returns the air pressure of each of the vehicle's tires.
      # API - https://smartcar.com/docs/api#get-tire-pressure
      #
      # @return [TirePressure] object
      def tire_pressure
        get_attribute(klass: TirePressure)
      end

      # Returns the vehicle's manufacturer identifier (VIN).
      # API - https://smartcar.com/docs/api#get-vin
      #
      # @return [String] Vin of the vehicle.
      def vin
        @vin ||= get_attribute(klass: Vin).vin
      end

      private

      def get_attribute(klass:, options: {})
        body, meta = fetch(
          path: klass::PATH.call(id),
          options: options
        )
        klass.new(body.merge(meta: meta))
      end
    end
  end
end
