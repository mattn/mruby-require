def assert_mruby_require(expect, code)
  env = { "MRBLIB" => File.dirname(__dir__) }
  cmd = [cmd("mruby"), "-e", code]
  result = IO.popen(env, cmd, "r", err: [:child, :out]) { |pipe| pipe.read }
  diff = "    Expected #{result.inspect} to be match to #{expect.inspect}."
  cond = expect === result
  assert_true cond, nil, diff
end

unused = 1 # variables to check for invisibility in `require/load`

assert "require" do
  assert_mruby_require <<~'RESULT', %(3.times { p require "testfiles/minimal" })
    {:self=>main}
    {:instance_variables=>[]}
    {:module=>A}
    true
    false
    false
  RESULT

  assert_mruby_require /\(LoadError\)$/, %(require "testfiles/notexist")
end

assert "require with fiber" do
  assert_mruby_require /\[0, 3, 6\]\n.* \(FiberError\)$/m, %(require "testfiles/fiber")
end

assert "load" do
  assert_mruby_require <<~'RESULT', %(3.times { p load "testfiles/minimal.rb" })
    {:self=>main}
    {:instance_variables=>[]}
    {:module=>A}
    true
    {:self=>main}
    {:instance_variables=>[]}
    {:module=>A}
    true
    {:self=>main}
    {:instance_variables=>[]}
    {:module=>A}
    true
  RESULT

  assert_mruby_require /\(LoadError\)$/, %(load "testfiles/minimal") # because it does not complement the extensions
  assert_mruby_require /\(LoadError\)$/, %(load "testfiles/notexist.rb")
end

assert "load with wrapper" do
  assert_mruby_require /\{:self=>main\}\n\{:instance_variables=>\[\]\}\n\{:module=>A\}\n/, %(load "testfiles/minimal.rb", nil)
  assert_mruby_require /\{:self=>main\}\n\{:instance_variables=>\[\]\}\n\{:module=>A\}\n/, %(load "testfiles/minimal.rb", false)
  assert_mruby_require /\{:self=>main\}\n\{:instance_variables=>\[\]\}\n\{:module=>#<Module:0x\w+>::A\}\n/, %(load "testfiles/minimal.rb", true)
  assert_mruby_require /\{:self=>main\}\n\{:instance_variables=>\[\]\}\n\{:module=>#<Module:0x\w+>::A\}\n/, %(load "testfiles/minimal.rb", Object)
  assert_mruby_require /\{:self=>main\}\n\{:instance_variables=>\[\]\}\n\{:module=>Kernel::A\}\n/, %(load "testfiles/minimal.rb", Kernel)
end
