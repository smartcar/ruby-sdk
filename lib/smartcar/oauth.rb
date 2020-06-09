module Smartcar
  # Oauth class to take care of the Oauth 2.0 with genomelink APIs
  #
  class Oauth < Base
    extend Utils
    class << self
      # Generate the OAuth authorization URL.
      #
      # By default users are not shown the permission dialog if they have already
      # approved the set of scopes for this application. The application can elect
      # to always display the permissions dialog to the user by setting
      # approval_prompt to `force`.
      #
      # @param options [Hash]
      # @option options[:state] [String] - OAuth state parameter passed to the
      # redirect uri. This parameter may be used for identifying the user who
      # initiated the request.
      # @option options[:test_mode] [Boolean] - Setting this to 'true' runs it in test mode.
      # @option options[:force_prompt] [Boolean] - Setting `force_prompt` to
      # `true` will show the permissions approval screen on every authentication
      # attempt, even if the user has previously consented to the exact scope of
      # permissions.
      # @option options[:make] [String] - `make' is an optional parameter that allows
      # users to bypass the car brand selection screen.
      # For a complete list of supported makes, please see our
      # [API Reference](https://smartcar.com/docs/api#authorization) documentation.
      # @option options[:scope] [Array of Strings] - array of scopes that specify what the user can access
      #   EXAMPLE : ['read_odometer', 'read_vehicle_info', 'required:read_location']
      # For further details refer to https://smartcar.com/docs/guides/scope/
      #
      # @return [String] URL where user needs to be redirected for authorization
      def authorization_url(options)
        parameters = {
          redirect_uri: get_config('REDIRECT_URI'),
          approval_prompt: options[:force_prompt] ? FORCE : AUTO,
          mode: options[:test_mode] ? TEST : LIVE,
          response_type: CODE
        }
        parameters[:scope] = options[:scope].join(' ') if options[:scope]
        %I(state make).each do |parameter|
          parameters[:parameter] = options[:parameter] unless options[:parameter].nil?
        end

        client.auth_code.authorize_url(parameters)
      end

      # [get_token description]
      # @param auth_code [String] This is the code that is returned after use r
      # visits and authorizes on the authorization URL.
      #
      # @return [Hash] Hash of token, refresh token, expiry info and token type
      def get_token(auth_code)
        client.auth_code
          .get_token(
            auth_code,
            redirect_uri: get_config('REDIRECT_URI')
          ).to_hash
      end

      # [refresh_token description]
      # @param token_hash [Hash] This is the hash that is returned with the
      # get_token method
      #
      # @return [Hash] Hash of token, refresh token, expiry info and token type
      def refresh_token(token_hash)
        token_object = OAuth2::AccessToken.from_hash(client, token_hash)
        token_object = token_object.refresh!
        token_object.to_hash
      end

      private
      # gets the Oauth Client object
      #
      # @return [OAuth2::Client] A Oauth Client object.
      def client
        @client ||= OAuth2::Client.new( get_config('CLIENT_ID'),
          get_config('CLIENT_SECRET'),
          :site => OAUTH_PATH
        )
      end
    end
  end
end
