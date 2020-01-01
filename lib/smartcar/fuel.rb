module Smartcar
  # class to represent Fuel info
  #
  # @author [ashwin]
  #
  class Fuel < Base
    include Utils
    PATH = Proc.new{|id| "/vehicles/#{id}/fuel"}
    attr_accessor :amountRemaining, :percentRemaining, :range

    # just to have Ruby-esque method names
    alias_method :amount_remaining, :amountRemaining
    alias_method :percent_remaining, :percentRemaining
  end
end
