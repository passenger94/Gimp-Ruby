#!ruby

require 'rubyfu'

include Gimp
include RubyFu

RubyFu.register(
	  :name       => 'ruby-fu-disable_mask',
	  :blurb      => 'assign a shortcut...',
	  :help       => 'intended to be used with a shortcut (no menu entry)',
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
	
    drw = drawable.layer_mask? ? gimp_layer_from_mask(drawable) : drawable
    
    gimp_layer_set_apply_mask(drw, gimp_layer_get_apply_mask(drw) == 0 ? true : false)
    
	Display.flush
end

# for use with a shortcut, i use : Ctrl+Shift M  
RubyFu.menu_register('ruby-fu-disable_mask', '<NoMenu>')

