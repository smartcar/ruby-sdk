module Smartcar
  # class to represent Vehicle attributes like make model year
  #@attr [String] id Smartcar vehicle ID
  #@attr [String] make Manufacturer of the vehicle.
  #@attr [String] model Model of the vehicle.
  #@attr [Number] year Model year of the vehicle.
  class VehicleAttributes < Base
    # Path Proc for hitting vehicle attributes end point
    PATH = Proc.new{|id| "/vehicles/#{id}"}
    attr_accessor :id, :make, :model, :year
  end
end
