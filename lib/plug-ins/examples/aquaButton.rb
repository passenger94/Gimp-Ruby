#!ruby

require "rubyfu"

include Gimp
include RubyFu


register(
	  :name       => "ruby-fu-aqua-button",
	  :blurb      => "Creates an Aqua-like button from the current selection",
	  :help       => "Creates an Aqua-like button from the current selection",
	  :author     => "xy",
	  :copyright  => "xy",
	  :date       => "2008",
	  :menulabel   => "Aqua button",
	  :imagetypes => "*",
	  :params     => [
		ParamDef.COLOR("c1", "Color of top of button", Color(0.09, 0.3, 0.56)),
		ParamDef.COLOR("c2", "Color of inner glow of button", Color(0.78, 0.96, 1.0)),
		ParamDef.INT16("xoffset", "Shadow Glow X Offset", 2),
		ParamDef.INT16("yoffset", "Shadow Glow Y Offset", 2),
		ParamDef.FLOAT("hstart", "Highlight Start (fraction of selection)", 0.125),
		ParamDef.FLOAT("hend", "Highlight End (fraction of selection)", 0.4),
		            ],
	  :results    => []

) do |run_mode, image, drawable, c1, c2, xoffset, yoffset, hstart, hend|
	include PDB::Access
	gimp_message_set_handler(ERROR_CONSOLE)
	
	def darken(color)
		col = Color(*color.marshal_dump[0..2].inject([]) {|r,x| r << 3*x/4} << color.a)
	end
	
	def lighten(color)
		# lighter = (3color + white) / 4 => 3 parts original color, one part white
		col = Color(*color.marshal_dump[0..2].inject([]) {|r,x| r << (3*x+1) / 4} << color.a)
	end
	
	Context.push do
		image.undo_group_start do
			
			non_empty, sx1, sy1, sx2, sy2 = Selection.bounds(image)
			break message("must have a selection !") unless non_empty == 1
			
			chan = Selection.save(image)
			bglayer = image.layersOO.last
			lwidth = bglayer.width
			lheight = bglayer.height
			
			sw = sx2 - sx1
			sh = sy2 - sy1
			md = sw > sh ? sw : sh
			sc = md * 0.015 + 1
			
			shadow = Layer.new(image, lwidth, lheight, RGBA_IMAGE, "shadow", 100,
														NORMAL_MODE)
			gradient = Layer.new(image, lwidth, lheight, RGBA_IMAGE, "gradient", 100,
													 NORMAL_MODE)
			highlight = Layer.new(image, lwidth, lheight, RGBA_IMAGE, "highlight", 100,
														NORMAL_MODE)
			[shadow, gradient, highlight].each {|l| l.fill(FILL_TRANSPARENT); image.insert_layer(l, nil, -1)}
			
			Context.set_foreground(darken(c2))
			Edit.bucket_fill(shadow, BUCKET_FILL_FG, NORMAL_MODE, 100, 0, false, 0, 0)
			
			Context.set_foreground(c1)
			Context.set_background(c2)
			Edit.blend(gradient, BLEND_FG_BG_RGB, NORMAL_MODE, GRADIENT_LINEAR, 100, 0,
								REPEAT_NONE, false, false, 1, 0, false, 0, sy1, 0, sy2)
			
			Context.set_foreground(Color(1,1,1))
			Selection.shrink(image, sc)
			Selection.feather(image, sc)
			Edit.blend(highlight, BLEND_FG_TRANSPARENT, NORMAL_MODE, GRADIENT_LINEAR, 100, 0,
				    REPEAT_NONE, false, false, 1, 0, false, 0, sy1+(sh*hstart), 0, sy1+(sh*hend))
			
			Selection.none(image)
			plug_in_gauss_iir(image, shadow, 4.0, sc, sc)
			shadow.set_offsets(xoffset, yoffset)
			
			#image.select_item(CHANNEL_OP_REPLACE, chan)
			#image.remove_channel(chan)

		end
	end
	Display.flush
end

menu_register("ruby-fu-aqua-button", "<Image>/Fus/Ruby-Fu/")





