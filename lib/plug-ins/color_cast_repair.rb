#!ruby
require 'rubyfu'

include Gimp
include RubyFu

RubyFu.register(
	  :name       => 'ruby-fu-color_cast_repair',
	  :blurb      => 'simple color cast processing',
	  :help       => 'simple color cast processing, adjust layer opacity for fine tuning',
	  :author     => 'xy',
	  :copyright  => 'xy',
	  :date       => '2014',
	  :menulabel   => 'color cast repair',
	  :imagetypes => '*',
	  :params     => [],
	  :results    => []

) do |run_mode, image, drawable|
	include PDB::Access
	gimp_message_set_handler(ERROR_CONSOLE)
	
    Context.push do
        image.undo_group_start do
            
            #ly = image.addLayer_from_drawable(drawable)
            #
			## like blur average in PS
            #w2 = (ly.width / 2).to_i
            #h2 = (ly.height / 2).to_i
            #col = image.pick_color(ly, w2, h2, false, true, w2 > h2 ? w2 : h2)
            #Context.set_foreground( Color(1.0, 1.0, 1.0) - col ) #inverted color, also : Color(1-col.r, 1-col.g, 1-col.b)
            #ly.fill FILL_FOREGROUND
            #ly.set_mode COLOR_MODE
            #ly.set_opacity 20.0
            
            ly2 = image.addLayer_from_drawable(drawable)
            plug_in_pixelize2(image, ly2, ly2.width, ly2.height) ## like blur average in PS
            gimp_invert(ly2)
            ly2.set_mode COLOR_MODE
            ly2.set_opacity 35.0
            
		end # undo_group
    end # Context
	Display.flush
end

RubyFu.menu_register('ruby-fu-color_cast_repair', '<Image>/Fus/Ruby-Fu/')

