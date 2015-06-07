

require 'json/ext'
require 'open3'

GIMP_PLUGIN_DIR = File.dirname(__FILE__)

module ShoesFu
    
SHOES = '/home/xy/NBWorkspace/shoes3/dist/shoes'

	def go_steppin(gui, args)
		
	    @result = []
		
		Open3.popen3("#{SHOES} #{File.join(GIMP_PLUGIN_DIR, gui)}") do |stdin, stdout, stderr|
			stdin.sync = stdout.sync = stderr.sync = true
			
			#sending to shoes
			stdin.puts(args)
			
			# receiving from shoes
			stdout.each do |line|
				
			    r = line.chomp
			    #message "line.chomp = #{r}"
                
                # we're done
                return @result = [r] if r == "cancelled"
                
                # waiting for a reply
                if /askgimp(.*)/ =~ r
                    
                    elem = JSON.parse($1)
                    
                    obj, met = elem["meth"].split(".")
                    
                    if elem["args"].size > 1
                        if elem["args"][0].is_a? String and /rgb\((.*)\)/ =~ elem["args"][0] # String to Color
                            retmethods = Gimp.const_get(obj).send(met.to_sym, Color(*$1.split(",").map! {|x|x.to_f/255}))
                        else
                            retmethods = Gimp.const_get(obj).send(met.to_sym, *elem["args"])
                        end
                    else
                        if elem["args"].empty? || elem["args"][0].nil?
                            retmethods = Gimp.const_get(obj).send(met.to_sym)
                        else
                            retmethods = Gimp.const_get(obj).send(met.to_sym, elem["args"].pop)
                        end
                    end
                    
                    # reply to shoes
                    retmethods.is_a?(Array) ? stdin.puts(retmethods.to_json) : stdin.puts([retmethods].to_json)
                    
                    @result << retmethods.to_json
                    
                # tell gimp    
                else                                  
                    @result << r
                end
                
			end # stdout.each
		end # open3
		
		return @result
		
	end
	module_function :go_steppin
	
	
	def gimp_says
		JSON.parse($stdin.gets.chomp)
	end
	
	def ask_gimp(metod, *args)
		$stdout.puts "askgimp" + { :meth => metod, :args => args }.to_json
		$stdout.flush
		r = JSON.parse($stdin.gets)
		r.respond_to?(:chomp) ? r.chomp : r
	end
	
	def tell_gimp(mess)
		$stdout.puts mess
		$stdout.flush
	end
	module_function :gimp_says, :ask_gimp, :tell_gimp
	
end
