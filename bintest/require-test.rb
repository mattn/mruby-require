def assert_mruby_require(expect, code)
  env = { "MRBLIB" => File.dirname(__dir__) }
  cmd = [cmd("mruby"), "-e", code]
  result = IO.popen(env, cmd, "r", err: [:child, :out]) { |pipe| pipe.read }
  diff = "    Expected #{result.inspect} to be match to #{expect.inspect}."
  cond = expect === result
  assert_true cond, nil, diff
end

assert "require" do
  assert_mruby_require <<~'RESULT', %(invisible = 0; 3.times { p require "testfiles/minimal" })
    {:self=>main}
    {:instance_variables=>[]}
    {:module=>A}
    true
    false
    false
  RESULT

  assert_mruby_require /\(LoadError\)$/, %(require "testfiles/notexist")
end

assert "load" do
  assert_mruby_require <<~'RESULT', %(invisible = 0; 3.times { p load "testfiles/minimal.rb" })
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
