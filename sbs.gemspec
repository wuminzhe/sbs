lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "sbs/version"

Gem::Specification.new do |spec|
  spec.name          = "sbs"
  spec.version       = Sbs::VERSION
  spec.authors       = ["wuminzhe"]
  spec.email         = ["wuminzhe@gmail.com"]

  spec.summary       = %q{A better cli tool for substrate development}
  spec.description   = %q{A better cli tool for substrate development}
  spec.homepage      = "https://github.com/wuminzhe/sbs"
  spec.license       = "MIT"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/wuminzhe/sbs"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "rake", "~> 13.0"

  spec.add_dependency "thor", "~> 0.20.3"
  spec.add_dependency "activesupport", ">= 5.2.3", "< 7.1.0"
  spec.add_dependency "colorize", "~> 0.8.1"
end
