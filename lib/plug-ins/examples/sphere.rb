#!ruby
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



# converted from sphere.scm
# Everyone else on the block had a sphere generator.
# I didn't want Gimp-Ruby to feel left out.

rfsphere = {
  :name       => "ruby-fu-sphere",
  :blurb      => _("Simple sphere with a drop shadow"),
  :help       => _("Simple sphere with a drop shadow"),
  :author     => "Spencer Kimball and Scott Lembcke",
  :copyright  => "Spencer Kimball",
  :date       => "1996",
  :menulabel   => _("Sphere"),
  :imagetypes => "",
  :params     => [
    ParamDef.SPINNER("radius", _("Radius (pixels)"), 100, 0..1000, 1),
    ParamDef.SLIDER("lighting", _("Lighting (degrees)"), 45, 0..360, 1),
    ParamDef.TOGGLE("shadow", _("Shadow"), 1),
    ParamDef.COLOR("bg color", _("Background Color"), Color(1.0, 1.0, 1.0)),
    ParamDef.COLOR("color", _("Sphere Color"), Color(1.0, 0.0, 0.0)),
  ],
  :results => [ParamDef.IMAGE("image", _("Sphere Image"))]
}

RubyFu.register(rfsphere) do |run_mode, radius, light, shadow, bg_color, sphere_color|
  include PDB::Access


  shadow = (shadow == 1)
  
  width  = radius * 3.75
  height = radius * 2.5

  image = Image.new(width, height, 0)

  Context.push do
    image.undo_disable do
      radians = light * Math::PI / 180
      cx = width / 2
      cy = height / 2
      light_x = cx + radius * 0.6 * Math.cos(radians)
      light_y = cy - radius * 0.6 * Math.sin(radians)
      light_end_x = cx + radius * Math.cos(radians + Math::PI)
      light_end_y = cy - radius * Math.sin(radians + Math::PI)
      offset = radius * 0.1
  
      layer = Layer.new(image, width, height, RGB_IMAGE,
                        _("Sphere Layer"), 100, NORMAL_MODE)
      image.insert_layer(layer, nil, 0)
      
      Context.set_foreground(sphere_color)
      Context.set_background(bg_color)
      Edit.fill(layer, FILL_BACKGROUND)
  
      Context.set_background(Color(0.1, 0.1, 0.1))
  
      if shadow and ((45 >= light and light <= 75) or
                    (105 >= light and light <= 135))
        shadow_w = radius * 2.5 * Math.cos(radians + Math::PI)
        shadow_h = radius * 0.5
        shadow_x = cx
        shadow_y = radius * 0.65 + cy
        if shadow_w < 0
          shadow_x = shadow_w + cx
          shadow_w = - shadow_w
        end
        
        Context.set_antialias true
        Context.set_feather true
        Context.set_feather_radius 7.5, 7.5
        image.select_ellipse(CHANNEL_OP_REPLACE, shadow_x, shadow_y, shadow_w, shadow_h)
        Edit.bucket_fill(layer, BUCKET_FILL_BG, MULTIPLY_MODE, 100, 0, false, 0, 0)
      end
      
      Context.set_feather false
      image.select_ellipse(CHANNEL_OP_REPLACE, cx - radius, cy - radius, radius * 2, radius * 2)
      Edit.blend(layer, BLEND_FG_BG_RGB, NORMAL_MODE, GRADIENT_RADIAL, 100, offset,
                 REPEAT_NONE, false, false, 0, 0, true, 
                 light_x, light_y, light_end_x, light_end_y)
      Selection.none(image)
    end
  end
  
  Display.new(image)
  
  image
end


RubyFu.register(
  :name       => "ruby-fu-sphere-precision",
  :blurb      => _("Simple sphere with a drop shadow on 16bits image, Gimp >= 2.9"),
  :help       => _("Simple sphere with a drop shadow on 16bits image\n Usable only on Gimp >= 2.9"),
  :author     => "Spencer Kimball and Scott Lembcke, xy",
  :copyright  => "Spencer Kimball, xy",
  :date       => "2015",
  :menulabel   => _("Sphere 16bits linear-float"),
  :imagetypes => "",
  :params     => [
    ParamDef.SPINNER("radius", _("Radius (pixels)"), 100, 0..1000, 1),
    ParamDef.SLIDER("lighting", _("Lighting (degrees)"), 45, 0..360, 1),
    ParamDef.TOGGLE("shadow", _("Shadow"), 1),
    ParamDef.COLOR("bg color", _("Background Color"), Color(1.0, 1.0, 1.0)),
    ParamDef.COLOR("color", _("Sphere Color"), Color(1.0, 0.0, 0.0)),
  ],
  :results => [ParamDef.IMAGE("image", _("Sphere Image"))]    
    
) do |run_mode, radius, light, shadow, bg_color, sphere_color|
  include PDB::Access

  shadow = (shadow == 1)
  width  = radius * 3.75
  height = radius * 2.5
  image = Image.new_with_precision(width, height, RGB, PRECISION_HALF_LINEAR )

  Context.push do
    image.undo_disable do
      radians = light * Math::PI / 180
      cx = width / 2
      cy = height / 2
      light_x = cx + radius * 0.6 * Math.cos(radians)
      light_y = cy - radius * 0.6 * Math.sin(radians)
      light_end_x = cx + radius * Math.cos(radians + Math::PI)
      light_end_y = cy - radius * Math.sin(radians + Math::PI)
      offset = radius * 0.1
      
      layer = image.addLayer(width, height, RGB_IMAGE,
                             _("Sphere Layer"), 100, NORMAL_MODE, 0)
      
      Context.set_foreground(sphere_color)
      Context.set_background(bg_color)
      Edit.fill(layer, FILL_BACKGROUND)
  
      Context.set_background(Color(0.1, 0.1, 0.1))
  
      if shadow and ((45..75).include? light or
                    (105..135).include? light)
        shadow_w = radius * 2.5 * Math.cos(radians + Math::PI)
        shadow_h = radius * 0.5
        shadow_x = cx
        shadow_y = radius * 0.65 + cy
        if shadow_w < 0
          shadow_x = shadow_w + cx
          shadow_w = - shadow_w
        end
        
        Context.set_antialias true
        Context.set_feather true
        Context.set_feather_radius 7.5, 7.5
        image.select_ellipse(CHANNEL_OP_REPLACE, shadow_x, shadow_y, shadow_w, shadow_h)
        Edit.bucket_fill(layer, BUCKET_FILL_BG, MULTIPLY_MODE, 100, 0, false, 0, 0)
      end
      
      Context.set_feather false
      image.select_ellipse(CHANNEL_OP_REPLACE, cx - radius, cy - radius, radius * 2, radius * 2)
      Edit.blend(layer, BLEND_FG_BG_RGB, NORMAL_MODE, GRADIENT_RADIAL, 100, offset,
                 REPEAT_NONE, false, false, 0, 0, true, 
                 light_x, light_y, light_end_x, light_end_y)
      Selection.none(image)
    end
  end
  
  Display.new(image)
  
  image
end


["ruby-fu-sphere", "ruby-fu-sphere-precision"].each do |fn|
    RubyFu.menu_register(fn, "<Image>/File/Create/RubyFu")
end


