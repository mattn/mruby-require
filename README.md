# mruby-require

mruby-require adds require support to mruby

## install by mrbgems
```ruby
MRuby::Build.new do |conf|

    # ... (snip) ...

    conf.gem :github => 'mattn/mruby-require'
end
```

To work properly, mruby-require must be the last mrbgem specified in the build configuration.

## Requiring additional mrbgems
When mruby-require is being used, additional mrbgems must be required to be used. 

For example, if using mruby-onig-regexp, you should add the following to your code:

````ruby
require 'mruby-onig-regexp'
````

