#!ruby

require "rubyfu"

include Gimp
include RubyFu

register(
  :name       => "ruby-fu-smartSharpen",
  :blurb      => "Smart Edge sharpening",
  :help       => "Smart Edge sharpening",
  :author     => "xy",
  :copyright  => "xy",
  :date       => "2008",
  :menulabel  => "smart Sharpen",
  :imagetypes => "RGB*",
  :params     => [],
  :results    => []

) do |run_mode, image, drawable|
  include PDB::Access
  
  image.undo_group_start do
	hsv_image = plug_in_decompose(image, drawable, "Value", 1)[0] 
    v_layer = hsv_image.get_active_layer
  	
	sharpen_layer = image.addLayer_from_drawable(drawable)
	sharpen_layer.set_mode(VALUE_MODE)
	sharpen_layer.set_name "Sharpening"
	
	Edit.copy(v_layer)
	gimp_floating_sel_anchor(Edit.paste(sharpen_layer, true))
	hsv_image.delete
	
	mask = sharpen_layer.addMask(ADD_MASK_BLACK)
	
	lab_image = plug_in_decompose(image, drawable, "LAB", 1)[0]
	l_layer = lab_image.get_layer_by_name("L")

	l_layer.levels_stretch
	PDB.call_interactive("plug_in_edge", lab_image, l_layer)
	## new pdb gegl ?????
	##PDB.call_interactive('plug_in_gauss', lab_image, l_layer)
    # temporary (slow) replacement
    PDB.call_interactive "plug-in-sel-gauss", lab_image, l_layer
	
	Edit.copy(l_layer)
	gimp_floating_sel_anchor(Edit.paste(mask, true))
	sharpen_layer.set_edit_mask(false)
	
	lab_image.delete
	
    #    Settting convenient default values for plug_in_unsharp_mask   
    # plug_in_unsharp_mask expect float, float, int32 as arguments type (see pdb browser)
    # we pack the arguments array into a string of bytes given a format : d is for float , i is integer
    # See Array#pack for docs and the return values of "gimp_procedural_db_get_data"
    gimp_procedural_db_set_data("plug-in-unsharp-mask", 20, [1.0, 2.9, 0].pack("d2i"))
    
	PDB.call_interactive("plug_in_unsharp_mask", image, sharpen_layer)
	sharpen_layer.set_opacity(80.0)
  end
  
  Display.flush
end

menu_register("ruby-fu-smartSharpen", "<Image>/Fus/Ruby-Fu/")

