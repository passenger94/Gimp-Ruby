
require 'rake'
require 'rake/clean'
require 'fileutils'
require 'yaml'
require 'rbconfig'

include FileUtils

APP = YAML.load_file(File.join(".", "app.yaml"))

APP['VERSION'] = "#{APP['major']}.#{APP['minor']}.#{APP['tiny']}"
APP['MAJOR'] = APP['major'].to_s
APP['MINOR'] = APP['minor'].to_s
APP['TINY'] = APP['tiny'].to_s
APP['DATE'] = Time.now.to_s
APP['PLATFORM'] = RbConfig::CONFIG['arch']

SONAME = 'gimpext'
RF_CONSOLE = "ruby-fu-console"
PREFIX = APP['gimp_prefix']

RUBY_SO = RbConfig::CONFIG['RUBY_SO_NAME']  
RUBY_V = RbConfig::CONFIG['ruby_version']   
RUBY_ARCH = APP['PLATFORM']                 


if File.exists? "crosscompile"
    CROSS = true
    File.open('crosscompile','r') do |f|
        str = f.readline
        TGT_DIR = str.split('=')[1].strip
    end
else
    CROSS = false
    TGT_DIR = 'dist'
end



ROOT = File.expand_path('.')
SRC_DIR = "#{ROOT}/c_sources"

SRC = FileList["#{SRC_DIR}/*.c"] - ["#{SRC_DIR}/ruby-fu-console.c",  # not in linked lib
                                    "#{SRC_DIR}/rbgimpcolorspace.c"] # not ready ? TODO
#OBJ = SRC.map { |x| "#{TGT_DIR}/#{x.pathmap("%n").ext'.o'}" }
OBJ = SRC.map { |x| "#{TGT_DIR}/#{x.pathmap("%n").ext'.lo'}" } # libtool

CLEAN.include ["#{TGT_DIR}"] #TODO


# TODO
case RUBY_PLATFORM
when /mingw/
    Builder = MakeMinGW
    NAMESPACE = :win32
when /darwin/
    Builder = MakeDarwin
    NAMESPACE = :osx   
when /linux/
    require File.expand_path('make/linux/env')
    require File.expand_path('make/linux/task')
    Builder = MakeLinux
    NAMESPACE = :linux
else
    puts "Sorry, your platform [#{RUBY_PLATFORM}] is not supported..."
end
    

desc "Same as `rake build'"
task :default => [:build]

desc "Does a full compile, for the OS you're running on"
task :build => ["#{NAMESPACE}:build"]

desc "Install gimp-ruby in #{USERDIR}"
task  :install do
  if CROSS 
     puts "Sorry. Not yet implemented "
  else
    #create_version_file 'VERSION.txt'
    Builder.copy_files_to_gimpuser
  end
end

desc "copy library and console to gimp user directory"
task :copy_gimp_lib do
    Builder.copy_ext
end

desc "copy ruby lib to gimp user directory"
task :copy_ruby_lib do
    Builder.copy_ruby_lib
end

desc "copy ruby plug-ins to gimp user directory"
task :copy_plugins do
    Builder.copy_plugins
end

desc "copy shoes plug-ins to gimp user directory"
task :copy_shoes_plugins do
    Builder.copy_shoes_plugins
end

desc "copy static files to gimp user directory"
task :copy_static do
    Builder.copy_statics
end


directory "#{TGT_DIR}"

namespace :linux do
  
  task :build => [:make_app]
  
  desc "compile c files"
  task :build_obj => OBJ
  
  Localedir = (PREFIX ? "#{PREFIX}" : "/usr") + "/share/locale"
  SRC.each do |cfile|
    ofile = "#{TGT_DIR}/#{cfile.pathmap("%n").ext'.lo'}"
    pofile = "#{TGT_DIR}/.deps/#{cfile.pathmap("%f%n").ext('.Tpo')}"
    mkdir_p "#{TGT_DIR}"
    mkdir_p "#{TGT_DIR}/.deps" # .libs is done automatically by libtool
    
    file(ofile => cfile) do
        sh "libtool --tag=CC --mode=compile gcc -DHAVE_CONFIG_H -I. -I.. -fPIC "+
            "-fno-fast-math -ggdb3 -Wall -fPIC #{LINUX_CFLAGS} -DLOCALEDIR='#{Localedir}' "+
            "-g -O2 -Wall -MT #{ofile} -MD -MP -MF #{pofile} -c -o #{ofile} #{cfile}"
    end
  end
      
  desc "build ruby-fu-console"
  task :make_app => [:make_so] do
    Builder.make_app "ruby-fu-console"
  end
  
  desc "build gimp-ruby library"
  task :make_so => [:build_obj] do
    Builder.make_so "#{TGT_DIR}/#{SONAME}.#{DLEXT}"
  end
end


def copy_files glob, dir
  FileList[glob].each { |f| cp_r f, dir }
end


require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new do |task|
    task.rspec_opts = ['--color', '--format', 'doc']
end

