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

RubyFu.register(
  :name      => "ruby-fu-console-xy",
  :blurb     => _("No image, Starts an irb session in a console."),
  :help      => _("No image, Starts an irb session in a console."),
  :author    => "Scott Lembcke/xy",
  :copyright => "Scott Lembcke/xy",
  :date      => "2015",
  :menulabel  => _("Ruby Console")
) do |run_mode|


    require "irb"
     
    module IRB
        def self.start_session
            puts _("***     Irb on Ruby #{RUBY_VERSION}")
            
            ARGV.clear
            IRB.setup(nil)

            irb = Irb.new(nil, IRB::StdioInputMethod.new)

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

    include Gimp
    include PDB::Access

    console = File.join(GIMP_DIRECTORY, "ruby", "ruby-fu-console")
    # !!? why STDIN ??
    $stdout = STDIN = IO.popen(["#{console}", :err=>:out], "w+") 

    IRB.start_session
end

RubyFu.menu_register("ruby-fu-console-xy", RubyFu::RubyFuToolbox)
