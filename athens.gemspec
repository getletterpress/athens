
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "athens/version"

Gem::Specification.new do |spec|
  spec.name          = "athens"
  spec.version       = Athens::VERSION
  spec.authors       = ["Chris Schulte"]
  spec.email         = ["chris@oceanbreezesoftware.com"]

  spec.summary       = %q{Run simple SQL queries in AWS Athena}
  spec.description   = %q{Allows you to easily access AWS Athena databases and run queries}
  spec.homepage      = "https://github.com/getletterpress/athens"
  spec.license       = "WTFPL"

  if spec.respond_to?(:metadata)
    spec.metadata["homepage_uri"] = spec.homepage
    spec.metadata["source_code_uri"] = "https://github.com/getletterpress/athens"
    spec.metadata["changelog_uri"] = "https://github.com/getletterpress/athens/CHANGELOG.md"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "aws-sdk-athena", "~> 1"

  spec.add_development_dependency "bundler", "~> 1.17"
  spec.add_development_dependency "rake", "~> 10.0"
end
