module Smartcar
  # class to represent Engine oil life
  #
  # @author [ashwin]
  #
  class EngineOil < Base
    include Utils
    PATH = Proc.new{|id| "/vehicles/#{id}/engine/oil"}
    attr_accessor :lifeRemaining

    # just to have Ruby-esque method names
    alias_method :life_remaining, :lifeRemaining
  end
end
