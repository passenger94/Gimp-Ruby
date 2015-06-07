#!/usr/bin/env ruby

require 'rubyfu'

include Gimp
include RubyFu

RubyFu.register(
    :name       => 'ruby-fu-sg-luminosity-masks',
    :blurb      => '...',
    :help       => '......',
    :author     => 'saul goode',
    :copyright  => 'saul goode',
    :date       => '2014',
    :menulabel  => 'sg-luminosity-masks',
    :imagetypes => '*',
    :params     => [],
    :results    => []

) do |run_mode, image, drawable|
    include PDB::Access
    gimp_message_set_handler(ERROR_CONSOLE)
    
    Context.push do
        image.undo_group_start do
            
            orig_sel = gimp_selection_save(image)
            L = Selection.save(image)
            Selection.none(image)
            masks = [L]
            
            name = drawable.get_name
            L.set_name("L-#{name}")
            
            buffer = Edit.named_copy(drawable, "temp")
            gimp_floating_sel_anchor( Edit.named_paste(L, buffer, TRUE) )
            gimp_buffer_delete(buffer)
            
            D = L.copy
            image.insert_channel(D, 0, 1)
            D.set_name("D-#{name}")
            gimp_invert(D)
            masks << D
            
            #DD = D.copy
            #image.insert_channel(DD, 0, 2)
            #DD.set_name("DD-#{name}")
            #DD.combine_masks(L, CHANNEL_OP_SUBTRACT, 0, 0)
            #masks << DD
            #
            #DDD = DD.copy
            #image.insert_channel(DDD, 0, 3)
            #DDD.set_name("DDD-#{name}")
            #DDD.combine_masks(L, CHANNEL_OP_SUBTRACT, 0, 0)
            #masks << DDD
            #
            #LL = L.copy
            #image.insert_channel(LL, 0, 1)
            #LL.set_name("LL-#{name}")
            #LL.combine_masks(D, CHANNEL_OP_SUBTRACT, 0, 0)
            #masks << LL
            #
            #LLL = LL.copy
            #image.insert_channel(LLL, 0, 2)
            #LLL.set_name("LLL-#{name}")
            #LLL.combine_masks(D, CHANNEL_OP_SUBTRACT, 0, 0)
            #masks << LLL
            
            M = L.copy
            image.insert_channel(M, 0, 3)
            M.set_name("M-#{name}")
            M.combine_masks(D, CHANNEL_OP_INTERSECT, 0, 0)
            masks << M
            
            #MM = LL.copy
            #image.insert_channel(MM, 0, 3)
            #MM.set_name("MM-#{name}")
            #gimp_invert(MM)
            #MM.combine_masks(DD, CHANNEL_OP_SUBTRACT, 0, 0)
            #masks << MM
            #
            #MMM = LLL.copy
            #image.insert_channel(MMM, 0, 3)
            #MMM.set_name("MMM-#{name}")
            #gimp_invert(MMM)
            #MMM.combine_masks(DDD, CHANNEL_OP_SUBTRACT, 0, 0)
            #masks << MMM
            
            image.select_item(CHANNEL_OP_REPLACE, orig_sel)
            if Selection.empty?(image) or drawable.mask_intersect == FALSE
                Selection.all(image)
            end
            
            Context.set_feather false
            image.select_rectangle( CHANNEL_OP_INTERSECT, 
                                    drawable.offsets[0], 
                                    drawable.offsets[1],
                                    drawable.width,
                                    drawable.height )
            
            Selection.invert(image)
            unless Selection.empty?(image)
                masks.map {|x| Edit.fill(x, FILL_WHITE); gimp_invert(x) }
            end
            
            image.select_item(CHANNEL_OP_REPLACE, orig_sel)
            image.remove_channel(orig_sel)
            
            if drawable.channel?
                image.set_active_layer(drawable)
                if drawable.layer_mask?
                    image.set_active_channel(drawable)
                    image.set_active_layer(gimp_layer_from_mask(drawable))
                end
            end
            
        end # undo_group
    end # Context
    Display.flush
end

RubyFu.menu_register('ruby-fu-sg-luminosity-masks', '<Image>/Fus/Ruby-Fu/')

