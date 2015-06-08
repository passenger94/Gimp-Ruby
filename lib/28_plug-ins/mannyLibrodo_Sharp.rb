#!ruby

require "rubyfu"

include Gimp
include RubyFu

RubyFu.register(
    :name       => "ruby-fu-mannyLibrodo_sharp",
    :blurb      => "manny Librodo's sharpening",
    :help       => "manny Librodo's sharpening",
    :author     => "xy",
    :copyright  => "xy",
    :date       => "2008",
    :menulabel  => "mannyLibrodo_sharp",
    :imagetypes => "*",
    :params     => [], 
    :results    => []
    
) do |run_mode, image, drawable|
    include PDB::Access
    Context.push do
        image.undo_group_start do
            
            sharp_base = image.addLayer_from_drawable(drawable)
            
            plug_in_unsharp_mask(image, sharp_base, 4, 0.18, 0)
            sharp_base.set_name("ML_base sharp")
            
            sharp_dark = image.addLayer_from_drawable(sharp_base)
            plug_in_unsharp_mask(image, sharp_dark, 0.3, 1.5, 0)
            
            sharp_light =  image.addLayer_from_drawable(sharp_dark)
            
            sharp_dark.set_mode(DARKEN_ONLY_MODE)
            sharp_dark.set_name("ML_dark sharp")
            
            sharp_light.set_mode(LIGHTEN_ONLY_MODE)
            sharp_light.set_opacity(50.0)
            sharp_light.set_name("ML_light sharp")
            
            l_group = gimp_layer_group_new(image)
            image.insert_layer(l_group, nil, 0)
            l_group.set_name "MLSharp"
            [sharp_base, sharp_dark, sharp_light].each {|i| image.reorder_item(i, l_group, 0)}
            
        end # undo_group
    end # Context
    Display.flush
end

RubyFu.menu_register("ruby-fu-mannyLibrodo_sharp", "<Image>/Fus/Ruby-Fu/")

