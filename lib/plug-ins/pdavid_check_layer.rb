#!/usr/bin/env ruby

require 'rubyfu'

include Gimp
include RubyFu

RubyFu.register(
    :name       => 'ruby-fu-check_layer',
    :blurb      => 'see blue channel quirks',
    :help       => '......',
    :author     => 'xy, pat david',
    :copyright  => 'xy, pat david',
    :date       => '2014',
    :menulabel  => 'check layer',
    :imagetypes => '*',
    :params     => [],
    :results    => []
    
) do |run_mode, image, drawable|
    include PDB::Access
    gimp_message_set_handler(ERROR_CONSOLE)
    
    Context.push do
        image.undo_group_start do
            
            yellow = image.addLayer_from_drawable(drawable)
            Context.set_foreground(Color(255/255.0, 255/255.0, 0/255.0))
            yellow.fill(FILL_FOREGROUND)
            yellow.set_mode(SUBTRACT_MODE)
            yellow.set_name("Yellow")
            
            white = image.addLayer_from_drawable(drawable)
            Context.set_foreground(Color(255/255.0, 255/255.0, 255/255.0))
            white.fill(FILL_FOREGROUND)
            white.set_mode(COLOR_MODE)
            white.set_name("White")
            
            dodge = image.addLayer_from_drawable(drawable)
            Context.set_foreground(Color(127/255.0, 127/255.0, 127/255.0))
            dodge.fill(FILL_FOREGROUND)
            dodge.set_mode(DODGE_MODE)
            dodge.set_name("Dodge")
            
            image.set_active_layer(drawable)
            
        end # undo_group
    end # Context
    Display.flush
end

RubyFu.menu_register('ruby-fu-check_layer', '<Image>/Fus/Ruby-Fu/')

