# mruby-require

[![Build Status](https://travis-ci.org/mattn/mruby-require.svg)](https://travis-ci.org/mattn/mruby-require)

mruby-require adds require support to mruby.
This is based on iij's fork of mruby: https://github.com/iij/mruby

## install by mrbgems
```ruby
MRuby::Build.new do |conf|
  if ENV['OS'] != 'Windows_NT' then
    conf.cc.flags << %w|-fPIC| # needed for using bundled gems
  end
    # ... (snip) ...
  conf.gem :github => 'mattn/mruby-require'
end
```

To work properly, mruby-require must be the last mrbgem specified in the build configuration. Any mrbgem specified *after* mruby-require is compiled as a shared object (`.so`) and put in `build/host/lib` (full path available in `$:`). For loading them at runtime, see the next section.

## Requiring additional mrbgems
When mruby-require is being used, additional mrbgems that appear *after* mruby-require in build_config.rb must be required to be used. 

For example, if using mruby-onig-regexp, you should add the following to your code:

````ruby
require 'mruby-onig-regexp'
````

## Requiring mrbgems in defaults
Set MRUBY_REQUIRE environment variable as comma separated values like following

```
MRUBY_REQUIRE=mruby-onig-regexp,mruby-xquote
```

## License

MIT
