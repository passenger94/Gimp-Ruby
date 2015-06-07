#! ruby
#
# Transposed to ruby april 2015 Gimp 2.9.1
# 
# Original work by J.D. Smith :
# 
# exposure-blend.scm: Blend 3 bracketed exposures.
# Copyright (C) 2006-2009 by J.D. Smith <jdtsmith _at gmail _dot com>
#
# Version 1.3c (Feb, 2009) for Gimp v2.6 and later
#
# http://tir.astro.utoledo.edu/jdsmith/exposure_blend.php
#
# Exposure Blend: Prompt for 3 images in a bracketed exposure series
# (e.g. 0,-2,+2 EV), and blend these into a contrast enhanced image,
# roughly based on the GIMP masking prescription of Daniel Schwen:
#
#   http://www.schwen.de/wiki/Exposure_blending.
#
# Also, provides an image alignment mode, layer overlap cropping, and
# several options for setting blend masks.  Smoothed masks are cached
# for quick recovery, and any of the three images can be used as a
# mask for any layer.
# 
# 
# Version 1.3c: - updated menu paths for new v2.6 menu layout, fixed
#                 Mask save/restore for Gimp >=v2.3.
# Version 1.3b: - Converted by Alan Stewart to work with the new
#                 TinyScheme scripting system of Gimp v2.3 and later.
# Version 1.3:  - Fixed accumulating shift mismatch issues with cached masks.
#               - New tattoo labelling scheme for cached masks.
#               - Added "edge protection" options using selective
#                 Gaussian blur.
# Version 1.2:  - First release into the wild
#
##############################################################################
#
# LICENSE
#
#  Copyright (C) 2006 J.D. Smith
#
#  exposure-blend is free software; you can redistribute it and/or
#  modify it under the terms of the GNU General Public License as
#  published by the Free Software Foundation; either version 2, or (at
#  your option) any later version.
#
#  exposure-blend is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#  General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with exposure-blend; see the file COPYING.  If not, write to
#  the Free Software Foundation, Inc., 51 Franklin Street, Fifth
#  Floor, Boston, MA 02110-1301, USA.
#
##############################################################################

require "rubyfu"

include Gimp
include RubyFu

# Tattoo constants
# Tattoo includes information on the image type (normal/bright/dark).
# Saved channels are tagged with a tattoo for quick retrieval as
# layer masks
EXP_IM_TYPE_MASK = 3
EXP_IM_TYPE_OFF = 17

EXP_BLUR_THRESHOLD_MASK = 3
EXP_BLUR_THRESHOLD_OFF = 19

EXP_BLUR_RAD_MASK = 1023
EXP_BLUR_RAD_OFF = 21

# Image Types values
# The loaded images are tagged with a tattoo of their image type.
EXP_OFFSET = (2**15).truncate
EXP_NORMAL = EXP_OFFSET + 0
EXP_DARK = EXP_OFFSET + 1
EXP_BRIGHT = EXP_OFFSET +  2


ebMessage = ""
BlurTypes = ["Gaussian/None", "Selective/Low", "Selective/Medium", "Selective/High"]
BrightMasks = { "Bright (inverted)" => EXP_BRIGHT, 
                "Normal (inverted)" => EXP_NORMAL, 
                "Dark (inverted)" => EXP_DARK}                
DarkMasks = {   "Dark" => EXP_DARK,
                "Normal" => EXP_NORMAL,
                "Bright" => EXP_BRIGHT}
Exposure_blend_name = Hash.new("Unknown").merge({EXP_NORMAL => "Normal Exp", 
                                                EXP_BRIGHT => "Bright Exp", 
                                                EXP_DARK => "Dark Exp"})
Blurtype = ["gauss", "edges low", "edges med", "edges high"]



# compose-tattoo -- create tattoo from image type, blur type,
#                   selective blur threshold, and blur radius
def exposure_blend_compose_tattoo(img_type, blur_rad, blur_thresh)
    (img_type - EXP_OFFSET) * (2**EXP_IM_TYPE_OFF).truncate +
     blur_thresh * (2**EXP_BLUR_THRESHOLD_OFF).truncate + 
     blur_rad * (2**EXP_BLUR_RAD_OFF).truncate
end

