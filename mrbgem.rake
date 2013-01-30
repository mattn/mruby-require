MRuby::Gem::Specification.new('mruby-require') do |spec|
  spec.license = 'MIT'
  spec.authors = 'mattn'

  top_build_dir = build_dir
  MRuby.each_target do
    if enable_gems?
      sharedlibs = []
      gems.each do |g|
        libs = gems.map {|g| g.linker.libraries }.flatten.map {|l| "-l#{l}"}
        sharedlibs << "#{g.build_dir}/#{g.name}.so"

        if ENV['OS'] != 'Windows_NT'
          deffile = "#{build_dir}/lib/#{g.name}.def"
          open(deffile, 'w') do |f|
            f.puts [
              "EXPORTS",
              "\tmrb_#{g.name.gsub(/-/, '_')}_gem_init",
              "\tmrb_#{g.name.gsub(/-/, '_')}_gem_final",
            ].join("\n")
          end
        else
          deffile = ''
        end
        options = {
            :flags => '-shared',
            :outfile => "#{build_dir}/lib/#{g.name}.so",
            :objs => g.objs.join(" ") + " " + deffile,
            :libs => "#{build_dir}/lib/libmruby.a #{build_dir}/lib/libmruby_core.a" + " " + libs.join(" "),
            :flags_before_libraries => '',
            :flags_after_libraries => '',
        }
        sh linker.command + ' ' + (linker.link_options % options)
      end
      libmruby.flatten!.reject! {|l| l =~ /\/mrbgems\//}
      gems.reject! {|g| g.name != 'mruby-require' }

      file "#{build_dir}/mrbgems/gem_init.c" => sharedlibs.reject{|l| l =~ /\/mruby-require\//}
      top_build_dir = build_dir
    end
  end

  spec.cc.include_paths << ["#{build.root}/src"]
  if ENV['OS'] != 'Windows_NT'
    spec.linker.libraries = 'dl'
    spec.cc.flags << "-DMRBGEMS_ROOT=\"#{top_build_dir}/lib\""
  else
    spec.cc.flags << "-DMRBGEMS_ROOT=\"\"\"#{top_build_dir}/lib\"\"\""
  end
end
