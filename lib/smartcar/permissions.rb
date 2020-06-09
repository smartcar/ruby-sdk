module Smartcar
  # class to represent permissions response
  #@attr [Array] permissions Array of permissions granted on the vehicle.
  class Permissions < Base
    # Path Proc for hitting permissions end point
    PATH = Proc.new{|id| "/vehicles/#{id}/permissions"}
    attr_reader :permissions
  end
end
