module Smartcar
  # class to represent Odometer
  #@attr [Number] distanceLast recorded odometer reading.
  class Odometer < Base
    # Path Proc for hitting odometer end point
    PATH = Proc.new{|id| "/vehicles/#{id}/odometer"}
    attr_reader :distance
  end
end
