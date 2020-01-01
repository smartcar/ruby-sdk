module Smartcar
  # class to represent Charge info
  #
  # @author [ashwin]
  #
  class Charge < Base
    include Utils
    PATH = Proc.new{|id| "/vehicles/#{id}/charge"}
    attr_accessor :isPluggedIn, :state

    # just to have Ruby-esque method names
    alias_method :is_plugged_in?, :isPluggedIn
  end
end
