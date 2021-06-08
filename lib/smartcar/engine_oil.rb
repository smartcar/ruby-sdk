# frozen_string_literal: true

module Smartcar
  # class to represent Engine oil info
  # @attr [Number] lifeRemaining Remaining life of the engine oil
  class EngineOil < Base
    # Path Proc for hitting engine oil end point
    PATH = proc { |id| "/vehicles/#{id}/engine/oil" }
    attr_reader :lifeRemaining

    # just to have Ruby-esque method names
    alias life_remaining lifeRemaining
  end
end
