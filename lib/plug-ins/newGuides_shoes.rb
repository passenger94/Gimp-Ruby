#!ruby

require "rubyfu"
include Gimp
include RubyFu

require File.expand_path("shoesfu.rb", File.dirname(__FILE__))
include ShoesFu


RubyFu.register(
    :name       => "ruby-fu-shoesnewGuides",
    :blurb      => "...",
    :help       => "......",
    :author     => "xy",
    :copyright  => "xy",
    :date       => "2008",
    :menulabel   => "shoes's new guides(% or px)... ",
    :imagetypes => "*",
    :params     => [],
    :results    => []
    
) do |run_mode, image, drawable|
    include PDB::Access
    gimp_message_set_handler(ERROR_CONSOLE)
    
    ret = go_steppin("newGuides_shoesgui.rb", [image.get_name, image.width, image.height].to_json)
    
    unless ret.first == "cancelled"
        # message "placing guides... " + ret[0].inspect
        
        hguides, vguides, cleaning = JSON.parse(ret[0])
        
        Context.push do
            image.undo_group_start do
                while (g = image.find_next_guide(0)) != 0
                    image.delete_guide g
                end if cleaning
                
                hguides.each do |g|
                    image.add_hguide( g.is_a?(Float) ? (image.height * g / 100).to_i : g )
                end unless hguides == [0]
                
                vguides.each do |g|
                    image.add_vguide( g.is_a?(Float) ? (image.width * g / 100).to_i : g )
                end unless vguides == [0]
                
            end # undo_group
        end # Context
        Display.flush
    end
end

RubyFu.menu_register("ruby-fu-shoesnewGuides", "<Image>/Image/Guides") 

