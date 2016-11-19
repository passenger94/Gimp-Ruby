#!ruby

require "rubyfu"
include RubyFu

require File.expand_path("shoesfu.rb", File.dirname(__FILE__))
include ShoesFu

RubyFu.register(
    :name       => "ruby-fu-shoesgimpmethods", 
    :blurb      => "Gimp introspection", 
    :help       => "Gimp introspection", 
    :author     => "xy", 
    :copyright  => "xy", 
    :date       => "2015", 
    :menulabel  => "shoes's Gimp methods", 
    :imagetypes => nil, 
    :params     => [], 
    :results    => [] 
    
) do |run_mode|
    include PDB::Access
    gimp_message_set_handler(ERROR_CONSOLE)
    
    Context.push do
        
        consts = Gimp.constants.each_with_object({:numeric => [], :string => [], :gobj => [:Gimp]}) do |c,obj|
            if Gimp.const_get(c).is_a?(Numeric)
                obj[:numeric] << c
            elsif Gimp.const_get(c).is_a?(String)
                obj[:string] << c
            else
                obj[:gobj] << c
            end
        end.each_value {|v| v.sort!}
        
        go_steppin("gimpmethods_shoesgui.rb", consts.to_json)
        
    end # Context
end

RubyFu.menu_register("ruby-fu-shoesgimpmethods", RubyFu::RubyFuToolbox)

