#!ruby

require "rubyfu"
include RubyFu

def processgrouplayer(img, layer)
    if layer.group?
        visibles = img.layersOO.each_with_object({}) do |l,obj|
            unless l == layer
                obj[l] = l.get_visible                       
                l.set_visible(false)
            end
        end
        layer = img.merge_visible_layers(CLIP_TO_IMAGE)
        visibles.each { |k,v| k.set_visible(v) }
    end
    layer
end

def addthemask(layer)
    mask = layer.create_mask(ADD_MASK_BLACK)
    layer.add_mask(mask)
    gimp_floating_sel_anchor(Edit.paste(mask, true))
    mask
end

RubyFu.register(
    :name       => "ruby-fu-lithprintsepia-colorize",
    :blurb      => "sepia on darks lith print on whites",
    :help       => "sepia on darks lith print on whites",
    :author     => "xy",
    :copyright  => "xy",
    :date       => "2008",
    :menulabel  => _("Sepia, Lith Print"),
    :imagetypes => "*",
    :params     => [],
    :results => []
    
) do |run_mode, image, drawable|
    include PDB::Access
    Context.push do
        image.undo_group_start do
            
            lab_image = plug_in_decompose(image, drawable, "LAB", 1)[0]
            l_layer = lab_image.get_layer_by_name("L")
            Edit.copy(l_layer)
            
            sepia = processgrouplayer(image, image.addLayer_from_drawable(drawable, 0))
            
            Context.set_foreground(Color(122/255.0, 44/255.0, 20/255.0)) # sepia  0.44, 0.17, 0.07
            sepia.fill(FILL_FOREGROUND)
            
            gimp_invert(addthemask(sepia))
            
            sepia.set_mode(OVERLAY_MODE)
            sepia.set_opacity(20.0)
            sepia.set_name("Sepia")
            
            lith = processgrouplayer(image, image.addLayer_from_drawable(drawable))
            addthemask(lith)
            
            Context.set_foreground(Color(1.0,0.84,0.68))
            lith.fill(FILL_FOREGROUND)
            lith.set_mode(OVERLAY_MODE)
            lith.set_opacity(20.0)
            lith.set_name("Old Whites")
            
            lab_image.delete
        end # undo_group
    end # Context
    Display.flush
end

RubyFu.menu_register("ruby-fu-lithprintsepia-colorize", "<Image>/Fus/Ruby-Fu/")

