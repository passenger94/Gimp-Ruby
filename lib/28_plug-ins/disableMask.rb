#!/usr/bin/env ruby
$KCODE='U'

require 'rubyfu'

include Gimp
include RubyFu

RubyFu.register(
	  :name       => 'ruby-fu-disable_mask',
	  :blurb      => 'Ctrl-Shift-M',
	  :help       => 'Ctrl-Shift-M',
	  :author     => 'xy',
	  :copyright  => 'xy',
	  :date       => '2014',
	  :menulabel   => 'toggle layer mask',
	  :imagetypes => '*',
	  :params     => [],
	  :results    => []

) do |run_mode, image, drawable|
	include PDB::Access
	gimp_message_set_handler(ERROR_CONSOLE)
	
    Context.push do
        image.undo_group_start do
            # if the layer mask is active get the layer
            drw = drawable.is_layer_mask == 1 ? gimp_layer_from_mask(drawable) : drawable
            
			gimp_layer_set_apply_mask(drw, gimp_layer_get_apply_mask(drw) == 0 ? true : false)
            
		end # undo_group
    end # Context
	Display.flush
end

RubyFu.menu_register('ruby-fu-disable_mask', '<Layers>')