def exposure_blend_copy(from, to, offset=false)
    Edit.copy(from)
    floatdraw = Edit.paste(to, false)
    offs = from.offsets
    if offset and (offs.first != 0 or offs.last != 0)
        floatdraw.set_offsets(*offs)
    end
    gimp_floating_sel_anchor(floatdraw)
end

# mask -- Locate and return an appropriate mask from the mask cache,
#         or create and blur a new mask with given RADIUS TYPE
#         (e.g. EXP_NORMAL), and blur threshold (for selective
#         blurring). If REGEN is non-nil, regenerate the masks, even
#         if cached (useful if shifted).
def exposure_blend_mask(img, activeLayer, type, blur_rad, blur_thresh, regen)
    
    target_tattoo = exposure_blend_compose_tattoo(type, blur_rad, blur_thresh)
    source_layer = img.get_layer_by_tattoo(type)
    channel = *img.channelsOO.select {|ch| ch.get_tattoo == target_tattoo}
    
    # Do we have a layer mask already in place?
    mask = activeLayer.get_mask
    mask = activeLayer.addMask(ADD_MASK_WHITE) if mask.to_int == -1
    
    # Check for cached mask
    if channel.nil? or regen
        # We must create and store a new channel from the source layer
        img.remove_channel(channel) if !channel.nil?
        # Create a new channel for this combo
        channel = Channel.new(img, activeLayer.width, activeLayer.height,
            "#{Exposure_blend_name[type]} (#{blur_rad.to_s}pix #{Blurtype[blur_thresh]})",
            100, Color(0.0, 0.0, 0.0))
        
        # Copy the layer to a channel and mark with tattoo ID
        channel.set_visible(false)
        channel.set_tattoo(target_tattoo)
        img.insert_channel(channel, nil, -1)
        exposure_blend_copy(source_layer, channel)
        
        # Blur the channel image
        if blur_thresh == 0
            plug_in_gauss_iir(img, channel, blur_rad, true, true)
        else
            plug_in_sel_gauss(img, channel, blur_rad, [nil,100,30,10][blur_thresh])     
        end
        
    else # It's cached.
        ebMessage = "#{ebMessage}  #{gimp_item_get_name(channel)}\n"
    end
    
    # Copy the channel's data over
    exposure_blend_copy(channel, mask, false)
    mask
end


def exposure_blend_set_masks(img, blur_rad, blur_thresh, mask_dark, mask_bright,
                                dark_precedence, auto_trim, regen)
    
    dark_mask_type = DarkMasks[mask_dark]
    bright_mask_type = BrightMasks[mask_bright]
    # ...
    
    ebMessage = ""
    
    img.layersOO.each do |ly|
        tattoo = ly.get_tattoo
        dark = tattoo if tattoo == EXP_DARK 
        bright = tattoo if tattoo == EXP_BRIGHT
        
        if (dark or bright)
            #  Ensure appropriate layer is on top
            if (dark and dark_precedence) or (bright and !dark_precedence)
                img.raise_item_to_top(ly)
                img.set_active_layer(ly)
            end
            
            # Setup and blur the mask (or recover from channel cache)
            mask = exposure_blend_mask(img, ly, 
                                bright ? bright_mask_type : dark_mask_type, 
                                blur_rad, blur_thresh, regen)
           
           # Stretch the mask, if requested
           mask.levels_stretch if auto_trim
           # Invert the bright mask
           gimp_invert(mask) if bright
        end
    end
    message "Reused saved masks:\n#{ebMessage}" unless ebMessage.empty?
end              

