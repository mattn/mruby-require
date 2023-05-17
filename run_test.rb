#!/usr/bin/env ruby

if __FILE__ == $PROGRAM_NAME
  require 'fileutils'
  FileUtils.mkdir_p 'tmp'
  unless File.exist?('tmp/mruby')
    system 'git clone https://github.com/mruby/mruby.git tmp/mruby'
  end
  exit system(%Q[cd tmp/mruby; MRUBY_CONFIG=#{File.expand_path __FILE__} ./minirake #{ARGV.join(' ')}])
end

MRuby::Lockfile.disable rescue nil # for development

MRuby::Build.new do |conf|
  toolchain :clang
  conf.enable_debug
  conf.enable_test
  conf.enable_bintest
  conf.cc.flags << ["-fPIC"]
  conf.gembox 'default'
  conf.gem File.dirname(File.expand_path(__FILE__))
end
