# frozen_string_literal: true

module Smartcar
  module VehicleUtils
    # Actions module has all the action methods here to declutter Vehicle class
    module Actions
      #  Method Used toRevoke access for the current requesting application
      # API - https://smartcar.com/docs/api#delete-disconnect
      #
      # @return [Boolean] true if success
      def disconnect!
        response, = delete("#{Smartcar::Vehicle::PATH.call(id)}/application")
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

      private

      def lock_or_unlock!(action:)
        response, = post("#{Smartcar::Vehicle::PATH.call(id)}/security", { action: action })
        response['status'] == SUCCESS
      end

      def start_or_stop_charge!(action:)
        response, = post("#{Smartcar::Vehicle::PATH.call(id)}/charge", { action: action })
        response['status'] == SUCCESS
      end
    end
  end
end
