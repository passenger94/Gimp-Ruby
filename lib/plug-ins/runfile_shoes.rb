#!ruby

require 'rubyfu'

include Gimp
include RubyFu

module RubyFu
  class Procedure
    attr_accessor :type
  end

  def self.test_proc(procname, drawable)
    proc = @@procedures[procname]
    
    case proc.type
    when :toolbox
      proc.run(Param.INT32(RUN_INTERACTIVE))
    when :image
      proc.run(Param.INT32(RUN_INTERACTIVE),
							 Param.IMAGE(PDB.gimp_item_get_image(drawable)),
							 Param.DRAWABLE(drawable))
    else
      args = RubyFu.dialog("Testing #{procname}", procname, proc.fullparams)
      proc.run(*args)
    end
  end
end

require File.expand_path("shoesfu.rb", File.dirname(__FILE__))
include ShoesFu

RubyFu.register(
	:name       => 'ruby-fu-run-file-shoes',
	:blurb      => 'run a plugin',
	:help       => 'run a plugin without installing it',
	:author     => 'xy',
	:copyright  => 'xy',
	:date       => '2016',
	:menulabel  => 'run File (Shoes)',
	:imagetypes => nil,
	:params     =>  [],
	:results    =>  []

) do |run_mode|
	include PDB::Access
	gimp_message_set_handler(ERROR_CONSOLE)
    
	def get_drawables
		nbr_images, image_ids = Image.list
		return {"Empty" => nil} if nbr_images == 0
		
		image_ids.each_with_object({}) do |im, obj|
			Image.create(im).layersID.each { |ly| obj[Layer.create(ly).get_name] = ly }
		end
	end
	
	Context.push do
		drawables = get_drawables
		ret = go_steppin("runfile_shoesgui.rb", drawables.keys.to_json)
		
		unless ret.first == "cancelled"
			filename, procname, drw = JSON.parse(ret[0])
			drawable = drw == "Empty" ? nil : Drawable.create(drawables[drw].to_i)
			Shelf["ruby-fu-last-run-file"] = [filename, procname, drawable]
			
			load(filename)
			RubyFu.test_proc(procname, drawable)
		end
	end
    
end

RubyFu.menu_register('ruby-fu-run-file-shoes', RubyFu::RubyFuToolbox)

register(
  :name       => "ruby-fu-rerun-file-shoes",
  :blurb      => _("Reruns the last file ran using Runfile"),
  :help       => nil,
  :author     => "xy",
  :copyright  => "xy",
  :date       => "2016",
  :menulabel  => "Run_again File (Shoes)",
  :imagetypes => nil,
  :params     => [],
  :results    => []
  
) do |run_mode|
  last = Shelf["ruby-fu-last-run-file"]
  
  if last
    load(last.shift)
		RubyFu.test_proc(*last)
  else
    Gimp.message _("No previous file to run")
  end
end

menu_register("ruby-fu-rerun-file-shoes", RubyFu::RubyFuToolbox)

