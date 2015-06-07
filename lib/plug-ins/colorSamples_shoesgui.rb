
dir = File.dirname(__FILE__)
require File.expand_path("shoesfu.rb", dir)
include ShoesFu

SAMPLESDIR = File.expand_path("#{dir}/../ruby_static")

Shoes.app :width => 400, :height => 700, :title => "Sample Colors" do
    
    img, drw, samples = gimp_says
    current_sample = ""
    
	background black
    stack :margin_left => 10 do
        stack :margin_top => 40 do
			samples.each do |k,v|
				stack :margin_bottom => 10 do
					inscription k, :margin_bottom => 2, :stroke => white
					image "#{SAMPLESDIR}/#{v[1]}", :width => "95%",
						:click => proc{ current_sample = v[0]; ask_gimp("PDB.ruby-fu-sample_colorize_#{v[0]}", img, drw) }
				end
			end
        end
        
        @buttons_slot = flow :left => 0, :top => 0, :margin => [150,2,0,0], :attach => Shoes::Window do 
             button "Annuler" do
                tell_gimp "cancelled"
                exit
            end           
            button "Valider", :right => 10 do
                tell_gimp current_sample
                exit
            end
        end
    end                                                                                    
    
end

