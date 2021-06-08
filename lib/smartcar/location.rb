# frozen_string_literal: true

module Smartcar
  # class to represent Location info
  # @attr [Number] latitude Latitude of last recorded location.
  # @attr [Number] longitude Longitude of last recorded location.
  class Location < Base
    # Path Proc for hitting location end point
    PATH = proc { |id| "/vehicles/#{id}/location" }
    attr_reader :latitude, :longitude
  end
end
