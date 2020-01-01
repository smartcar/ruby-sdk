module Smartcar
  # class to represent Engine oil life
  #
  # @author [ashwin]
  #
  class TirePressure < Base
    include Utils
    PATH = Proc.new{|id| "/vehicles/#{id}/tires/pressure"}
    attr_accessor :backLeft, :backRight, :frontLeft, :frontRight

    # just to have Ruby-esque method names
    alias_method :back_left, :backLeft
    alias_method :back_right, :backRight
    alias_method :front_left, :frontLeft
    alias_method :front_right, :frontRight
  end
end
