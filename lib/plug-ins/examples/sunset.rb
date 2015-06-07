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

include Gimp
include RubyFu

register(
  :name       => "ruby-fu-sunset",
  :blurb      => "Creates a nice sunset over water",
  :help       => "Creates a new image of the given size of a sunset.",
  :author     => "Scott Lembcke",
  :copyright  => "Scott Lembcke",
  :date       => "2006",
  :menulabel   => "Sunset",
  :imagetypes => nil,
  :params     => [
            ParamDef.INT32("width", "Width", 640),
            ParamDef.INT32("height", "Height", 480)
  ],
  :results => [ParamDef.IMAGE("image", "Image")]

) do|run_mode, w, h|
	include PDB::Access

	image = Image.new(w, h, RGB)
	sunset = image.addLayer(w, h, RGB_IMAGE, "sunset", 100, NORMAL_MODE)
	
	Context.push do
	    image.undo_disable do
            Context.set_foreground(Color(0.025, 0.000, 0.219))
            Context.set_background(Color(1.000, 0.870, 0.000))
            Context.set_gradient("FG to BG (HSV anti-clockwise)")
    
            image.select_rectangle(CHANNEL_OP_REPLACE, 0, 0, w, h/3)
            Edit.blend(sunset, BLEND_CUSTOM, NORMAL_MODE, GRADIENT_LINEAR, 100, 0, REPEAT_NONE, FALSE, FALSE, 1, 0, TRUE, 0, 0, 0, h/3)
            image.select_rectangle(CHANNEL_OP_REPLACE, 0, h/3, w, h)
            Edit.blend(sunset, BLEND_CUSTOM, NORMAL_MODE, GRADIENT_LINEAR, 100, 0, REPEAT_NONE, FALSE, FALSE, 1, 0, TRUE, 0, h, 0, h/3)
            Selection.none(image)
    
            waves = image.addLayer(w, h, RGB_IMAGE, "waves", 100, NORMAL_MODE)
            plug_in_solid_noise(image, waves, false, false, rand(10_000), 15, 1.5, 16)    
    
            Context.set_foreground(Color(0.5, 0.5, 0.5))
            Edit.blend(waves, BLEND_FG_TRANSPARENT, NORMAL_MODE, GRADIENT_LINEAR, 100, 0, REPEAT_NONE, FALSE, FALSE, 1, 0, TRUE, 0, h/3, 0, h)
            plug_in_displace(image, sunset, 0, h/4, false, true, nil, waves, 1)
    
            plug_in_bump_map(image, sunset, waves, 270, 50, 6, 0, 0, 0, 111, true, false, 0)
            image.remove_layer(waves)
    
            image.select_rectangle(CHANNEL_OP_REPLACE, 0, h/3, w, h)
            sunset.levels(HISTOGRAM_VALUE, 0, 1.0, 0.65, 0, 1.0)
            Selection.none(image)
            
            gimp_progress_end # getting rid of annoying dialog warning 
            Display.new(image)
        end
	end
	
	image
end

menu_register("ruby-fu-sunset", "<Image>/File/Create/RubyFu")

