#!/usr/bin/env ruby


require "rubyfu"

include Gimp
include RubyFu

RubyFu.register(
    :name       => "ruby-fu-sepia-colorize",
    :blurb      => "sepia",
    :help       => "sepia",
    :author     => "xy",
    :copyright  => "xy",
    :date       => "june2013",
    :menulabel  => "Sepia",
    :imagetypes => "*",
    :params     => [],
    :results    => []
    
) do |run_mode, image, drawable|
    include PDB::Access
    
    gimp_message_set_handler(ERROR_CONSOLE)
    unless gimp_procedural_db_proc_exists("plug-in-gmic").to_bool
        message "We need Gmic plugin to operate !" 
    else
        Context.push do
            image.undo_group_start do
                
                sl = image.addLayer_from_drawable(drawable, 0)
                
                if sl.group?
                    visibles = image.layersOO.each_with_object({}) do |l,obj|
                        unless l.to_int == sl.to_int
                            obj[l] = l.get_visible
                            l.set_visible(false)
                        end
                    end
                    sl = image.merge_visible_layers(CLIP_TO_IMAGE)
                    visibles.each { |k,v| k.set_visible(v) }
                end
                
                # preparing gmic
                gimp_procedural_db_set_data("gmic_current_filter", 4, [116, 0,0,0].pack("c4")) # sepia
                gimp_procedural_db_set_data("gmic_current_treepath", 5, "5:30\000")
                    gimp_procedural_db_set_data("gmic_filter116_parameter0", 2, "1\000")  # 1 
                    gimp_procedural_db_set_data("gmic_filter116_parameter1", 2, "1\000")  # 1
                    gimp_procedural_db_set_data("gmic_filter116_parameter2", 2, "0\000")  # 0
                    gimp_procedural_db_set_data("gmic_filter116_parameter3", 2, "0\000")  # 0
                gimp_procedural_db_set_data("gmic_input_mode", 4, [3,0,0,0].pack("c*")) #  active
                gimp_procedural_db_set_data("gmic_output_mode", 4, [2,0,0,0].pack("c*")) #  on place
                
                PDB.call_interactive("plug_in_gmic", image, sl)
                
                sl.set_mode(OVERLAY_MODE)
                sl.set_opacity(20.0)
                sl.set_name("GMIC sepia")
                
            end # undo_group
        end # Context
        Display.flush
    end
end

RubyFu.menu_register("ruby-fu-sepia-colorize", "<Image>/Fus/Ruby-Fu/")

