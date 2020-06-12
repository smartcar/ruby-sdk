module Smartcar
  # Class to get to user API.
  #@attr [String] id Smartcar user id.
  #@attr [String] token Access token used to connect to Smartcar API.
  class User < Base
    # Path  for hitting user end point
    USER_PATH = '/user'.freeze
    attr_reader :id, :token

    def initialize(token:)
      raise InvalidParameterValue.new, "Access Token(token) is a required field" if token.nil?
      @token = token
    end

    # Class method Used to get user id
    # EX : Smartcar::User.fetch
    # API - https://smartcar.com/docs/api#get-user
    # @param token [String] Access token
    #
    # @return [User] object
    def self.user_id(token:)
      new(token: token).get(USER_PATH)['id']
    end

  end
end
