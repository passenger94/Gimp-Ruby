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
include RubyFu

module RubyFu
  class Procedure
    attr_reader :type
  end

  def self.test_proc(procname, drawable)
    proc = @@procedures[procname]
    
    params = proc.fullparams
    case proc.type
    when :toolbox
      proc.run(Param.INT32(RUN_INTERACTIVE))
    when :image
      image = Param.IMAGE(PDB.gimp_item_get_image(drawable))
      drawable = Param.DRAWABLE(drawable)
      proc.run(Param.INT32(RUN_INTERACTIVE), image, drawable)
    else
      args = RubyFu.dialog("Testing #{procname}", procname, params)
      proc.run(*args)
    end
  end
end

help_string = _(
  "The procedure argument should be the name of the " +
  "procedure defined in the file you wish to run. " +
  "The drawable argument is only needed if the procedure "+
  "is image based."
)

register(
  :name       => "ruby-fu-run-file",
  :blurb      => "Runs a Ruby-Fu script without requiring you to install it.",
  :help       => help_string,
  :author     => "Scott Lembcke",
  :copyright  => "Scott Lembcke",
  :date       => "2006",
  :menulabel  => "Run File",
  :imagetypes => nil,
  :params     => [
                  ParamDef.FILE("file", "File"),
                  ParamDef.STRING("procedure", "Procedure name\n(only needed if there is \nseveral procedures in the file)", "ruby-fu-"),
                  ParamDef.DRAWABLE("drawable", "Drawable (if needed)"),
                 ],
  :results    => []
  
) do |run_mode, filename, procname, drawable|
    begin
        if procname == "ruby-fu-"
            matches = /name.+(ruby-fu-.*)["'].*/.match(File.read(filename))
            raise "Sorry ...\ndidn't find a ruby-fu function in\n#{filename}\n" if matches.nil?
            procname = matches[1]
        end
        
        Shelf["ruby-fu-last-run-file"] = [filename, procname, drawable]
        
        load(filename)
        RubyFu.test_proc(procname, drawable)
        
    rescue => e
        message "#{e}\n#{e.backtrace.join("\n")}" 
    end
end

menu_register("ruby-fu-run-file", RubyFu::RubyFuToolbox)


register(
  :name       => "ruby-fu-rerun-file",
  :blurb      => _("Reruns the last file ran using Runfile"),
  :help       => nil,
  :author     => "Scott Lembcke",
  :copyright  => "Scott Lembcke",
  :date       => "2006",
  :menulabel  => "Run_again File",
  :imagetypes => nil,
  :params     => [],
  :results    => []
  
) do |run_mode, filename, procname|
  last = Shelf["ruby-fu-last-run-file"]
  
  if last
    load(last.shift)
		RubyFu.test_proc(*last)
  else
    Gimp.message _("No previous file to run")
  end
end

menu_register("ruby-fu-rerun-file", RubyFu::RubyFuToolbox)
