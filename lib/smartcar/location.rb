module Smartcar
  # class to represent Location info
  #
  # @author [ashwin]
  #
  class Location < Base
    include Utils
    PATH = Proc.new{|id| "/vehicles/#{id}/location"}
    attr_accessor :latitude, :longitude
  end
end
