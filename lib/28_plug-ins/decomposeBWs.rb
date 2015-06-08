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
            
            image_copy = image.duplicate
            drw_copy = image_copy.layersOO[0]
            
            rvb_image =  plug_in_decompose(image_copy, drw_copy, "RGB", true)[0]
            r_layer, g_layer, b_layer = rvb_image.layersOO
            
            cmy_image = plug_in_decompose(image_copy, drw_copy, "CMY", true)[0]
            c_layer, m_layer, y_layer = cmy_image.layersOO
            
            k_layer = plug_in_decompose(image_copy, drw_copy, "CMYK", true)[0].layersOO[3]
            
            y470_layer = plug_in_decompose(image_copy, drw_copy, "YCbCr ITU R470 256", true)[0].layersOO[0]
            #y709_layer = plug_in_decompose(image_copy, drw_copy, "YCbCr ITU R709 256", true)[0].layersOO[0]
            
            v_layer = plug_in_decompose(image_copy, drw_copy, "Value", true)[0].layersOO[0]
            
            lightness_layer = plug_in_decompose(image_copy, drw_copy, "Lightness", true)[0].layersOO[0]
            
            lab_layer = plug_in_decompose(image_copy, drw_copy, "LAB", true)[0].layersOO[0]
            
            l = image_copy.addLayer_from_drawable(b_layer)
            l = image_copy.addLayer_from_drawable(g_layer)
            l = image_copy.addLayer_from_drawable(r_layer)
            
            l = image_copy.addLayer_from_drawable(y_layer)
            gimp_invert(l)
            l = image_copy.addLayer_from_drawable(m_layer)
            gimp_invert(l)
            l = image_copy.addLayer_from_drawable(c_layer)
            gimp_invert(l)
            
            l = image_copy.addLayer_from_drawable(k_layer)
            gimp_invert(l)
            l = image_copy.addLayer_from_drawable(y470_layer)
            l.set_name("luma-y470")
            #l = image_copy.addLayer_from_drawable(y709_layer)
            #l.set_name("luma-y709")
            l = image_copy.addLayer_from_drawable(v_layer)
            l.set_name("value")
            l = image_copy.addLayer_from_drawable(lightness_layer)
            l.set_name("HSL_lightness")
            l = image_copy.addLayer_from_drawable(lab_layer)
            l.set_name("Lab_L")
            
            Image.list.last[0...-2].each { |i| gimp_image_delete(i) }
            image_copy.remove_layer(drw_copy)
            
            Display.new(image_copy)
            
        end # undo_group
    end # Context
    
end

RubyFu.menu_register('ruby-fu-decompose_bws', '<Image>/Fus/Ruby-Fu/')
