#!ruby

require "rubyfu"
include Gimp
include RubyFu

dir = File.dirname(__FILE__)
require File.expand_path("shoesfu.rb", dir)
include ShoesFu

SAMPLESDIR = File.expand_path("#{dir}/../ruby_static")

samples = {
    "cavendish Morton" 			=> ["X01", "cavendishMorton_X_samplecolor.png"],
    "kerr Eby" 					=> ["X02", "KerrEby_X_samplecolor.png"],
    "joseph Sudek" 				=> ["X03", "josephSudek01_X_samplecolor.png"],
    "menlo" 					=> ["X20", "menlo_X_samplecolor.png"],
    "aMal Digital" 	        	=> ["X04", "annaMalinaTriesteDigital_X_samplecolor.png"],
    "xf1" 						=> ["X21", "fujifilmXF1_X_samplecolor.png"],
    "Mezzotint SunshineV" 		=> ["X06", "MezzotintSunshineV_X_samplecolor.png"],
    "lith Print 01" 			=> ["X07", "lithPrint01_X_samplecolor.png"],
    "kazban" 					=> ["X08", "kazban_X_samplecolor.png"],
    "intLost boat" 				=> ["X09", "intentionallyLostFlickr_boat_X_samplecolor.png"],
    "gumoil Roman Aytmurzin" 	=> ["X10", "gumoil_RomanAytmurzin_X_samplecolor.png"],
    "alt Process 01" 			=> ["X11", "altProcess01_X_samplecolor.png"],
    "sheet NB" 					=> ["X13", "drapNB_X_samplecolor.png"],
    "aMal Bulb" 	     		=> ["X14", "annaMalinaBulb_X_samplecolor.png"],
    "Carleton Eugene Watkins" 	=> ["X15", "CarletonEugeneWatkins_X_samplecolor.png"],
    "albumen Cairo" 			=> ["X17", "albumenCairo_X_samplecolor.png"],
    'bruxells' 		    		=> ["X18", 'bruxells01_X_samplecolor.png'],
    'Auxill' 			        => ["X19", 'Aux01_X_samplecolor.png'],
    "odilon Redon" 				=> ["X05", "odilonRedon01_X_samplecolor.png"],
    "alt Process Greenish" 		=> ["X12", "altProcess02Greenish_X_samplecolor.png"],
    "blueprint cyanotype" 		=> ["X16", "blueprint_X_samplecolor.png"]
}

samples.each do |k,v|
    RubyFu.register(
        :name       => "ruby-fu-sample_colorize_#{v[0]}",
        :blurb      => "sample colorize '#{k}'",
        :help       => "sample colorize '#{k}'",
        :author     => 'xy',
        :copyright  => 'xy',
        :date       => '2015',
        :menulabel  => k,
        :imagetypes => '*',
        :params     => [],
        :results    => []
        
    ) do |run_mode, image, drawable|
        include PDB::Access
        gimp_message_set_handler(ERROR_CONSOLE)
        
        Context.push do
            image.undo_group_start do
                sample_image = file_png_load("#{SAMPLESDIR}/#{v[1]}", "#{v[1]}")
                sample_drw = sample_image.layersOO[0]
                
                plug_in_sample_colorize(image, drawable, sample_drw, false, false, true, true, 0, 255, 1.0, 0, 255)    
                
                sample_image.delete
                
            end # undo_group
        end # Context
        Display.flush
    end
    
    RubyFu.menu_register("ruby-fu-sample_colorize_#{v[0]}", '<Image>/Fus/Ruby-Fu/extendedSampleColorize/thepdbmethods/')
end




RubyFu.register(
    :name       => "ruby-fu-shoes_sample_colorize",
    :blurb      => "Visualy choose a pattern for the sample-colorize plugin",
    :help       => "Visualy choose a pattern for the sample-colorize plugin",
    :author     => "xy",
    :copyright  => "xy",
    :date       => "2015",
    :menulabel  => "Shoes's sample colorize",
    :imagetypes => "*",
    :params     => [],
    :results    => []
    
) do |run_mode, image, drawable|
    include PDB::Access
    gimp_message_set_handler(ERROR_CONSOLE)
    
    Context.push do
        image.undo_group_start do
            
            copy_layer = image.addLayer_from_drawable(drawable)
            Display.flush
            
            ret = go_steppin("colorSamples_shoesgui.rb", [image.to_int, copy_layer.to_int, samples].to_json)
            
            PDB.send("ruby-fu-sample_colorize_#{ret.last}", image, drawable) unless ret.first == "cancelled"
            
            image.remove_layer(copy_layer)
        end # undo_group
        
        Display.flush
    end # Context
end

RubyFu.menu_register("ruby-fu-shoes_sample_colorize", '<Image>/Fus/Ruby-Fu/extendedSampleColorize/') 


