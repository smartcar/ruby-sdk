module Smartcar
  # Hidden class to represent vin
  #
  #@attr [String] vin Vin of the vehicle
  class Vin < Base
    # Path Proc for hitting vin end point
    PATH = Proc.new{|id| "/vehicles/#{id}/vin"}
    attr_reader :vin
  end
end
