#!ruby

require 'rubyfu'

include Gimp
include RubyFu

RubyFu.register(
    :name       => 'ruby-fu-decompose_bws',
    :blurb      => 'some Black and Whites',
    :help       => 'some Black and Whites',
    :author     => 'xy',
    :copyright  => 'xy',
    :date       => '2013',
    :menulabel   => 'decompose choices',
    :imagetypes => '*',
    :params     => [],
    :results    => []
    
) do |run_mode, image, drawable|
    include PDB::Access
    
    
    Context.push do
        image.undo_group_start do
            
            greys_image =  plug_in_decompose(image, drawable, "RGB", true)[0]
            r_layer, g_layer, b_layer = greys_image.layersOO
            greys_image.set_active_layer(r_layer)
            
            cmy_image = plug_in_decompose(image, drawable, "CMY", true)[0]
            c_layer, m_layer, y_layer = cmy_image.layersOO
            gimp_invert(greys_image.addLayer_from_drawable(y_layer))
            gimp_invert(greys_image.addLayer_from_drawable(m_layer))
            gimp_invert(greys_image.addLayer_from_drawable(c_layer))
            cmy_image.delete              
            
            cmyk_image = plug_in_decompose(image, drawable, "CMYK", true)[0]
            gimp_invert( greys_image.addLayer_from_drawable(cmyk_image.layersOO[3]) )
            cmyk_image.delete
            
            y470_image = plug_in_decompose(image, drawable, "YCbCr_ITU_R470_256", true)[0]
            l = greys_image.addLayer_from_drawable(y470_image.layersOO[0])
            l.set_name("luma-y470")
            y470_image.delete
            
            #y709_image = plug_in_decompose(image, drawable, "YCbCr ITU R709 256", true)[0]
            #l = greys_image.addLayer_from_drawable(y709_image.layersOO[0])
            #l.set_name("luma-y709")
            #y709_image.delete
            
            v_image = plug_in_decompose(image, drawable, "Value", true)[0]
            l = greys_image.addLayer_from_drawable(v_image.layersOO[0])
            l.set_name("value")
            v_image.delete
            
            lightness_image = plug_in_decompose(image, drawable, "Lightness", true)[0]
            l = greys_image.addLayer_from_drawable(lightness_image.layersOO[0])
            l.set_name("HSL_lightness")
            lightness_image.delete
            
            lab_image = plug_in_decompose(image, drawable, "LAB", true)[0]
            l = greys_image.addLayer_from_drawable(lab_image.layersOO[0])
            l.set_name("Lab_L")
            lab_image.delete
            
            Display.new(greys_image)
            
        end # undo_group
    end # Context

end

RubyFu.menu_register('ruby-fu-decompose_bws', '<Image>/Fus/Ruby-Fu/')

