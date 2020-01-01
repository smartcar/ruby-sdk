module Smartcar
  # class to get Charge info
  #
  # @author [ashwin]
  #
  class Odometer < Base
    include Utils
    PATH = Proc.new{|id| "/vehicles/#{id}/odometer"}
    attr_accessor :distance
  end
end
