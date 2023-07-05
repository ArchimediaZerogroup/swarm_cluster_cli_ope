require_relative 'lib/swarm_cluster_cli_ope/version'

Gem::Specification.new do |spec|
  spec.name = "swarm_cluster_cli_ope"
  spec.version = SwarmClusterCliOpe::VERSION
  spec.authors = ["Marino Bonetti"]
  spec.email = ["marinobonetti@gmail.com"]

  spec.summary = "WIP Gemma per la gestione del cluster swarm"
  spec.description = "Gestione di varie operazioni come sincronia con le cartelle bindate dei container (rsync) up o
                        down e possibilità di scaricare/caricare i file direttamente all'interno del cluster, in
                        modo facilitato"
  spec.homepage = "https://github.com/ArchimediaZerogroup/swarm_cluster_cli_ope"
  spec.license = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.3.0")

  spec.metadata["allowed_push_host"] = 'https://rubygems.org/'

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/ArchimediaZerogroup/swarm_cluster_cli_ope"
  spec.metadata["changelog_uri"] = "https://github.com/ArchimediaZerogroup/swarm_cluster_cli_ope/blob/master/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features|test_folder|Dockerfile)/}) }
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "thor", '~>1.0'
  spec.add_dependency "zeitwerk", '~>2.3'
  spec.add_dependency "open4"
  spec.add_dependency "activesupport", '<7'
end
