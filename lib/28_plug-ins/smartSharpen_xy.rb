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
    :menulabel  => "xy_smartSharpen", #menulabel
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
        
        #    Settting convenient default values for plug_in_unsharp_mask   
        # plug_in_unsharp_mask expect float, float, int32 as arguments type (see pdb browser)
        # we pack the arguments array into a string of bytes given a format : d is for float , i is integer
        # See Array#pack for docs and the return values of "gimp_procedural_db_get_data"
        gimp_procedural_db_set_data("plug-in-unsharp-mask", 20, [1.0, 2.9, 0].pack("d2i"))
        
        PDB.call_interactive("plug_in_unsharp_mask", image, SharpenLayer)
        SharpenLayer.set_opacity(80.0)
    end
    
    Display.flush
end

menu_register("ruby-fu-smartSharpen_xy", "<Image>/Fus/Ruby-Fu/")

