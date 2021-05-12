module Smartcar
  # Class to get to user API.
  #@attr [String] id Smartcar user id.
  #@attr [String] token Access token used to connect to Smartcar API.
  class User < Base
    # Path  for hitting user end point
    USER_PATH = '/user'.freeze
    attr_reader :id

    # Class method Used to get user id
    # EX : Smartcar::User.user_id
    # API - https://smartcar.com/docs/api#get-user
    # @param token [String] Access token
    #
    # @return [String] User ID
    def self.user_id(token:, version: Smartcar.get_api_version)
      # @deprecated Please use {#get} instead
      warn "[DEPRECATION] `Smartcar::User.user_id` is deprecated and will be removed in next major version update.  Please use `Smartcar::User.get` instead."
      get(token: token, version: version).id
    end

    # Class method Used to get user id
    # EX : Smartcar::User.get
    # API - https://smartcar.com/docs/api#get-user
    # @param token [String] Access token
    #
    # @return [User] User object
    def self.get(token:, version: Smartcar.get_api_version)
      user = new(token: token, version: version)
      body, _meta = user.fetch(path: USER_PATH)
      user.instance_variable_set('@id', body['id'])
      user
    end
  end
end
