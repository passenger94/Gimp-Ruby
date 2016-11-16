
require "rubyfu"

include Gimp
include RubyFu

RubyFu.register(
    :name       => "ruby-fu-hideAllExceptActive", 
    :blurb      => "hide all layers except active", 
    :help       => "hide all layers except active", 
    :author     => "xy", 
    :copyright  => "xy", 
    :date       => "2013", 
    :menulabel   => "Hide All Except Active", 
    :imagetypes => "*",
    :params     => [],
    :results    => []
    
) do |run_mode, image, drawable|
    include PDB::Access
    
    image.undo_group_start do
        image.layersOO.each {|l| l.set_visible(false) unless l == image.get_active_layer }
    end
    Display.flush
end

RubyFu.register(
    :name       => "ruby-fu-showAll",
    :blurb      => "show all layers",
    :help       => "show all layers",
    :author     => "xy",
    :copyright  => "xy",
    :date       => "2008",
    :menulabel   => "show All",
    :imagetypes => "*",
    :params     => [],
    :results    => []
    
) do |run_mode, image, drawable|
    include PDB::Access
    
    image.undo_group_start do
        image.layersOO.each {|l| l.set_visible(true)}
    end
    Display.flush
end

["ruby-fu-hideAllExceptActive", "ruby-fu-showAll"].each {|fn| RubyFu.menu_register(fn, "<Layers>/ShowHide")}

