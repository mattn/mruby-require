loading_path = []
runner = ->(lib, path) do
  unless path
    instance_eval(&lib)
    true
  else
    return false if loading_path.include?(path)
    loading_path << path

    begin
      instance_eval(&lib)
      $" << path
      true
    ensure
      loading_path.pop rescue nil
    end
  end
end

Kernel.define_method(:require, &->(path) {
  lib, path = Kernel.__require_load_library(path, true, nil)
  if path
    runner.call(lib, path)
  else
    lib # true or false
  end
})

Kernel.define_method(:load, &->(path, wrap = false) {
  case
  when !wrap
    wrap = nil
  when wrap.kind_of?(Module) && !wrap.kind_of?(Class)
    # use module as is
  else
    wrap = Module.new
  end

  lib, path = Kernel.__require_load_library(path, false, wrap)
  runner.call(lib, nil)
})
