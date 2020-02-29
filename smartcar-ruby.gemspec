lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "smartcar/version"

Gem::Specification.new do |spec|
  spec.name          = "smartcar-ruby"
  spec.version       = Smartcar::VERSION
  spec.authors       = ["Ashwin Subramanian"]
  spec.email         = ["Ashwin.Subramanian@ooma.com"]

  spec.summary       = %q{Ruby Gem to access smartcar APIs (https://smartcar.com/docs/)}
  spec.description   = %q{This is a ruby gem to access the smartcar APIs. It includes the API classes and the OAuth system.}
  spec.license       = "MIT"
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "byebug", "~> 11.0"
  spec.add_dependency "oauth2", "~> 1.4"
end
