module MRuby
  module Gem
    class List
      include Enumerable
      def reject!(&x)
        @ary.reject! &x
      end
      def uniq(&x)
        @ary.uniq &x
      end
    end
  end
  class Build
    unless method_defined?(:old_print_build_summary_for_require)
      alias_method :old_print_build_summary_for_require, :print_build_summary
    end
    def print_build_summary 
      old_print_build_summary_for_require

      Rake::Task.tasks.each do |t|
        if t.name =~ /\.so$/
          t.invoke
        end
      end

      unless @bundled.empty?
        puts "================================================"
          puts "     Bundled Gems:"
          @bundled.map(&:name).each do |name|
          puts "             #{name}"
        end
        puts "================================================"
      end
    end
  end
end

MRuby::Gem::Specification.new('mruby-require') do |spec|
  spec.license = 'MIT'
  spec.authors = 'mattn'
  ENV["MRUBY_REQUIRE"] = ""

  is_vc = ENV['OS'] == 'Windows_NT' && cc.command =~ /^cl(\.exe)?$/
  is_mingw = ENV['OS'] == 'Windows_NT' && cc.command =~ /^gcc(.*\.exe)?$/
  top_build_dir = build_dir
  MRuby.each_target do
    next if @bundled
    @bundled = []
    next unless enable_gems?
    top_build_dir = build_dir
    # Only gems included AFTER the mruby-require gem during compilation are 
    # compiled as separate objects.
    gems_uniq   = gems.uniq {|x| x.name}
    mr_position = gems_uniq.find_index {|g| g.name == "mruby-require"}
    mr_position = -1 if mr_position.nil?
    compiled_in = gems_uniq[0..mr_position].map {|g| g.name}
    @bundled    = gems_uniq.reject {|g| compiled_in.include?(g.name) or g.name == 'mruby-require'}
    gems.reject! {|g| !compiled_in.include?(g.name)}
    libmruby_libs      = MRuby.targets["host"].linker.libraries
    libmruby_lib_paths = MRuby.targets["host"].linker.library_paths
    gems_uniq.each do |g|
      unless g.name == "mruby-require"
        g.setup 
        libmruby_libs      += g.linker.libraries
        libmruby_lib_paths += g.linker.library_paths
      end
    end
    @bundled.each do |g|
      next if g.objs.nil? or g.objs.empty?
      ENV["MRUBY_REQUIRE"] += "#{g.name},"
      sharedlib = "#{top_build_dir}/lib/#{g.name}.so"
      file sharedlib => g.objs do |t|
        if RUBY_PLATFORM.downcase =~ /mswin(?!ce)|mingw|bccwin/
          libmruby_libs += %w(msvcrt kernel32 user32 gdi32 winspool comdlg32)
          name = g.name.gsub(/-/, '_')
          has_rb = !Dir.glob("#{g.dir}/mrblib/*.rb").empty?
          has_c = !Dir.glob(["#{g.dir}/src/*"]).empty?
          deffile = "#{build_dir}/lib/#{g.name}.def"
          open(deffile, 'w') do |f|
            f.puts %Q[EXPORTS]
            f.puts %Q[	gem_mrblib_irep_#{name}] if has_rb
            f.puts %Q[	mrb_#{name}_gem_init] if has_c
            f.puts %Q[	mrb_#{name}_gem_final] if has_c
          end
        else
          deffile = ''
        end
        options = {
            :flags => [
                is_vc ? '/DLL' : is_mingw ? '-shared' : '-shared -fPIC',
                (libmruby_lib_paths + (g.linker ? g.linker.library_paths : [])).flatten.map {|l| is_vc ? "/LIBPATH:#{l}" : "-L#{l}"}].flatten.join(" "),
            :outfile => sharedlib,
            :objs => g.objs.flatten.join(" "),
            :libs => [
                (is_vc ? '/DEF:' : '') + deffile,
                libfile("#{build_dir}/lib/libmruby"),
                libfile("#{build_dir}/lib/libmruby_core"),
                (libmruby_libs + (g.linker ? g.linker.libraries : [])).flatten.uniq.map {|l| is_vc ? "#{l}.lib" : "-l#{l}"}].flatten.join(" "),
            :flags_before_libraries => '',
            :flags_after_libraries => '',
        }

        _pp "LD", sharedlib
        sh linker.command + ' ' + (linker.link_options % options)
      end

      file sharedlib => libfile("#{top_build_dir}/lib/libmruby")
      Rake::Task.tasks << sharedlib
    end
    libmruby.flatten!.reject! do |l|
      @bundled.reject {|g| l.index(g.name) == nil}.size > 0
    end
    cc.include_paths.reject! do |l|
      @bundled.reject {|g| l.index(g.name) == nil}.size > 0
    end
  end

  spec.cc.include_paths << ["#{MRUBY_ROOT}/src"]
  if RUBY_PLATFORM.downcase !~ /mswin(?!ce)|mingw|bccwin/
    spec.linker.libraries << ['dl']
    spec.cc.flags << "-DMRBGEMS_ROOT=\\\"#{File.expand_path top_build_dir}/lib\\\""
  else
    spec.cc.flags << "-DMRBGEMS_ROOT=\"\"\\\"#{File.expand_path top_build_dir}/lib\\\"\"\""
  end
end
