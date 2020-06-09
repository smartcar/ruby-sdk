require_relative "../../../lib/smartcar.rb"
require "selenium-webdriver"
require "securerandom"
require "cgi"

class AuthHelper
  class << self
    def get_code(uri)
      code_hash = CGI.parse(URI.parse(uri).query)
      code_hash["code"].first
    end

    def auth_client_params
      {
        redirect_uri: "https://example.com/auth",
        scope: [
          "required:read_vehicle_info",
          "required:read_location",
          "required:read_odometer",
          "required:control_security",
          "required:read_vin",
          "required:read_fuel",
          "required:read_battery",
          "required:read_charge",
          "required:read_engine_oil",
          "required:read_tires",
          "required:control_charge",
        ],
        test_mode: true,
      }
    end

    def run_auth_flow(authorization_url)
      options = Selenium::WebDriver::Firefox::Options.new(args: ['-headless'])
      email = "#{SecureRandom.uuid}@email.com";
      driver = Selenium::WebDriver.for :firefox, options: options
      driver.navigate.to authorization_url
      driver.find_element(css: "button#continue-button").click
      driver.find_element(css: "button.brand-selector-button[data-make=\"CHEVROLET\"]").click
      driver.find_element(css: "input[id=username]").send_keys(email)
      driver.find_element(css: "input[id=password").send_keys('password')
      driver.find_element(css: "button[id=sign-in-button]").click

      wait = Selenium::WebDriver::Wait.new(:timeout => 10)

      wait.until {
          element = driver.find_element(:css, "button[id=approval-button]")
          element if element.displayed?
      }.click
      uri = wait.until{
        driver.current_url if driver.current_url.match('example.com')
      }
      driver.quit
      get_code(uri)
    end
  end
end