RubyFu.register(
  :name       => "ruby-fu-exposure_blend",
  :blurb      => "exposures blending",
  :help       => "exposures blending",
  :author     => "J.D. Smith/xy",
  :copyright  => "J.D. Smith/xy",
  :date       => "june 2013",
  :menulabel  => "Exposures Blend ...",
  :imagetypes => nil,
  :params     => [
        ParamDef.FILE("img_f", "Normal Exposure", "normal.png"),
        ParamDef.FILE("img_dark_f", "Short Exposure (Dark)", "dark.png"),
        ParamDef.FILE("img_bright_f", "Long Exposure (Bright)", "bright.png"),
        ParamDef.TOGGLE("same_file", "using a single file ?", 0),
        ParamDef.SPINNER("blur_rad","Blend Mask Blur Radius", 8, 1..1024, 1),
        ParamDef.LIST("blur_thresh", "Blur Type/Edge Protection", BlurTypes),
        ParamDef.LIST("mask_dark", "Dark Mask Grayscale", ["Dark", "Normal", "Bright"]),
        ParamDef.LIST("mask_bright", "Bright Mask Grayscale", ["Bright (inverted)",
                                               "Normal (inverted)", "Dark (inverted)"]),
        ParamDef.TOGGLE("dark_precedence", "Highligths on top of Shadows", 0),
        ParamDef.TOGGLE("auto_trim", "Auto-Trim Mask Histograms", 0),
        #ParamDef.STRING("scale_image", "Scale Largest Image Dimension to", "")
  ],
  :results => [ParamDef.IMAGE('image', 'Image')] 

) do |run_mode, img_f, img_dark_f, img_bright_f, same_file, blur_rad, blur_thresh, mask_dark,
                            mask_bright, dark_precedence, auto_trim|#, scale_image|              
    include PDB::Access
    gimp_message_set_handler(ERROR_CONSOLE)
    
    # Gimp to ruby
    blur_thresh = BlurTypes.index(blur_thresh)
    dark_precedence = dark_precedence.to_bool
    auto_trim = auto_trim.to_bool
    same_file = same_file.to_bool
    
    if same_file
        img = gimp_file_load(img_f, img_f)
        # bug? in "gimp_file_load" --> no history avalaible, this at least get rid of the warning dialog
        gimp_progress_end
        
        img_dark = img_bright = img
    else
        img = gimp_file_load(img_f, img_f)
        img_dark = gimp_file_load(img_dark_f, img_dark_f)
        img_bright = gimp_file_load(img_bright_f, img_bright_f)
        gimp_progress_end
    end
    # bug? in "gimp_file_load" ## get history back
    img.undo_thaw
    
    layer = img.layersOO.first
    
    Context.push do
        img.undo_group_start do
            layer_bright = img.addLayer_from_drawable(img_bright.layersID.first, -1)
            layer_dark = img.addLayer_from_drawable(img_dark.layersID.first, dark_precedence ? 1 : -1)
            
            #layer.set_name("Normal Exp: #{img_f.split("/").last}")
            layer.set_name("#{img_f.split("/").last}")
            layer.set_tattoo(EXP_NORMAL)
            
            #layer_bright.set_name("Bright Exp: #{img_bright_f.split("/").last}")
            layer_bright.set_name("Shadows")
            layer_bright.set_tattoo(EXP_BRIGHT)
            layer_bright.add_alpha
            layer_bright.set_opacity(80)
            layer_bright.set_mode(SCREEN_MODE)
            
            #layer_dark.set_name("Dark Exp: #{img_dark_f.split("/").last}")
            layer_dark.set_name("Highlights")
            layer_dark.set_tattoo(EXP_DARK)
            layer_dark.add_alpha
            layer_dark.set_opacity(80)
            layer_dark.set_mode(MULTIPLY_MODE)
            
            [img_dark, img_bright].each {|i| gimp_image_delete(i)} unless same_file
            
            ## Scale layers
            # not implemented
            
            exposure_blend_set_masks(img, blur_rad, blur_thresh, mask_dark, 
                                mask_bright, dark_precedence, auto_trim, false)
            
            Display.new(img)
        end # undo_group
    end # Context

end

RubyFu.menu_register("ruby-fu-exposure_blend", RubyFu::RubyFuToolbox)



