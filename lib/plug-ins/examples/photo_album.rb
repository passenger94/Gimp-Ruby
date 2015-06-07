#!/usr/bin/env ruby

require "rubyfu"

include Gimp
include RubyFu

RubyFu.register(
    :name       => "ruby-fu-photo-album",
    :blurb      => "Creates a photo album image",
    :help       => "Creates an album image for printing from 6 photos of the 1024x768 size",
    :author     => "shackon / xy",
    :copyright  => "Copyright (c) 2001 shackon / xy",
    :date       => "2001 / 2008",
    :menulabel  => "Album image", #menulabel
    :imagetypes => "",
    :params     => [
        ParamDef.SPINNER("xsize","X size of new image", 2100, (2..2100), 1),
        ParamDef.SPINNER("ysize","Y size of new image", 2600, (2..2950), 1),
        ParamDef.FILE("p1", "Photo 1", ""),
        ParamDef.FILE("p2", "Photo 2", ""),
        ParamDef.FILE("p3", "Photo 3", ""),
        ParamDef.FILE("p4", "Photo 4", ""),
        ParamDef.FILE("p5", "Photo 5", ""),
        ParamDef.FILE("p6", "Photo 6", ""),
        ParamDef.COLOR("bgcolor", "Background color of image", Color(255, 255, 255)),
        ParamDef.TOGGLE("shadow", "Make shadow", 0),
        ParamDef.COLOR("shadowcolor", "Shadow color of image", Color(64, 64, 64))
                ],
    :results    => [] #results
    
) do |run_mode, xsize, ysize, p1, p2, p3, p4, p5, p6, bgcolor, shadow, shadowcolor|
    include PDB::Access

    Context.push do
        img = Image.new(xsize, ysize, RGB)
        
        img.undo_group_start do
            
            bglayer = img.addLayer(xsize, ysize, RGB, "Background", 100, NORMAL_MODE, 1)
            
            Context.set_background(bgcolor)
            Edit.fill(bglayer, FILL_BACKGROUND)
            
            Display.new(img)
            
            drawable = img.get_active_drawable
            
            photos = [ p1, p2, p3, p4, p5, p6 ]
            pos = [
                { :x => 0,    :y => 0 },
                { :x => 1050, :y => 0 },
                { :x => 0,    :y => 900 },
                { :x => 1050, :y => 900 },
                { :x => 0,    :y => 1800 },
                { :x => 1050, :y => 1800 },
            ]
            
            photos = photos.reject { |p| p.empty? }
            
            if shadow == 1
                Context.set_foreground(shadowcolor)
                (0...(photos.size)).each do |i|
                    img.select_rectangle(CHANNEL_OP_ADD, pos[i][:x]+20, pos[i][:y]+20, 1024, 768)
                end
                Edit.bucket_fill(drawable, 0, 0, 100, 0, 0, 0, 0)
                Selection.none(img)
            end
            
            (0...(photos.size)).each do |i|
                img_tmp = gimp_file_load(photos[i],File.basename(photos[i]))
                Selection.all(img_tmp)
                Edit.copy(img_tmp.get_active_drawable)
                float = Edit.paste(drawable, 1)
                float.set_offsets(pos[i][:x],pos[i][:y])
                gimp_floating_sel_anchor(float)
                img_tmp.delete
            end
            
        end
    end
    Display.flush
end

RubyFu.menu_register("ruby-fu-photo-album", "<Image>/File/Create/RubyFu")

