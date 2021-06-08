# frozen_string_literal: true

module Smartcar
  # class to represent Charge info
  # @attr [Boolean] isPluggedIn Specifies if the vehicle is plugged in.
  # @attr [String] state Charging state of the vehicle.
  class Charge < Base
    # Path Proc for hitting charge end point
    PATH = proc { |id| "/vehicles/#{id}/charge" }
    attr_reader :isPluggedIn, :state

    # just to have Ruby-esque method names
    alias is_plugged_in? isPluggedIn
  end
end
