#!/usr/bin/env ruby

require 'rubyfu'

include Gimp
include RubyFu

RubyFu.register(
    :name       => 'ruby-fu-blur-average',
    :blurb      => '...',
    :help       => '......',
    :author     => 'xy',
    :copyright  => 'xy',
    :date       => '2014',
    :menulabel  => 'blur average',
    :imagetypes => '*',
    :params     => [],
    :results    => []

) do |run_mode, image, drawable|
    include PDB::Access
    gimp_message_set_handler(ERROR_CONSOLE)

    Context.push do
        image.undo_group_start do
            
            w2 = (drawable.width / 2).to_i
            h2 = (drawable.height / 2).to_i
            max = w2 > h2 ? w2 : h2
            col = image.pick_color(drawable, w2, h2, false, true, max)
            Context.set_foreground(col)
            Edit.fill(drawable, 0)
            
        end
    end
    Display.flush
end

RubyFu.menu_register('ruby-fu-blur-average', '<Image>/Fus/Ruby-Fu/')

