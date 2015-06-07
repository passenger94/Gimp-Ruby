
require File.expand_path("shoesfu.rb", File.dirname(__FILE__))
include ShoesFu

Shoes.app :width => 430, :height => 400, :title => "New Guides" do
	
    image_name, image_width, image_height = gimp_says
	
	@guides = []
	
	para "image : #{image_name}	 #{image_width} x #{image_height}", :align => "center"
	
	stack :margin => [0,0,0,0] do
		flow(:margin => [30,0,0,0]) { @remove_guides = check checked: false; para "remove old guides if any ?" }
		
		flow :margin => [30,0,0,0] do
		    para "predefined : "
		    predefs = ["default", "thirds", "golden sections", "center"]
		    list_box :items => predefs, :width => 200 do |list|
		       
		        # don't trigger the click event on @h and @v radio buttons while processing change event here
		        freeze_hv_events do
                    case list.text
                    when "thirds"
                        [@hguides, @vguides].each do |slot|
                            clear_add_guides(slot, 2)
                            slot.contents[3].contents[2].text = "33.33"
                            slot.contents[4].contents[2].text = "66.66"
                        end
                        @percent.checked = true
                        
                    when "golden sections"
                        [@hguides, @vguides].each do |slot|
                            clear_add_guides(slot, 2)
                            dim = slot == @hguides ? image_height : image_width
                            slot.contents[3].contents[2].text = (dim - (dim / 1.618)).to_i.to_s
                            slot.contents[4].contents[2].text = (dim / 1.618).to_i.to_s
                        end
                        @pixel.checked = true
                        
                    when "center"
                        [@hguides, @vguides].each do |slot|
                            clear_add_guides(slot)
                            slot.contents[3].contents[2].text = "50.0"
                        end
                        @percent.checked = true
                        
                    when "default"
                        [@hguides, @vguides].each { |slot| clear_add_guides(slot) }
                        @pixel.checked = true
                    end
                    
                    [@h, @v].each {|c| c.checked = true}
                end # freeze_hv_events
		    end
		end
		
	    flow :margin => [30,0,0,0] do
			@pixel = radio :checked => true, :click => proc {|r| px_or_perc(r)}
			 para "pixel"
			
			@percent = radio :margin_left => 20, :click => proc {|r| px_or_perc(r)}
			para "percent"
		end
		
		flow :margin => gutter do
			@hguides = stack :width => 0.5 do;end
			@vguides = stack :width => 0.5 do;end
			
			[@hguides, @vguides].each do |slot|
			    slot.append {
			        border white, :curve => 15, :strokewidth => 2
			        flow do
			            chk = app.instance_variable_set(slot == @hguides ? :@h : :@v , 
			                                              check(:checked => true, :margin_left => 30))
			            para "vertical", :align => "center"
			            
			            chk.click do |c| 
                            if c.checked?
                                add_guideline(slot) #if @vguides.contents.length == 3
                            else
                                clear_add_guides(slot, 0) 
                            end unless @hv_radio_disabled
                        end
			        end
                    
			        flow :margin => [10,0,10,10] do
                        button("add") {add_guideline(slot)}
                        button("del") {del_guideline(slot)}
                    end
			    }
			end
			
		end
	end
    
	flow :margin => 10 do
		
	    button "ok", :right => 30 do
			resu = @guides.inject([[], []]) do |r,g|
				if @h.checked? and g[1] == @hguides
				    val = @pixel.checked? ? g[0].contents[2].text.to_i : g[0].contents[2].text.to_f
				    r[0] << val
				elsif @v.checked? and g[1] == @vguides
				    val = @pixel.checked? ? g[0].contents[2].text.to_i : g[0].contents[2].text.to_f
					r[1] << val
				end
				r
			end
			resu[0] = [0] if !@h.checked?
			resu[1] = [0] if !@v.checked?
			resu[2] = @remove_guides.checked?
			
			tell_gimp resu.to_json
			
			exit
		end
		
		button "cancel", :right => 100 do
			tell_gimp "cancelled"
			exit
		end
	end
	
	
	def px_or_perc(rad)
		@guides.each do |g|
			g[0].contents[3].replace(rad == @pixel ? "px" : "%" )
		end
	end
	
	def freeze_hv_events(&block)
	    @hv_radio_disabled = true
	    yield block if block_given?
	    @hv_radio_disabled = false
	end

	def add_guideline(slot)
		
        slot.append do
            @guide = flow :margin => [15,0,15,2] do
                background silver, :curve => 15
                para "guide at ", :margin_top => 8
                edit_line :width => 75, :margin_top => 5
                para( ( @pixel.checked? ? "px" : "%"), :margin_top => 8 )
            end
        end
		
		@guides << [@guide, slot]
		
		freeze_hv_events do
		    chk = slot.contents[1].contents[0]
		    chk.checked = true unless chk.checked?
		end
		
	end
	
	def del_guideline(slot)
		g = slot.contents.last
		unless slot.contents.length == 3
			g.remove
			@guides.reject! {|x| x[0] == g}
			
			chk = slot.contents[1].contents[0]
			chk.checked = false if slot.contents.length == 3
		end
	end
		
	def clear_add_guides(slot, nbr = 1)
	    (slot.contents.length - 3).times { del_guideline(slot) }
	    nbr.times { add_guideline(slot) }
	end
	
end

