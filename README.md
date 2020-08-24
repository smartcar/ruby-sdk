
# Smartcar Ruby SDK [![Gem Version][gem-url]][gem-image]

Ruby gem library to quickly get started with the Smartcar API.

## Overview

The [Smartcar API](https://smartcar.com/docs) lets you read vehicle data
(location, odometer) and send commands to vehicles (lock, unlock) using HTTP requests.

To make requests to a vehicle from a web or mobile application, the end user
must connect their vehicle using
[Smartcar Connect](https://smartcar.com/docs/api#smartcar-connect).
This flow follows the OAuth spec and will return a `code` which can be used to
obtain an access token from Smartcar.

The Smartcar Ruby Gem provides methods to:

1. Generate the link to redirect to Connect.
2. Make a request to Smartcar with the `code` obtained from Connect to obtain an
   access and refresh token
3. Make requests to the Smartcar API to read vehicle data and send commands to
   vehicles using the access token obtained in step 2.

Before integrating with Smartcar's SDK, you'll need to register an application
in the [Smartcar Developer portal](https://developer.smartcar.com). If you do
not have access to the dashboard, please
[request access](https://smartcar.com/subscribe).

### Flow

- Create a new `AuthClient` object with your `clientId`, `clientSecret`,
  `redirectUri`, and required `scope`.
- Redirect the user to Smartcar Connect using `getAuthUrl` or one
  of our frontend SDKs.
- The user will login, and then accept or deny your `scope`'s permissions.
- Handle the get request to `redirectUri`.
  - If the user accepted your permissions, `req.query.code` will contain an
    authorization code.
    - Use `exchangeCode` with this code to obtain an access object
      containing an access token (lasting 2 hours) and a refresh token
      (lasting 60 days).
      - Save this access object.
    - If the user denied your permissions, `req.query.error` will be set
      to `"access_denied"`.
    - If you passed a state parameter to `getAuthUrl`, `req.query.state` will
      contain the state value.
- Get the user's vehicles with `getVehicleIds`.
- Create a new `Vehicle` object using a `vehicleId` from the previous response,
  and the `access_token`.
- Make requests to the Smartcar API.
- Use `exchangeRefreshToken` on your saved `refreshToken` to retrieve a new token
  when your `accessToken` expires.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'smartcar'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install smartcar

## Usage

Setup the environment variables for CLIENT_ID and CLIENT_SECRET.
```bash
# Get your API keys from https://dashboard.smartcar.com/signup
export CLIENT_ID=<client id>
export CLIENT_SECRET=<client secret>
```

Example Usage for calling the reports API with oAuth token
```ruby
2.5.7 :001 > require 'smartcar'
 => true
2.5.7 :003 > ids =  Smartcar::Vehicle.all_vehicle_ids(token: token)
 => ["4bb777b2-bde7-4305-8952-25956f8c0868"]
2.5.7 :004 > vehicle = Smartcar::Vehicle.new(token: token, id: ids.first)
 => #<Smartcar::Vehicle:0x00005564211a7c48 @token="5ae77cb0-7c1a-486a-ac20-00c76d2fd1aa", @id="4bb777b2-bde7-4305-8952-25956f8c0868", @unit_system="imperial">
2.5.7 :006 > vehicle.odometer
 => #<Smartcar::Odometer:0x00005564211330f0 @distance=17966.94802354251, @meta={"date"=>"Fri, 12 Jun 2020 06:04:32 GMT", "content-type"=>"application/json; charset=utf-8", "content-length"=>"30", "connection"=>"keep-alive", "access-control-allow-origin"=>"*", "sc-data-age"=>"2020-06-12T06:04:28.843Z", "sc-unit-system"=>"imperial", "sc-request-id"=>"3c447e9e-4cf7-43cb-b688-fba8db3d3582"}>
2.5.7 :007 > vehicle.battery
 => #<Smartcar::Battery:0x00005564210fcb18 @range=105.63, @percentRemaining=0.98, @meta={"date"=>"Fri, 12 Jun 2020 06:04:44 GMT", "content-type"=>"application/json; charset=utf-8", "content-length"=>"40", "connection"=>"keep-alive", "access-control-allow-origin"=>"*", "sc-data-age"=>"2020-06-12T06:04:28.843Z", "sc-unit-system"=>"imperial", "sc-request-id"=>"455ed4b0-b768-4961-86d7-436ad71cf0fa"}>
2.5.7 :009 > vehicle.lock!
 => true
2.5.7 :010 > vehicle.batch(["charge","battery"])
=> {:charge=>#<Smartcar::Charge:0x000055853d1fd7c8 @state="NOT_CHARGING", @isPluggedIn=false, @meta={"sc-data-age"=>"2020-06-12T06:18:50.581Z"}>, :battery=>#<Smartcar::Battery:0x000055853d1fd638 @range=105.63, @percentRemaining=0.98, @meta={"sc-data-age"=>"2020-06-12T06:18:50.581Z", "sc-unit-system"=>"imperial"}>}
2.5.7 :011 > vehicle.start_charge!
Traceback (most recent call last):
        5: from /usr/share/rvm/rubies/ruby-2.5.7/bin/irb:11:in `<main>'
        4: from (irb):5
        3: from /home/st-2vgpnn2/.rvm/gems/ruby-2.5.7/gems/smartcar-1.0.0/lib/smartcar/vehicle.rb:118:in `start_charge!'
        2: from /home/st-2vgpnn2/.rvm/gems/ruby-2.5.7/gems/smartcar-1.0.0/lib/smartcar/vehicle.rb:290:in `start_or_stop_charge!'
        1: from /home/st-2vgpnn2/.rvm/gems/ruby-2.5.7/gems/smartcar-1.0.0/lib/smartcar/base.rb:39:in `block (2 levels) in <class:Base>'
Smartcar::ExternalServiceError (API error - {"error":"vehicle_state_error","message":"Charging plug is not connected to the vehicle.","code":"VS_004"})

```

Example Usage for oAuth -
```ruby
# To get the redirect URL :
2.5.5 :002 > options = {test_mode: true,scope: ["read_battery","read_charge","read_fuel","read_location","control_security","read_odometer","read_tires","read_vin","read_vehicle_info"]}
2.5.5 :003 > require 'smartcar'
2.5.5 :004 > url = Smartcar::Oauth.authorization_url(options)
 => "https://connect.smartcar.com/oauth/authorize?approval_prompt=auto&client_id=2715c6b2-eba8-4fda-85b1-8d849733a344&mode=test&redirect_uri=http%3A%2F%2Flocalhost%3A8000%2Fcallback&response_type=code&scope=read_battery+read_charge+read_fuel+read_location+control_security+read_odometer+read_tires+read_vin+read_vehicle_info"
# Redirect user to the above URL.
# After authentication user control reaches the callback URL with code.
# Use the code from the parameters and request a token
2.5.5 :006 > token_hash = Smartcar::Oauth.get_token(code)
 => {"token_type"=>"Bearer", :access_token=>"56801a5e-6a0b-4d05-a43e-52a4d5e6648f", :refresh_token=>"4f46e7e4-28c5-47b3-ba8d-7dcef73d05dd", :expires_at=>1577875279}
# This access_token can be used to call the Smartcar APIs as given above.
# Store this hash and if it expired refresh the token OR use the code again to
# get a new token or use .
```

## Development

To install this gem onto your local machine, run `bundle exec rake install`.

To run tests, make sure you have the env variables setup for client id and secret.
```shell
export INTEGRATION_CLIENT_ID=<client id>
export INTEGRATION_CLIENT_SECRET=<client secret>
```

Tests can be run using either default rake command OR specific rspec command.
```ruby
bundle exec rake spec
```

Releasing to rubygems right now cannot be automated because of MFA ([source](https://github.com/rubygems/rubygems/issues/3092)). For now the process is to run the gem build and push commands locally and manually enter in the Rubygems MFA code (available on 1password). Steps for that would be :

```
# After merging to master, checkout to master and pull code locally, then run the following
gem build
  Successfully built RubyGem
  Name: smartcar
  Version: <version>
  File: smartcar-<version>.gem
# now push the gem built by the build command. This would ask for the MFA code
gem push smartcar-<version>.gem
```
In general it is a good advice to create a tag for every release. If not for the above mentioned MFA bug, creating a tag for a commit on master and pushing the tag would trigger travis to deploy to rubygems automatically.

## Contributing

To contribute, please:

1. Open an issue for the feature (or bug) you would like to resolve.
2. Resolve the issue and add tests in your feature branch.
3. Open a PR from your feature branch into `develop` that tags the issue.

[gem-image]: https://badge.fury.io/rb/smartcar
[gem-url]: https://badge.fury.io/rb/smartcar.svg
