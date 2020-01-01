module Smartcar
  # class to represent Engine oil life
  #
  # @author [ashwin]
  #
  class Vin < Base
    include Utils
    PATH = Proc.new{|id| "/vehicles/#{id}/vin"}
    attr_accessor :vin
  end
end
