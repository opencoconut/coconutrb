$LOAD_PATH.unshift(::File.join(::File.dirname(__FILE__), "lib"))

require "coconut/version"

Gem::Specification.new do |gem|
  gem.name        = "coconutrb"
  gem.version     = Coconut::VERSION
  gem.summary     = "Client library to transcode videos with coconut.co"
  gem.description = "Official client library to transcode videos with Coconut Cloud Service"
  gem.author      = "Coconut"
  gem.email       = "support@coconut.co"
  gem.homepage    = "https://coconut.co"
  gem.license     = "MIT"
  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- test/*`.split("\n")
  gem.require_paths = ["lib"]
  gem.add_runtime_dependency "http"
end
