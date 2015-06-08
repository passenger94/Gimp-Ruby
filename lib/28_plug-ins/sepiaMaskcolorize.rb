#!/usr/bin/env ruby

require "rubyfu"

include Gimp
include RubyFu

RubyFu.register(
    :name       => "ruby-fu-sepiaMask-colorize",
    :blurb      => "sepia with mask",
    :help       => "sepia with mask",
    :author     => "xy",
    :copyright  => "xy",
    :date       => "june2013",
    :menulabel  => "Sepia Mask",
    :imagetypes => "*",
    :params     => [],
    :results    => []
    
) do |run_mode, image, drawable|
    include PDB::Access
    Context.push do
        image.undo_group_start do
            
            sl = image.addLayer_from_drawable(drawable)
            
            if sl.group?
                visibles = image.layersOO.each_with_object({}) do |l,obj|
                    unless l == sl
                        obj[l] = l.get_visible 
                        l.set_visible(false)
                    end
                end
                sl = image.merge_visible_layers(CLIP_TO_IMAGE)
                visibles.each { |k,v| k.set_visible(v) }
            end
            
            gimp_invert(sl.addMask(ADD_COPY_MASK))
            
            # should be set to default (on place) by gmic when non interactive,  but doesn't work ? so DIY
            gimp_procedural_db_set_data("gmic_output_mode", 4, [2,0,0,0].pack("c*")) #  on place
            plug_in_gmic(image, sl, 1, " -sepia") # 1 = active layer as input
            
            sl.set_mode(OVERLAY_MODE)
            sl.set_opacity(20.0)
            sl.set_name("GMIC sepia")
            
        end # undo_group
    end # Context
    Display.flush
end

RubyFu.menu_register("ruby-fu-sepiaMask-colorize", "<Image>/Fus/Ruby-Fu/")

