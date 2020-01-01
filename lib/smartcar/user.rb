module Smartcar
  # Class to get to user API.
  #
  # @author [ashwin]
  #
  class User < Base
    USER_PATH = '/user'.freeze
    attr_accessor :id, :token

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
