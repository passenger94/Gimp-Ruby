
class ImageDrawable # TODO make it a module and extend ?
  attr_reader :nbr_images, :drw, :img, :layer_names
  
  def initialize
    #include Gimp
    #include RubyFu
    @nbr_images, @image_ids = Image.list
    @img = fetch_image
  end

  def imgdrw 
    @imID = @image_ids[0]
    @drw = gimp_image_get_active_drawable(@imID)
    @img = gimp_drawable_get_image(@drw)    
    [@img, @drw]
  end
  
  def get_image_by_name(name)
    @img, @drw, @imID = @image_ids.each_with_object([]) do |id, obj|
      d = gimp_image_get_active_drawable(id)
      i = gimp_drawable_get_image(d)
      obj << i << d << id if gimp_image_get_name(i).match(name)
    end
    @img
  end
  
  def fetch_image(position = 0)
    Image.create(@image_ids[position])
  end
  
  def get_layers
      layers = gimp_image_get_layers(@img)[1].map {|l| Layer.create(l)}.reverse
      @layer_names = layers.each_with_object("") { |x, obj| 
                    obj << "@layer#{layers.index(x)}, " }[0..-3]
      layers
  end

end

@imdr = ImageDrawable.new
@image = @imdr.img
@layers = @imdr.get_layers
@layers.size.times { |i| instance_variable_set("@layer#{i}", @layers[i]) }

puts "#     @image is the first image in the stack (last opened)\r" + 
     "#     @layers are layers from that image (bottom to top) :\r" +
     "#     \t\t#{@imdr.layer_names}"