### Align exposures layers
###
def exposure_blend_align(img, align_set)
    include PDB::Access
    
    Context.push do
        img.undo_group_start do
            
            img.layersOO.each do |layer|
                tattoo = layer.get_tattoo
                dark = tattoo if tattoo == EXP_DARK 
                bright = tattoo if tattoo == EXP_BRIGHT
                
                do_align = ((dark and align_set == 'dark') or (bright and align_set == 'bright')) ? true : false
                
                layer.set_visible( (align_set == 'off' or tattoo == EXP_NORMAL or do_align) ? true : false )
                
                layer.set_linked(false) #default
                
                if (dark or bright)
                    
                    if do_align
                        Shelf[layer.to_int.to_s] = [layer.get_opacity, layer.get_mode]
                        layer.set_mode(DIFFERENCE_MODE) 
                        layer.set_apply_mask(false)
                        layer.set_opacity(100)
                        layer.set_linked(true)
                        layer.set_edit_mask(false)
                        img.set_active_layer(layer)
                    else #  align_set == 'off'
                        if Shelf[layer.to_int.to_s] and align_set == 'off'
                            opacity, mode = Shelf[layer.to_int.to_s]
                            layer.set_opacity(opacity)
                            layer.set_mode(mode)
                        end
                        layer.set_apply_mask(true)
                    end
                end
            end
            exposure_blend_link_channels(img, align_set)
            message("Select Move Tool. Use arrow keys for 1 pixel movements.") unless align_set == 'off'
        end
    end
    Display.flush
end

def exposure_blend_link_channels(img, type)
    img.channelsOO.each do |ch|
        tattoo = ch.get_tattoo
        mask_type = exposure_blend_decompose_tattoo(tattoo)
        ch.set_linked( ((type == 'bright' and mask_type == EXP_BRIGHT) or 
                        (type == 'dark' and mask_type == EXP_DARK)) ? true : false )
    end
end

def bit_mask(value, offset, mask)
    value.divmod((2**offset).truncate)[0].divmod(mask+1)[1]
end

def exposure_blend_decompose_tattoo(tattoo)
   #im type
   EXP_OFFSET + (bit_mask(tattoo, EXP_IM_TYPE_OFF, EXP_IM_TYPE_MASK))
##   # blur_rad
##   bit_mask(tattoo, EXP_BLUR_RAD_OFF, EXP_BLUR_RAD_MASK),
##   # selective blur thresh
##   bit-mask(tattoo, EXP_BLUR_THRESHOLD_OFF, EXP_BLUR_THRESHOLD_MASK)
end


["dark", "bright", "off"].each do |alignvar|
    RubyFu.register(
      :name       => "ruby-fu-exposure-blend-align-#{alignvar}",
      :blurb      => "Aligning #{alignvar} Exposure",
      :help       => "Aligning #{alignvar} Exposure",
      :author     => "J.D. Smith/xy",
      :copyright  => "J.D. Smith/xy",
      :date       => "june 2013",
      :menulabel  => alignvar,
      :imagetypes => "*",
      :params     => [],
      :results    => []
    ) do |run_mode, image, drw|
        exposure_blend_align(image, alignvar)
    end
    
    RubyFu.menu_register("ruby-fu-exposure-blend-align-#{alignvar}", 
                        "<Image>/Filters/RubyFu Exposure Blend/Align Exposures/")
end



### Crop Exposure layers
###
RubyFu.register(
      :name       => "ruby-fu-exposure-blend-crop-image",
      :blurb      => "Trim image to combined layer overlap",
      :help       => "Trim image to combined layer overlap",
      :author     => "J.D. Smith/xy",
      :copyright  => "J.D. Smith/xy",
      :date       => "june 2013",
      :menulabel  => "Trim Image to Overlap Area",
      :imagetypes => "*",
      :params     => [],
      :results    => []

) do |run_mode, img, drw|
    include PDB::Access
    
    Context.push do
        img.undo_group_start do
            x = y = xt = yt = x2 = y2 = nil
            img.layersOO.each do |layer|
                offs = layer.offsets
                x = !x.nil? ? [x, offs[0]].max : offs[0]
                y = !y.nil? ? [y, offs[1]].max : offs[1]
                xt = (layer.width + offs[0]) - 1
                yt = (layer.height + offs[1]) - 1
                x2 = !x2.nil? ? [x2, xt].min : xt
                y2 = !y2.nil? ? [y2, yt].min : yt
            end
            
            img.crop( (x2-x)+1, (y2-y)+1, x, y )
            message("Trimmed image to: #{(x2-x)+1} x #{(y2-y)+1} [#{x}, #{y}]")
            
        end
    end
    Display.flush
end

RubyFu.menu_register("ruby-fu-exposure-blend-crop-image", "<Image>/Filters/RubyFu Exposure Blend/")


