#!/usr/bin/env ruby
$KCODE='U'

require 'rubyfu'

include Gimp
include RubyFu

RubyFu.register(
	  :name       => 'ruby-fu-bilateral-luma-chroma',
	  :blurb      => 'Gmic selective bilateral smooth on LAB',
	  :help       => 'Gmic selective bilateral smooth on LAB channels and recompose as a new layer',
	  :author     => 'xy',
	  :copyright  => 'xy',
	  :date       => '2013',
	  :menulabel   => 'bilateral Luma Chroma',
	  :imagetypes => '*',
	  :params     => [
			ParamDef.TOGGLE('keep', 'keep intermediate LAB image ?', 0)	
					],
	  :results    => []

) do |run_mode, image, drawable, keep|
	include PDB::Access
	#gimp_message_set_handler(ERROR_CONSOLE)
	
    Context.push do
        image.undo_group_start do
            
            new_layer = image.addLayer_from_drawable(drawable)
            
            lab_image = plug_in_decompose(image, new_layer, "LAB", true)[0]
            l_layer, a_layer, b_layer = lab_image.layersOO
            
            
            ### initializing gmic bilateral (info in "./gmic_gimp.cpp" and "~/.update1552.gmic")
            ### get/set_data happens in RAM (no files, not persistent)
            #data = gimp_procedural_db_get_data("gmic_current_filter") # data[0] = 4 bytes -> unpack("c4")
            #puts data[1].unpack("c4") # with 'gimp_message_set_handler(ERROR_CONSOLE)' commented out
            
            gimp_procedural_db_set_data("gmic_current_filter", 4, [90, 1,0,0].pack("c4")) # [89, 1,0,0].pack("c4") ="Y\x01\x00\x00"; "Y\x01\x00\x00".unpack("I") = 345
            filterID = gimp_procedural_db_get_data("gmic_current_filter")[1].unpack("I") # = 345
            gimp_procedural_db_set_data("gmic_filter#{filterID}_parameter0", 4, "1.75")
            gimp_procedural_db_set_data("gmic_filter#{filterID}_parameter1", 4, "1.75")
            gimp_procedural_db_set_data("gmic_filter#{filterID}_parameter2", 1, "1")
            
            gimp_procedural_db_set_data("gmic_output_mode", 4, [2,0,0,0].pack("c*")) # 2 -> output on place
            gimp_procedural_db_set_data("gmic_current_treepath", 5, [49, 54, 58, 49, 55].pack("c5")) # 16:17 -> row 17 inside row 16
            
            
            # gmic use active layer and preview is not refreshed if changes !
            [l_layer, a_layer, b_layer].each do |lyr|
                lab_image.set_active_layer lyr
                PDB.call_interactive("plug-in-gmic", lab_image, lyr)
            end
            
            plug_in_recompose(lab_image, l_layer)
            new_layer.set_name("LAB bilateral")
            
            if keep.to_bool
                lab_image.set_filename("#{image.get_filename}_LabLayers")
                Display.new(lab_image)
            else
                lab_image.delete
            end
                                                                       
		end # undo_group
    end # Context
	Display.flush
end

RubyFu.menu_register('ruby-fu-bilateral-luma-chroma', '<Image>/Fus/Ruby-Fu/')

# sepia
# b = 26; a = [45, 118, 32, 45, 57, 57, 32, 45, 103, 105, 109, 112, 95, 115, 101, 112, 105, 97, 32, 49, 44, 49, 44, 48, 44, 48]
# gimp_procedural_db_set_data("gmic_current_filter", 4, [122, 0,0,0].pack("c4"))
# gimp_procedural_db_set_data("gmic_commands_line122", 26, "-v -99 -gimp_sepia 1,1,0,0")
# 

# blilateral
# gimp_procedural_db_set_data("gmic_current_filter", 4, [202, 0,0,0].pack("c4"))
# gimp_procedural_db_set_data("gmic_current_treepath", 5, "9:26\000") ## [57, 58, 50, 54, 0].pack("c5")
# gimp_procedural_db_set_data("gmic_commands_line202", 44, "-v -99 -gimp_bilateral 1.94175,2.42718,1,0,0")
# 

# custom command local
# gimp_procedural_db_set_data("gmic_current_filter", 4, [214,1,0,0].pack("c4"))
# etc ...

=begin

-rgb2ycbcr # split the image into 3 layers, 1 for luma, 2 for chroma
--split[0] c
-name[1] luma
-name[2] chromaB
-name[3] chromaR

-bilateral[luma] 1.25,1.25
# low values for luma, higher values for chroma

-apply_gamma[chromaB] {1/0.7} # makes image brighter and reduces contrast in the highlights
-bilateral[chromaB] 8.75,8.75
-apply_gamma[chromaB] 0.7 # Reverses the gamma change at the start to give correct brightness.

-apply_gamma[chromaR] 0.7 # makes image darker and reduces contrast in the shadows
-bilateral[chromaR] 8.75,8.75
-apply_gamma[chromaR] {1/0.7}

--append[luma,chromaB,chromaR] c
-name[4] cleaned
-ycbcr2rgb[cleaned]
-keep[cleaned]

=end

