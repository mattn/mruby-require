MRuby::Gem::Specification.new('mruby-require') do |spec|
  spec.license = 'MIT'
  spec.authors = 'mattn'

  spec.cc.include_paths << ["#{build.root}/src"]
  if ENV['OS'] != 'Windows_NT'
    spec.linker.libraries = 'dl'
  end
end
