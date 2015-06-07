#!ruby

require 'rubyfu'

include Gimp
include RubyFu

RubyFu.register(
	  :name       => 'ruby-fu-clarity',
	  :blurb      => 'Clarity filter',
	  :help       => 'Clarity filter',
	  :author     => 'John Lakkas, xy',
	  :copyright  => 'John Lakkas, xy',
	  :date       => '2014',
	  :menulabel   => 'clarity',
	  :imagetypes => '*',
	  :params     => [
	                  RubyFu::ParamDef.SLIDER("radius", "Radius", 400, (1.0..500.0), 1.0),
	                  RubyFu::ParamDef.SLIDER("amount", "Amount", 0.9, (0.0..10), 0.1),
	                  RubyFu::ParamDef.TOGGLE("grouping", "grouping layers ? ", 0)
	                 ],
	  :results    => []

) do |run_mode, image, drawable, radius, amount, grouping|
	include PDB::Access
	gimp_message_set_handler(ERROR_CONSOLE)
	
    Context.push do
        image.undo_group_start do
            
            #layer_tmp = image.addLayer_from_drawable(drawable)
            #layer_tmp.desaturate DESATURATE_LIGHTNESS
                # getting midtones  
                ## waiting for access to GEGL plugins ?, no interactive mode !
            #PDB.call_interactive("gimp_drawable_curves_spline", image, layer_tmp) 
            #layer_tmp.curves_spline(HISTOGRAM_VALUE, 6, [25.0, 0.0, 50.0, 100.0, 75.0, 0.0]) # on more than 8bits image (0-255 otherwise)
                #layer_tmp2 = layer_tmp.copy(false)
                #image.insert_layer(layer_tmp2, nil, -1)
                #gimp_invert(layer_tmp2)
                #layer_tmp2.set_mode(DIFFERENCE_MODE)
                #layer_tmp = layer_tmp2.mergeDown(CLIP_TO_IMAGE)
                #gimp_invert(layer_tmp)
            
            # getting midtones
            L = Selection.save(image) #creates a channel
            buffer = Edit.named_copy(drawable, "temp")
            gimp_floating_sel_anchor( Edit.named_paste(L, buffer, TRUE) )
            gimp_buffer_delete(buffer)
            D = L.copy
            image.insert_channel(D, 0, 1)
            gimp_invert(D)
            M = L.copy
            image.insert_channel(M, 0, 3)
            M.set_name("M-#{drawable.get_name}")
            M.combine_masks(D, CHANNEL_OP_INTERSECT, 0, 0)
            image.remove_channel L; image.remove_channel D
            
            layer_usm = image.addLayer_from_drawable(drawable)
            layer_usm.set_name "USM Filter"
            plug_in_unsharp_mask(image, layer_usm, radius, amount, 0)
            
            image.set_active_channel M # mandatory
            layer_usm.add_mask layer_usm.create_mask(ADD_MASK_CHANNEL)  
            
            if grouping.to_bool
                layer_base = image.addLayer_from_drawable(drawable)
                layer_base.set_name "Base"
                l_group = gimp_layer_group_new(image)
                image.insert_layer(l_group, nil, 0)
                l_group.set_name "Clarity filter"
                [layer_base, layer_usm].each {|i| image.reorder_item(i, l_group, 0)}
            end
			
			gimp_progress_end # getting rid of annoying dialog warning 
		end # undo_group
    end # Context
	Display.flush
end

RubyFu.menu_register('ruby-fu-clarity', '<Image>/Fus/Ruby-Fu/')

