#!/usr/bin/env ruby

# GIMP-Ruby -- Allows GIMP plugins to be written in Ruby.
# Copyright (C) 2006  Scott Lembcke
# 
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor,Boston, MA
# 02110-1301, USA.

require "rubyfu"
require "irb"

module IRB
    class  RGconsoleInputMethod < StdioInputMethod
        def initialize(io)
            super()
            # pfeww ! IRB map @stdin to STDIN by default !
            @stdin = IO.open(io.to_i, :external_encoding => IRB.conf[:LC_MESSAGES].encoding, :internal_encoding => "-")
            #@stdout = IO.open($stdout.to_i, 'w', :external_encoding => IRB.conf[:LC_MESSAGES].encoding, :internal_encoding => "-")
            @stdout = IO.open(STDOUT.to_i, 'w', :external_encoding => IRB.conf[:LC_MESSAGES].encoding, :internal_encoding => "-")
        end
    end
    
    def self.start_session(io = nil)
        puts _("###              Irb on Ruby-#{RUBY_VERSION}")
        $stdout.flush
        
        ARGV.clear
        IRB.setup(nil)
        
        irb = Irb.new(nil, io.nil? ? IRB::StdioInputMethod.new : RGconsoleInputMethod.new(io))
        
        @CONF[:IRB_RC].call(irb.context) if @CONF[:IRB_RC]
        @CONF[:MAIN_CONTEXT] = irb.context
        
        trap("SIGINT") do
            irb.signal_handle
        end
        
        catch(:IRB_EXIT) do
            irb.eval_input
        end
    end
end
    

RubyFu.register(
    :name      => "ruby-fu-console-noimage",
    :blurb     => _("No image, Starts an irb session in a console."),
    :help      => _("No image, Starts an irb session in a console."),
    :author    => "Scott Lembcke/xy",
    :copyright => "Scott Lembcke/xy",
    :date      => "2015",
    :menulabel => _("Ruby Console")
) do |run_mode|
    
    include Gimp
    include PDB::Access
    
###  GTK+ console    
#    console = File.join(GIMP_DIRECTORY, "ruby", "ruby-fu-console")
#    $stdout = io = IO.popen(["#{console}", :err=>:out], "w+") 
    
###  Shoes console    
    require File.expand_path("shoesfu.rb", File.dirname(__FILE__))
    console = File.join(GIMP_DIRECTORY, "plug-ins/shoes_console.rb")
    $stdout = io = IO.popen([ShoesFu::SHOES, console, :err=>:out], "w+")
    
    
    IRB.start_session(io)
    
end

RubyFu.menu_register("ruby-fu-console-noimage", RubyFu::RubyFuToolbox)
