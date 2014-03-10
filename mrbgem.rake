MRuby::Gem::Specification.new('mruby-require') do |spec|
  spec.license = 'MIT'
  spec.authors = 'mattn'
  ENV["MRUBY_REQUIRE"] = ""

  spec.cc.include_paths << "#{MRUBY_ROOT}/src"
  
  case RUBY_PLATFORM
  when /linux/
    spec.linker.libraries += ['dl']
  end
  
end
