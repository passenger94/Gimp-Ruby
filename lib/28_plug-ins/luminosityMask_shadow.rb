#!/usr/bin/env ruby

require "rubyfu"

include Gimp
include RubyFu

RubyFu.register(
    :name       => "ruby-fu-luminosity_masks",
    :blurb      => _("enhance highlights and Shadows"),
    :help       => _("enhance highlights and Shadows"),
    :author     => "xy",
    :copyright  => "xy",
    :date       => "2013",
    :menulabel  => "Luminosity Masks",
    :imagetypes => "*",
    :params     => [],
    :results    => []
    
) do |run_mode, image, drawable|
    include PDB::Access
    
    Context.push do
        image.undo_group_start do
            
            lab_image = plug_in_decompose(image, drawable, "LAB", 1)[0]
            l_layer = lab_image.get_layer_by_name("L")
            
            Edit.copy(l_layer)
            
            mult = image.addLayer_from_drawable(drawable)
            multMask = mult.addMask(ADD_BLACK_MASK)
            Edit.pasteAnchor(multMask)
            mult.set_mode(MULTIPLY_MODE)
            mult.set_opacity(80.0)
            mult.set_name("Highlights")
            
            scr = image.addLayer_from_drawable(drawable)
            scrMask = scr.addMask(ADD_BLACK_MASK)
            Edit.pasteAnchor(scrMask)
            gimp_invert(scrMask)
            scr.set_mode(SCREEN_MODE)
            scr.set_name("Shadows") 
            
            lab_image.delete
        end # undo_group
    end # Context
    Display.flush
end

RubyFu.menu_register("ruby-fu-luminosity_masks", "<Image>/Fus/Ruby-Fu/")

