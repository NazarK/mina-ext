lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "mina/ext/version"

Gem::Specification.new do |spec|
  spec.name          = "mina-ext"
  spec.version       = Mina::Ext::VERSION
  spec.authors       = ["Nazar Kuliyev"]
  spec.email         = ["nazar.kuliev@gmail.com"]

  spec.summary       = "additional commands for mina gem"
  spec.description   = "adds mina tasks: db:pull, files:pull, shell, backup and other."
  spec.homepage      = "https://github.com/NazarK/mina-ext"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_dependency 'mina'
  spec.add_dependency "erb"

  spec.add_development_dependency "bundler", "~> 1.16"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "yaml"
end
