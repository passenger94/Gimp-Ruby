#!/usr/bin/env ruby

require "rubyfu"

include Gimp
include RubyFu


RubyFu.register(
    :name       => "ruby-fu-group_visible_layers_merge",
    :blurb      => "Group visible layers and merge a copy",
    :help       => "Group visible layers and merge a copy",
    :author     => "xy",
    :copyright  => "xy",
    :date       => "june 2013",
    :menulabel  => "Group Visible Layers and Merge",
    :imagetypes => "*",
    :params     => [],
    :results    => []
    
) do |run_mode, image, drawable|
    include PDB::Access
    
    image.undo_group_start do
        l_group = gimp_layer_group_new(image)
        image.insert_layer(l_group, nil, 0)
        l_group.set_name "Group"
        l_group.set_visible(false)  #so it doesn't go into V_layers  ##item != new_parent' failed
        
        image.layersOO.select {|l| l.get_visible == 1}.reverse!.each {|i| image.reorder_item(i, l_group, 0)}
        
        layer_copy = l_group.copy(false)
        image.insert_layer(layer_copy, nil, 0)
        layer_copy.set_visible(true)
        merged_layer = image.merge_visible_layers(CLIP_TO_IMAGE)
        merged_layer.set_name "merged#{l_group.get_name}"
    end
    Display.flush
end

RubyFu.register(
    :name       => "ruby-fu-group_visible_layers", 
    :blurb      => "Group visible layers", 
    :help       => "Group visible layers", 
    :author     => "xy", 
    :copyright  => "xy", 
    :date       => "june 2013", 
    :menulabel  => "Group visible layers",
    :imagetypes => "*",
    :params     => [],
    :results    => [] 
    
) do |run_mode, image, drawable|
    include PDB::Access

    image.undo_group_start do
        l_group = gimp_layer_group_new(image)
        image.insert_layer(l_group, nil, 0)
        l_group.set_name "Group"
        
        l_group.set_visible(false)  #so it doesn't go into V_layers  ##item != new_parent' failed
        
        image.layersOO.select {|l| l.get_visible == 1}.reverse!.each {|i| image.reorder_item(i, l_group, 0)}
        
        l_group.set_visible(true)
    end
    Display.flush
end #register

RubyFu.register(
    :name       => "ruby-fu-group_copy_merge", 
    :blurb      => "Copy Merge layers", 
    :help       => "Copy Merge layers", 
    :author     => "xy", 
    :copyright  => "xy", 
    :date       => "june 2013", 
    :menulabel  => "Copy Merge layers",
    :imagetypes => "*",
    :params     => [],
    :results    => [] 
    
) do |run_mode, image, drawable|
    include PDB::Access
    
    image.undo_group_start do
        vlayers = image.layersOO.select {|l| l.get_visible == TRUE}
        active_layer = image.get_active_layer
        layer_copy = active_layer.copy(false)
        image.insert_layer(layer_copy, nil, 0)
        image.layersOO.each {|l| l.set_visible(false) unless l.to_int == layer_copy.to_int}
        #layer_copy.set_visible(true)
        merged_layer = image.merge_visible_layers(CLIP_TO_IMAGE)
        merged_layer.set_name "merged#{active_layer.get_name}"
        vlayers.each {|l| l.set_visible(true)}
    end
    Display.flush
end

["ruby-fu-group_visible_layers_merge", "ruby-fu-group_copy_merge",
        "ruby-fu-group_visible_layers"].each {|fn| RubyFu.menu_register(fn, "<Layers>/Groups")}
