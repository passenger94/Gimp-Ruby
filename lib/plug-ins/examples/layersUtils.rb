
require "rubyfu"

include Gimp
include RubyFu

RubyFu.register(
    :name       => "ruby-fu-hideAllExceptActive", #procedure name
    :blurb      => "hide all layers except active", #blurb
    :help       => "hide all layers except active", #help
    :author     => "xy", #author
    :copyright  => "xy", #copyright
    :date       => "2013", #date
    :menulabel   => "Hide All Except Active", #menulabel
    :imagetypes => "*", #image types
    :params     => [],
    :results    => [] #results
    
) do |run_mode, image, drawable|
    include PDB::Access
    
    image.undo_group_start do
        image.layersOO.each {|l| l.set_visible(false) unless l == image.get_active_layer }
    end
    Display.flush
end #register

RubyFu.register(
    :name       => "ruby-fu-showAll", #procedure name
    :blurb      => "show all layers", #blurb
    :help       => "show all layers", #help
    :author     => "xy", #author
    :copyright  => "xy", #copyright
    :date       => "2008", #date
    :menulabel   => "show All", #menulabel
    :imagetypes => "*", #image types
    :params     => [],
    :results    => [] #results
    
) do |run_mode, image, drawable|
    include PDB::Access
    
    image.undo_group_start do
        image.layersOO.each {|l| l.set_visible(true)}
    end
    Display.flush
end #register

["ruby-fu-hideAllExceptActive", "ruby-fu-showAll"].each {|fn| RubyFu.menu_register(fn, "<Layers>/ShowHide")}

