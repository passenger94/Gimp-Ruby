#!/usr/bin/env ruby

require "rubyfu"

include Gimp
include RubyFu

def apply_cool_metal_logo_effect(img, logo_layer, size, bg_color, gradient, gradient_reverse)
    feather = size/5
    smear = 7.5
    period = size/3
    amplitude = size/40
    shrink = 1 + size/30
    depth = size/20
    width = logo_layer.width
    height = logo_layer.height
    posx, posy = logo_layer.offsets.map {|x| x*-1}
    img_width = width + (0.15 * height) + 10
    img_height = (1.85 * height) + 10
    bg_layer = Layer.new(img, img_width, img_height, RGB_IMAGE, "Background", 100, NORMAL_MODE)
    shadow_layer = Layer.new(img, img_width, img_height, RGB_IMAGE, "Shadow", 100, NORMAL_MODE)
    reflect_layer = Layer.new(img, width, height, RGB_IMAGE, "Reflection", 100, NORMAL_MODE)
   
    Context.set_defaults
    Context.set_feather false
    Context.set_interpolation INTERPOLATION_NONE
    Context.set_transform_resize TRANSFORM_RESIZE_ADJUST
     
    Selection.none img
    img.resize(img_width, img_height, posx, posy)
    [bg_layer, reflect_layer, shadow_layer].each {|l| img.insert_layer(l, 0, 1)}
    logo_layer.set_lock_alpha true
    
    Context.set_background bg_color
    Edit.fill(bg_layer, FILL_BACKGROUND)
    reflect_layer.add_alpha
    Edit.clear reflect_layer
    Context.set_background Color(0,0,0)
    Edit.fill(shadow_layer, FILL_BACKGROUND)
   
    Context.set_gradient gradient
    
    Edit.blend(logo_layer, BLEND_CUSTOM, NORMAL_MODE, GRADIENT_LINEAR, 100, 0, 
        REPEAT_NONE, gradient_reverse, false, 0, 0, true, 0, 0, 0, height+5)
    
    img.select_rectangle(CHANNEL_OP_REPLACE, 0, (height/2 - feather), img_width, feather*2)
    plug_in_gauss_iir(img, logo_layer, smear, true, true)
    Selection.none img
    plug_in_ripple(img, logo_layer, period, amplitude, 1, 0, 1, true, false)
    logo_layer.translate(5, 5)
    logo_layer.resize(img_width, img_height, 5, 5)
    
    img.select_item(CHANNEL_OP_REPLACE, logo_layer)
    channel = Selection.save img
    Selection.shrink(img, shrink)
    Selection.invert img
    plug_in_gauss_rle(img, channel, feather, true, true)
    img.select_item(CHANNEL_OP_REPLACE, logo_layer)
    Selection.invert img
    Context.set_background Color(0,0,0)
    Edit.fill(channel, FILL_BACKGROUND)
    Selection.none img
    
    plug_in_bump_map(img, logo_layer, channel, 135.0, 45.0, depth, 0, 0, 0, 0, false, false, 0)
    
    shadow_layer.add_alpha
    img.select_item(CHANNEL_OP_REPLACE, logo_layer)
    fs = Selection.float(shadow_layer, 0, 0)
    Edit.clear(shadow_layer)
    fs.transform_perspective(height*0.15 + 5, height - height*0.15, 
                             width + height*0.15 + 5, height - height*0.15, 
                             5, height, 
                             width+5, height)
    gimp_floating_sel_anchor fs
    plug_in_gauss_rle(img, shadow_layer, smear, true, true)
    
    img.select_rectangle(CHANNEL_OP_REPLACE, 5, 5, width, height)
    Edit.copy logo_layer
    fs = Edit.paste(reflect_layer, false)
    gimp_floating_sel_anchor fs
    reflect_layer.transform_scale(0, 0, width, height*0.85)
    Context.set_transform_resize TRANSFORM_RESIZE_CLIP
    reflect_layer.transform_flip_simple(ORIENTATION_VERTICAL, true, 0)
    reflect_layer.set_offsets(5, height+3)
    
    layer_mask = reflect_layer.addMask ADD_MASK_WHITE
    Context.set_foreground Color(1.0,1.0,1.0)
    Context.set_background Color(0,0,0)
    Edit.blend(layer_mask, BLEND_FG_BG_RGB, NORMAL_MODE, GRADIENT_LINEAR, 100, 0, 
                REPEAT_NONE, false, false, 0, 0, true, 0, -height/2, 0, height)
    
    img.remove_channel channel
    img.set_active_layer logo_layer
    
end


register(
    :name       => "ruby-fu-cool-metal-logo",
    :blurb      => "Cool _Metal...",
    :help       => "Create a metallic logo with reflections and perspective shadows",
    :author     => "Spencer Kimball & Rob Malda & xy",
    :copyright  => "Spencer Kimball & Rob Malda",
    :date       => "2008",
    :menulabel  => "Cool Metal",
    :imagetypes => nil,
    :params     => [
        ParamDef.STRING("text", "Text", "Cool Metal"),
        ParamDef.SPINNER("size","Font size (pixels)", 100, (2..1000), 1),
        ParamDef.FONT("font", "Font", "Crillee"),
        ParamDef.COLOR("bg_color", "Background color", Color(1.0, 1.0, 1.0)),
        ParamDef.GRADIENT("gradient","Gradient", "Horizon 1"),
        ParamDef.TOGGLE("gradient_reverse", "Gradient reverse", 0)
        ],
    :results    => []
) do |run_mode, text, size, font, bg_color, gradient, gradient_reverse|
    include PDB::Access
    
    img = Image.new 256, 256, RGB
    #text_layer = gimp_text_fontname(img, -1, 0, 0, text, 0, true, size, PIXELS, font)
    text_layer = TextLayer.new(img, text, font, size, PIXELS)
    img.insert_layer(text_layer, 0, -1)
    text_layer.set_antialias true
    
    img.undo_disable do
      Context.push do
        apply_cool_metal_logo_effect(img, text_layer, size, bg_color, gradient, gradient_reverse)
      end
    end
    Display.new(img)
end

menu_register("ruby-fu-cool-metal-logo", "<Image>/File/Create/RubyFu")



register(
    :name       => "ruby-fu-cool-metal-logo-alpha",
    :blurb      => "Cool _Metal...",
    :help       => "Add a metallic effect to the selected region (or alpha) with reflections and perspective shadows",
    :author     => "Spencer Kimball & Rob Malda & xy",
    :copyright  => "Spencer Kimball & Rob Malda",
    :date       => "2008",
    :menulabel  => "Cool Metal",
    :imagetypes => "RGBA",
    :params     => [
        ParamDef.SPINNER("size","Effect size (pixels)", 100, (2..1000), 1),
        ParamDef.COLOR("bg_color", "Background color", Color(1.0, 1.0, 1.0)),
        ParamDef.GRADIENT("gradient","Gradient", "Horizon 1"),
        ParamDef.TOGGLE("gradient_reverse", "Gradient reverse", 0)
        ],
    :results    => []
) do |run_mode, img, logo_layer, size, bg_color, gradient, gradient_reverse|
    include PDB::Access
        
    if logo_layer.floating_sel?
        gimp_floating_sel_to_layer logo_layer
        logo_layer = img.get_active_layer
    end
    
    Context.push do
        img.undo_group_start do
            apply_cool_metal_logo_effect(img, logo_layer, size, bg_color, gradient, gradient_reverse)
        end
    end
    Display.flush
end

menu_register("ruby-fu-cool-metal-logo-alpha", "#{ExamplesMenu}/Alpha to Logo")
