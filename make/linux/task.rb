
class MakeLinux
    include FileUtils

    class << self
        def make_app(name)
          puts "building ruby-fu-console"
          target = "#{TGT_DIR}/#{name}"
          #rm_f Dir.glob("#{target}*")
          sh "#{CC} -I. -c -o #{target}.o #{LINUX_CFLAGS} #{SRC_DIR}/#{name}.c"
          sh "#{CC} -o #{target} #{target}.o #{LINUX_LIBS}"  # 
        end

        # dynamic library with libtool
        def make_so(name)
          puts "creating library : #{name}"
          #sh "libtool --mode=link gcc -g -O -o dist/libgimpext.la #{(OBJ).join(' ')} -rpath #{File.expand_path(TGT_DIR)}"
          sh "libtool --tag=CC --mode=link gcc -module -avoid-version -shrext .so"+
              " -g -O2 -Wall -fPIC -fn -fast-math -ggdb3 -Wall -o dist/gimpext.la #{(OBJ).join(' ')}"+
              " #{LINUX_CFLAGS} -DLOCALEDIR='/home/xy/gimp29/share/locale'"+
              " -rpath /home/xy/gimp29/lib/gimp/2.0/ruby -Wl,--export-dynamic -pthread"+
              " #{GIMP_LIBDIR} #{LINUX_LDFLAGS} #{LINUX_LIBS} -fstack-protector"
        end
        
        def copy_files_to_gimpuser
            puts "Installing gimp-ruby in #{USERDIR}"
            ["#{USERDIR}/ruby", "#{USERDIR}/plug-ins"].each {|d| mkdir d unless Dir.exist?(d)}
            copy_ext
            copy_ruby_lib
            copy_plugins
            copy_statics
        end
        
        def copy_ext
            cp ["#{TGT_DIR}/.libs/gimpext.so", "#{TGT_DIR}/gimpext.la", "#{TGT_DIR}/ruby-fu-console"], 
                "#{USERDIR}/ruby"
        end
        
        def copy_ruby_lib
            cp Dir.glob("lib/ruby/*.rb"), "#{USERDIR}/ruby"
        end
        
        def copy_plugins
            copy_shoes_plugins if SHOES
            cp_r Dir.glob("lib/plug-ins/*") - Dir.glob("lib/plug-ins/*shoes*"), "#{USERDIR}/plug-ins"
        end
        
        def copy_shoes_plugins
            open("lib/plug-ins/shoesfu.rb", 'r') do |f|
                open("lib/plug-ins/shoesfu.tmp.rb", 'w') do |f2|
                    f.each_line do |line|
                        line = "SHOES = '#{SHOES}'\n" if line=~ /SHOES\s?=\s?/
                        f2.write line
                    end
                end
            end
            mv "lib/plug-ins/shoesfu.tmp.rb", "lib/plug-ins/shoesfu.rb"
            
            cp_r Dir.glob("lib/plug-ins/*shoes*"), "#{USERDIR}/plug-ins"
        end
        
        def copy_statics
            # at the moment only needed for shoes plugins
            # left outside of :copy_shoes_plugins method, in case needed by regular ruby plugins
            cp_r("ruby_static", "#{USERDIR}") if SHOES
        end
        
    end
end

