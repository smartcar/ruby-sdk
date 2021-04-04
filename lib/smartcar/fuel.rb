# frozen_string_literal: true

module Smartcar
  # class to represent Fuel info
  # @attr [Number] amountRemaining Amount of fuel remaining.
  # @attr [Number] percentageRemaining Decimal value representing the remaining fuel percent.
  # @attr [Number] range Remaining range of the vehicle.
  class Fuel < Base
    # Path Proc for hitting fuel end point
    PATH = proc { |id| "/vehicles/#{id}/fuel" }
    attr_reader :amountRemaining, :percentRemaining, :range

    # just to have Ruby-esque method names
    alias amount_remaining amountRemaining
    alias percent_remaining percentRemaining
  end
end
