# frozen_string_literal: true

module Smartcar
  # class to represent Tire Pressure response
  # @attr [Number] back_left Last recorded tire pressure of the back left tire.
  # @attr [Number] back_right Last recorded tire pressure of the back right tire.
  # @attr [Number] front_left Last recorded tire pressure of the front left tire.
  # @attr [Number] front_right Last recorded tire pressure of the front right tire.
  class TirePressure < Base
    # Path Proc for hitting tire pressure end point
    PATH = proc { |id| "/vehicles/#{id}/tires/pressure" }
    attr_reader :backLeft, :backRight, :frontLeft, :frontRight

    # just to have Ruby-esque method names
    alias back_left backLeft
    alias back_right backRight
    alias front_left frontLeft
    alias front_right frontRight
  end
end
