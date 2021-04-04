# frozen_string_literal: true

module Smartcar
  # Hidden class to represent vin
  #
  # @attr [String] vin Vin of the vehicle
  class Vin < Base
    # Path Proc for hitting vin end point
    PATH = proc { |id| "/vehicles/#{id}/vin" }
    attr_reader :vin
  end
end
