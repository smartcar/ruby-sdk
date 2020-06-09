module Smartcar
  # class to represent Battery info
  #@attr [Number] percentRemaining Decimal value representing the remaining charge percent.
  #@attr [Number] range Remaining range of the vehicle.
  class Battery < Base
    # Path Proc for hitting battery end point
    PATH = Proc.new{|id| "/vehicles/#{id}/battery"}
    attr_reader :percentRemaining, :range

    # just to have Ruby-esque method names
    alias_method :percentage_remaining, :percentRemaining
  end
end
