MRuby::Gem::Specification.new('mruby-require') do |spec|
  spec.license = 'MIT'
  spec.authors = 'mattn'
  ENV["MRUBY_REQUIRE"] = ""
  @bundled = []

  is_vc = ENV['OS'] == 'Windows_NT' && cc.command =~ /^cl(\.exe)?$/
  #cc.defines << "/LD" if is_vc
  top_build_dir = build_dir
  MRuby.each_target do
    if enable_gems?
      top_build_dir = build_dir
      @bundled = gems.clone.reject {|g| g.name == 'mruby-require'}
      sharedlibs = []
      gems.reject! {|g| g.name != 'mruby-require' }
      @bundled.each do |g|
        sharedlib = "#{top_build_dir}/lib/#{g.name}.so"
        file sharedlib => g.objs do |t|
          if ENV['OS'] == 'Windows_NT'
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
              :flags => [
                  is_vc ? '/DLL' : '-shared',
                  g.linker.library_paths.flatten.map {|l| is_vc ? "/LIBPATH:#{l}" : "-L#{l}"}].flatten.join(" "),
              :outfile => sharedlib,
              :objs => g.objs ? g.objs.join(" ") : "",
              :libs => [
                  (is_vc ? '/DEF:' : '') + deffile,
                  libfile("#{build_dir}/lib/libmruby"),
                  libfile("#{build_dir}/lib/libmruby_core"),
                  g.linker.libraries.flatten.uniq.map {|l| is_vc ? "#{l}.lib" : "-l#{l}"}].flatten.join(" "),
              :flags_before_libraries => '',
              :flags_after_libraries => '',
          }

          _pp "LD", sharedlib
          sh linker.command + ' ' + (linker.link_options % options)
        end

        sharedlibs << sharedlib
        file sharedlib => libfile("#{top_build_dir}/lib/libmruby")

        Rake::Task.tasks << sharedlib
      end
      libmruby.flatten!.reject! {|l| l =~ /\/mrbgems\//}
      cc.include_paths.reject! {|l| l =~ /\/mrbgems\// && l !~ /\/mruby-require/}
    end
  end
  module MRuby
    class Build
      alias_method :old_print_build_summary, :print_build_summary
      def print_build_summary 
        Rake::Task.tasks.each do |t|
          if t.name =~ /\.so$/
            t.invoke
          end
        end

        puts "================================================"
        puts "      Config Name: #{@name}"
        puts " Output Directory: #{self.build_dir}"
        puts "         Binaries: #{@bins.join(', ')}" unless @bins.empty?
        unless @gems.empty?
          puts "    Included Gems:"
          @gems.map(&:name).each do |name|
            puts "             #{name}"
          end
          puts "     Bundled Gems:"
          @bundled.map(&:name).each do |name|
            puts "             #{name}"
          end
        end
        puts "================================================"
        puts
      end
    end
  end

  spec.cc.include_paths << ["#{build.root}/src"]
  if ENV['OS'] != 'Windows_NT'
    spec.linker.libraries << ['dl']
    spec.cc.flags << "-DMRBGEMS_ROOT=\\\"#{File.expand_path top_build_dir}/lib\\\""
  else
    spec.cc.flags << "-DMRBGEMS_ROOT=\"\"\"#{File.expand_path top_build_dir}/lib\"\"\""
  end
end
