#!ruby

require "rubyfu"
include RubyFu

RubyFu.register(
    :name       => "ruby-fu-wrap-effect",
    :blurb      => "draw with wrap effect",
    :help       => "draw with wrap effect",
    :author     => "Masahiro Sakai, iccii, xy",
    :copyright  => "Masahiro Sakai, iccii, xy",
    :date       => "2008",
    :menulabel   => "wrap effect ...",
    :imagetypes => "RGB*",
    :params     => [
            ParamDef.SPINNER("radius", "Randomness", 10, (0..32), 1),
            ParamDef.SPINNER("gamma1", "Highlight Balance", 3, (1..10), 0.5),
            ParamDef.SPINNER("gamma2", "Edge Amount", 3, (1..10), 0.5),
            ParamDef.TOGGLE("smooth", "Smooth", 0)
                   ],
    :results    => []
    
) do |run_mode, image, drawable, radius, gamma1, gamma2, smooth|
    include PDB::Access
    Context.push do
        image.undo_group_start do
            
            wraplayer = image.get_active_layer.copy(1)
            wraplayer.set_name "Wrap effect"
            image.insert_layer(wraplayer, nil, -1)
            
            plug_in_gauss_iir2(image, wraplayer, radius, radius)
            plug_in_edge(image, wraplayer, 10.0, 0, 0)
            wraplayer.set_mode(NORMAL_MODE)
            wraplayer.desaturate(DESATURATE_LUMINANCE)
            gimp_invert(wraplayer)
            plug_in_gauss_iir2(image, wraplayer, 5, 5) if smooth == 1
            Edit.copy(wraplayer)
            
            2.times {wraplayer.levels(HISTOGRAM_VALUE, 0, 1, gamma1 / 10, 0, 1)}
            
            wrapMask = wraplayer.create_mask(ADD_MASK_WHITE)
            wraplayer.add_mask(wrapMask)
            
            gimp_floating_sel_anchor(Edit.paste(wrapMask, true))
            2.times {wrapMask.levels(HISTOGRAM_VALUE, 0, 1, gamma2 / 10, 0, 1)}
            
            gimp_progress_end # getting rid of annoying dialog warning 
        end # undo_group
    end # Context
    Display.flush
end

RubyFu.menu_register("ruby-fu-wrap-effect", "<Image>/Fus/Ruby-Fu/Alchemy")

