#!ruby

require "rubyfu"

include Gimp
include RubyFu

RubyFu.register(
    :name       => "ruby-fu-lithprint-colorize",
    :blurb      => "colorize whites like in a lith print",
    :help       => "colorize whites like in a lith print",
    :author     => "xy",
    :copyright  => "xy",
    :date       => "june2013",
    :menulabel  => "lith print colorization on whites",
    :imagetypes => "*",
    :params     => [],
    :results    => []

) do |run_mode, image, drawable|
	include PDB::Access
	Context.push do
		image.undo_group_start do
			
			lp = image.addLayer_from_drawable(drawable, 0)
			
			if lp.group?
			    visibles = image.layersOO.each_with_object({}) do |l, obj|
			        unless l == lp
                        obj[l] = l.get_visible 
                        l.set_visible(false)
                    end
			    end
			    lp = image.merge_visible_layers(CLIP_TO_IMAGE)
			    visibles.each { |k,v| k.set_visible(v) }
			end
			
			lpMask = lp.create_mask(ADD_MASK_COPY)
			lp.add_mask(lpMask)
			
			lp.colorize_hsl(30, 32, 0)
			
			lp.set_mode(OVERLAY_MODE)
			lp.set_opacity(20.0)
			lp.set_name("old whites")
			
		end # undo_group
	end # Context
	Display.flush
end

RubyFu.menu_register("ruby-fu-lithprint-colorize", "<Image>/Fus/Ruby-Fu/")

