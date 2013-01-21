MRuby::Gem::Specification.new('mruby-require') do |spec|
  spec.license = 'MIT'
  spec.authors = 'mattn'

  if ENV['OS'] != 'Windows_NT'
    spec.linker.libraries = 'dl'
  end
end
