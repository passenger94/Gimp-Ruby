#!ruby

require "rubyfu"

include Gimp
include RubyFu


RubyFu.register(
    :name       => "ruby-fu-transp_object",
    :blurb      => "create transparent object out of a shape in a layer",
    :help       => "create transparent object out of a shape in a layer",
    :author     => "xy",
    :copyright  => "xy",
    :date       => "2013",
    :menulabel   => "transparent object",
    :imagetypes => "RGBA",
    :params     => [
        ParamDef.COLOR('col', 'object color', Color(0.5,0.5,0.5)),
        ParamDef.SPINNER("depth", "glass depth", 4, (0..100), 1),	
        ParamDef.SPINNER("translucency", "glass translucency", 64, (0..255), 1),
        ParamDef.COLOR('sh_col', 'shadow color', Color(0.0,0.0,0.0)),
        ParamDef.SPINNER("sh_offx", "shadow offset X", 12, (-50..50), 1),
        ParamDef.SPINNER("sh_offy", "shadow offset Y", 12, (-50..50), 1),
        ParamDef.TOGGLE("linked", "link layers", 1)
    ],
    :results    => []
    
) do |run_mode, image, drawable, col, depth, translucency, sh_col, sh_offx, sh_offy, linked|
    include PDB::Access
    
    Context.push do
        image.undo_group_start do
            orig = image.get_active_layer
            
            bump = image.addLayer_from_drawable(drawable, image.get_item_position(orig)+1)
            bump.set_name("bump")
            bump.set_visible(false)
            Context.set_foreground(Color(1.0,1.0,1.0))
            image.select_item(CHANNEL_OP_REPLACE, bump)
            Edit.bucket_fill(bump, FG_BUCKET_FILL, NORMAL_MODE, 100, 0, false, 0, 0)
            
            #col.rgba_set((col.r - 1).abs, (col.g - 1).abs, (col.b - 1).abs, 1)
            Context.set_foreground(col.subtract(Color(1,1,1))* -1)
            Edit.bucket_fill(drawable, FG_BUCKET_FILL, NORMAL_MODE, 100, 0, false, 0, 0)
            Selection.none(image)
            
            plug_in_gauss(image, drawable, 5.0, 5.0, 1)
            plug_in_bump_map(image, drawable, bump, 300.0, 45.0, depth, 0, 0, 0, 0, true, false, 0) #LINEAR, no Constant in PDB !
            
            image.select_item(CHANNEL_OP_REPLACE, drawable)
            Selection.shrink(image, depth)
            Selection.feather(image, depth-1)
            gimp_curves_spline(drawable, HISTOGRAM_ALPHA, 4, [0, 0, 255, translucency].join)
            object = image.addLayer_from_drawable(drawable)
            object.set_name("object")
            
            Edit.clear(drawable)
            image.select_item(CHANNEL_OP_REPLACE, drawable)
            Context.set_foreground(sh_col)
            Edit.bucket_fill(drawable, FG_BUCKET_FILL, NORMAL_MODE, 100, 0, false, 0, 0)
            drawable.set_name("shadow")
            
            Selection.none(image)
            gimp_invert(object)
            
            plug_in_gauss(image, drawable, 10.0, 10.0, 1)
            orig.resize_to_image_size
            orig.offset(false, 1, sh_offx, sh_offy)
            orig.set_mode(MULTIPLY_MODE)
            orig.set_opacity(80)
            
            [object, bump, orig].each {|l| l.set_linked(true)} if linked.to_bool
            
        end # undo_group
    end # Context
    gimp_progress_end
    Display.flush
end

RubyFu.menu_register("ruby-fu-transp_object", "<Image>/Fus/Ruby-Fu/")

