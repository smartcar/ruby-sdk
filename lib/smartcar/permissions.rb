module Smartcar
  # class to get Charge info
  #
  # @author [ashwin]
  #
  class Permissions
    include Utils
    PATH = Proc.new{|id| "/vehicles/#{id}/permissions"}
    attr_accessor :permissions
  end
end
