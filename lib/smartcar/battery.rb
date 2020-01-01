module Smartcar
  # class to represent battery info
  #
  # @author [ashwin]
  #
  class Battery < Base
    include Utils
    PATH = Proc.new{|id| "/vehicles/#{id}/battery"}
    attr_accessor :percentRemaining, :range

    # just to have Ruby-esque method names
    alias_method :percentage_remaining, :percentRemaining
  end
end
