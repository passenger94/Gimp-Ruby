#
#   Links against system (or rvm) ruby, and libraries.
require 'rbconfig'

# manually set below to what you want to build with/for
#ENV['DEBUG'] = "true"
APP['GTK'] = "gtk+-2.0"
# APP['GTK'] = "gtk+-3.0" # gimp not gtk3 ready yet !!
# ENV['GDB'] = "true" # compile -g,  don't strip symbols
# Pick your optimatization and debugging options
if ENV['DEBUG'] || ENV['GDB']
  LINUX_CFLAGS = "-g -O2 -Wall" #-g -O0"
else
  LINUX_CFLAGS = "-O -Wall"
end
# figure out which ruby we need.
rv =  RUBY_VERSION[/\d.\d/]


LINUX_CFLAGS << " -DGTK3" unless APP['GTK'] == 'gtk+-2.0'
# Following line may need handcrafting 
LINUX_CFLAGS << " -I/usr/include/"
LINUX_CFLAGS << " #{`pkg-config --cflags #{APP['GTK']}`.strip}"


CC = "gcc"

pckgs = ['gimp-2.0', 'gimpui-2.0', 'gimpthumb-2.0']
GIMP_LIBS, GIMP_LIBDIR  = "", ""
if PREFIX
    # gimp on specific path
    puts "compiling #{APP['name']}-#{APP['VERSION']} for #{PREFIX} on Ruby-#{RUBY_VERSION}"
    #GIMP_BIN = "#{PREFIX}/bin"
    GIMP_PKG = "#{PREFIX}/lib/pkgconfig"
    
    ENV['LD_LIBRARY_PATH'] = "#{PREFIX}/lib:#{ENV['LD_LIBRARY_PATH']}" 
    ENV['PKG_CONFIG_PATH'] = "#{GIMP_PKG}:#{ENV['PKG_CONFIG_PATH']}"
    ENV['ACLOCAL_FLAGS'] = "-I #{PREFIX}"
    
    GIMP_LIBDIR << "#{PREFIX}/lib"
    GIMP_CFLAGS = " #{`pkg-config --cflags #{GIMP_PKG}/#{pckgs[0]}.pc`.strip}"
    pckgs.each {|p| GIMP_LIBS << " #{`pkg-config --libs #{GIMP_PKG}/#{p}.pc`.strip}"}
    
    # TODO
    # assuming for now we use gimp-2.9 and user files are in /home/user/.config/GIMP/2.9
    USERDIR = "#{ENV['HOME']}/.config/GIMP/2.9"
else
    # gimp on system path
    v = `gimp -v`.match(/(GIMP version .+)/)[1]
    puts "compiling #{APP['name']}-#{APP['VERSION']} for #{v} on Ruby-#{RUBY_VERSION}"
    
    GIMP_CFLAGS = " #{`pkg-config --cflags #{pckgs[0]}`.strip}"
    pckgs.each {|p| GIMP_LIBS << " #{`pkg-config --libs #{p}`.strip}"}
    
    #TODO
    # assuming gimp-2.8 (change for whatever version is installed) [but before 2.9] 
    USERDIR = "#{ENV['HOME']}/.gimp-2.8"
end

GTK_FLAGS = "#{`pkg-config --cflags #{APP['GTK']}`.strip}"
GTK_LIB = "#{`pkg-config --libs #{APP['GTK']}`.strip}"

EXT_RUBY = RbConfig::CONFIG['prefix']
RUBY_CFLAGS = " #{`pkg-config --cflags #{EXT_RUBY}/lib/pkgconfig/ruby-#{rv}.pc`.strip}"


LINUX_CFLAGS << " #{RUBY_CFLAGS} #{GTK_FLAGS} #{GIMP_CFLAGS}"

LINUX_LIBS = "#{GTK_LIB} #{GIMP_LIBS}"
LINUX_LIBS << " -lfontconfig" if APP['GTK'] == "gtk+-3.0"

LINUX_LDFLAGS = "-L. -rdynamic -Wl,-export-dynamic"

DLEXT = "so"

# do we want shoes support
SHOES = APP['shoes']



