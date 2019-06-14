Gem::Specification.new do |s|
  s.name        = 'coconutrb'
  s.version     = '2.4.0'
  s.summary     = "Client library to transcode videos with coconut.co"
  s.description = "Official client library to transcode videos with coconut cloud service"
  s.authors     = ["Bruno Celeste"]
  s.email       = 'bruno@coconut.co'
  s.files       = ["lib/coconutrb.rb"]
  s.homepage    = 'http://coconut.co'
  s.license     = "MIT"
  s.add_runtime_dependency 'multi_json', '~> 1.0'
end
