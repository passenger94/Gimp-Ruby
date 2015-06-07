#!ruby
$KCODE="U"

#   ** rubyfu-console **
#   image = Image.create(Image.list[1].last)
#   layer = Layer.create(image.get_layers[1].last)
## plug_in_gmic(@image, @layers[0], 1, " -sepia")
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
    :menulabel   => "lith print colorization on whites",
    :imagetypes => "*",
    :params     => [],
    :results => []

) do |run_mode, image, drawable|
	include PDB::Access
	Context.push do
		image.undo_group_start do
			
			lp = image.addLayer_from_drawable(drawable)
			
			if lp.group?
			    visibles = image.layersOO.inject({}) do |r,l|
			        unless l.to_int == lp.to_int
                        r[l] = l.get_visible 
                        l.set_visible(false)
                    end
			        r
			    end
			    lp = image.merge_visible_layers(CLIP_TO_IMAGE)
			    visibles.each { |k,v| k.set_visible(v) }
			end
			
			lpMask = lp.create_mask(ADD_COPY_MASK)
			lp.add_mask(lpMask)
			
			gimp_colorize(lp, 30, 32, 0)
			
			lp.set_mode(OVERLAY_MODE)
			lp.set_opacity(20.0)
			lp.set_name("old whites")
			
		end # undo_group
	end # Context
	Display.flush
end

RubyFu.menu_register("ruby-fu-lithprint-colorize", "<Image>/Fus/Ruby-Fu/")

