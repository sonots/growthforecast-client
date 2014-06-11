#! /usr/bin/env gem build
# encoding: utf-8

Gem::Specification.new do |gem|
  gem.name          = 'growthforecast-client'
  gem.version       = '0.82.5'
  gem.authors       = ["Naotoshi Seo"]
  gem.email         = ["sonots@gmail.com"]
  gem.homepage      = "https://github.com/sonots/growthforecast-client"
  gem.summary       = "A Ruby Client Library for GrowthForecast API"
  gem.description   = gem.summary
  gem.licenses      = ["MIT"]

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_runtime_dependency "thor"
  gem.add_runtime_dependency "parallel"

  # for testing
  gem.add_development_dependency "rake"
  gem.add_development_dependency "rspec", "~> 2.11"
  gem.add_development_dependency "webmock"

  # for debug
  gem.add_development_dependency "pry"
  gem.add_development_dependency "pry-nav"
end
