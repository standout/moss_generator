# frozen_string_literal: true

require_relative 'lib/moss_generator/version'

Gem::Specification.new do |spec|
  spec.name          = 'moss_generator'
  spec.version       = MossGenerator::VERSION
  spec.authors       = ['frdrkolsson']
  spec.email         = ['fredrik.olsson@standout.se']

  spec.summary       = 'Skatteverket One Stop Shop (OSS) generator.'
  spec.description   = spec.summary
  spec.homepage      = 'https://github.com/standout/moss_generator'
  spec.license       = 'MIT'
  spec.required_ruby_version = Gem::Requirement.new('>= 2.5.0')

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = spec.homepage

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added
  # into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject do |f|
      f.match(%r{\A(?:test|spec|features)/})
    end
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  # spec.add_dependency to register a new dependency of your gem
  spec.add_dependency 'countries', '~> 4.0'
  spec.add_dependency 'money', '~> 6.14'
  spec.add_dependency 'rexml', '~> 3.2'
  spec.add_dependency 'valvat', '~> 1.1'

  # For more information and examples about making a new gem, checkout our
  # guide at: https://bundler.io/guides/creating_gem.html
end
