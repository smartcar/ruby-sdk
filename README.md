
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
2.5.5 :003 > require 'smartcar'
 => true
2.5.5 :009 > ids =  Smartcar::Vehicle.all_vehicle_ids(token: token)
 => ["35e8a7c4-9e5c-4eb6-b552-7509e371669a", "c3332c35-fdeb-4780-a84b-706b7364979a", "d10ad5cf-5469-467e-972e-90427981873f", "fab5a744-6488-40d8-a6dd-41f0a804d44f"]
2.5.5 :010 > vehicle = Smartcar::Vehicle.new(token: token, id: ids.first)
 => #<Smartcar::Vehicle:0x00007fbad71aa2b8 @token="56801a5e-6a0b-4d05-a43e-52a4d5e6648f", @id="35e8a7c4-9e5c-4eb6-b552-7509e371669a", @unit_system="imperial">
2.5.5 :011 > vehicle.permissions
 => #<Smartcar::Odometer:0x00007fbad63851f0 @permissions=["control_security", "read_battery", "read_charge", "read_location", "read_odometer", "read_vehicle_info", "read_vin"]>
2.5.5 :012 > vehicle.odometer
 => #<Smartcar::Odometer:0x00007fbad718a3f0 @distance=74988.44443760936>
2.5.5 :013 > vehicle.battery
 => #<Smartcar::Battery:0x00007fbad50f4c80 @range=134.35, @percentRemaining=0.02>
2.5.5 :014 > vehicle.charge
 => #<Smartcar::Charge:0x00007fbad787e620 @state="FULLY_CHARGED", @isPluggedIn=true>
2.5.5 :015 > vehicle.lock!
 => true
2.5.5 :016 > vehicle.start_charge!
Traceback (most recent call last):
        8: from /usr/share/rvm/rubies/ruby-2.5.5/bin/irb:23:in `<main>'
        7: from /usr/share/rvm/rubies/ruby-2.5.5/bin/irb:23:in `load'
        6: from /usr/share/rvm/rubies/ruby-2.5.5/lib/ruby/gems/2.7.0/gems/irb-1.2.1/exe/irb:11:in `<top (required)>'
        5: from (irb):7
        4: from (irb):8:in `rescue in irb_binding'
        3: from /home/st-2vgpnn2/.rvm/gems/ruby-2.5.5/gems/smartcar-0.1.2/lib/smartcar/vehicle.rb:102:in `block (2 levels) in <class:Vehicle>'
        2: from /home/st-2vgpnn2/.rvm/gems/ruby-2.5.5/gems/smartcar-0.1.2/lib/smartcar/vehicle.rb:192:in `start_or_stop_charge!'
        1: from /home/st-2vgpnn2/.rvm/gems/ruby-2.5.5/gems/smartcar-0.1.2/lib/smartcar/base.rb:39:in `block (2 levels) in <class:Base>'
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

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

To contribute, please:

1. Open an issue for the feature (or bug) you would like to resolve.
2. Resolve the issue and add tests in your feature branch.
3. Open a PR from your feature branch into `develop` that tags the issue.

[gem-image]: https://badge.fury.io/rb/smartcar
[gem-url]: https://badge.fury.io/rb/smartcar.svg
