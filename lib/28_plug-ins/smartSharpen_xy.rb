#!ruby

require "rubyfu"

include Gimp
include RubyFu

register(
  :name       => "ruby-fu-smartSharpen_xy", #procedure name
  :blurb      => "Smart Edge sharpening", #blurb
  :help       => "Smart Edge sharpening", #help
  :author     => "xy", #author
  :copyright  => "xy", #copyright
  :date       => "2008", #date
  :menulabel   => "xy_smartSharpen", #menulabel
  :imagetypes => "RGB*", #image types
  :params     => [], #params
  :results    => [] #results

) do |run_mode, image, drawable|
  include PDB::Access
  
  image.undo_group_start do
	HSVimage = plug_in_decompose(image, drawable, "Value", 1)[0] 
    V_layer = HSVimage.get_active_layer
  	
	SharpenLayer = image.addLayer_from_drawable(drawable)
	SharpenLayer.set_mode(VALUE_MODE)
	SharpenLayer.set_name "Sharpening"
	
	Edit.copy(V_layer)
	gimp_floating_sel_anchor(Edit.paste(SharpenLayer, true))
	HSVimage.delete
	
	mask = SharpenLayer.addMask(ADD_BLACK_MASK)
	
	LABimage = plug_in_decompose(image, drawable, "LAB", 1)[0]
	L_layer = LABimage.get_layer_by_name("L")

	gimp_levels_stretch L_layer
	PDB.call_interactive("plug_in_edge", LABimage, L_layer)
	PDB.call_interactive('plug_in_gauss', LABimage, L_layer)
	
	Edit.copy(L_layer)
	gimp_floating_sel_anchor(Edit.paste(mask, true))
	SharpenLayer.set_edit_mask(false)
	
	LABimage.delete
	
    ## INT8ARRAY is implemented with String in Gimp-fu, need to convert !!
    ## data_int8array = [0, 0, 0, 0, 0, 0, 240, 63, 51, 51, 51, 51, 51, 51, 7, 64, 0, 0, 0, 0, 0, 0, 0, 0]
    ## got from pythonfu console : bytes, data = pdb.gimp_procedural_db_get_data("plug-in-unsharp-mask")
    ## script-fu console => (0 0 0 0 0 0 240 63 51 51 51 51 51 51 7 64 0 0 0 0 0 0 0 0)
    ## ASCII => \000 \000 \000 \000 \000\ 000\ 360 ? 3 3 3 3 3 3 \a @ \000 \000 \000 \000 \000 \000 \000 \000
    ## data = data_int8array.pack("C24")
    ## #data = "\000\000\000\000\000\000\360?333333\a@\000\000\000\000\000\000\000\000"
    ## data.unpack("ddi") =  [1.0, 2.9, 0]  (ddi stands for float, float, integer)
    ## "\x00\x00\x00\x00\x00\x00\xF0?".unpack("d") => [1.0]      | [1.0].pack("d") => "\000\000\000\000\000\000\360?"
    ## "333333\a@".unpack("d")=> [2.9]                           | [2.9].pack("d") => "333333\a@"
    ## "\000\000\000\000\000\000\000\000".unpack("i") => [0]     | [0].pack("i") => "\000\000\000\000"
    ## "\000\000\000\000\000\000\000\000".unpack("d") => [0.0]   | [0].pack("d") => "\000\000\000\000\000\000\000\000"
    
    #  Settting default values for plug_in_unsharp_mask
    # because plugin expect a (float, float, integer) values we use "d2q" q is 64 bits number or "d2i2" 2 32bits integers
    # 8 bytes (64 bits) for each value ?
    gimp_procedural_db_set_data("plug-in-unsharp-mask", 20, [1.0, 2.9, 0].pack("d2i")) # 24, [1.0, 2.9, 0,0].pack("d2i2")
    
	PDB.call_interactive("plug_in_unsharp_mask", image, SharpenLayer)
	SharpenLayer.set_opacity(80.0)
  end
  
  Display.flush
end

menu_register("ruby-fu-smartSharpen_xy", "<Image>/Fus/Ruby-Fu/")

