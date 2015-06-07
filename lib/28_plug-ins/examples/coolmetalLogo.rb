#!/usr/bin/env ruby

require "rubyfu"

include Gimp
include RubyFu

RubyFu.register(
    :name       => "ruby-fu-cool-metal-logo",
    :blurb      => "Cool _Metal...",
    :help       => "Create a metallic logo with reflections and perspective shadows",
    :author     => "xy",
    :copyright  => "xy",
    :date       => "2008",
    :menulabel   => "cool metal",
    :imagetypes => nil,
    :params     => [
        ParamDef.STRING("text", "Text", "Cool Metal"),
        ParamDef.SPINNER("size","Font size (pixels)", 100, (2..1000), 1),
        ParamDef.FONT("font", "Font", "Crillee"),
        ParamDef.COLOR("bg_color", "Background color", Color(0.0, 0.0, 0.0)),
        ParamDef.GRADIENT("gradient","Gradient", "Horizon 1"),
        ParamDef.TOGGLE("gradient_reverse", "Gradient reverse", 0)
        ],
    :results    => []
) do |run_mode, text, size, font, bg_color, gradient, gradient_reverse|
	include PDB::Access
    
    img = Image.new 256, 256, RGB
    text_layer = TextLayer.new(img, text, font, size, PIXELS)
    text_layer.set_antialias true
    
	Context.push do
      img.undo_disable do
        #apply_cool_metal_logo_effect(img, text_layer, size, bg_color, gradient, gradient_reverse)
      end
	end
	Display.new(img)
end

RubyFu.menu_register("ruby-fu-cool-metal-logo", "<Image>/File/Create/RubyFu")

