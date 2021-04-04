# frozen_string_literal: true

module Smartcar
  # class to represent permissions response
  # @attr [Array] permissions Array of permissions granted on the vehicle.
  class Permissions < Base
    # Path Proc for hitting permissions end point
    PATH = proc { |id| "/vehicles/#{id}/permissions" }
    attr_reader :permissions
  end
end
