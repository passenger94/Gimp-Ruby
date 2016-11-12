# GIMP-Ruby -- Allows GIMP plugins to be written in Ruby.
# Copyright (C) 2006  Scott Lembcke
# 
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor,Boston, MA
# 02110-1301, USA.

require 'gimp_oo.rb'

module Gimp
    blacklist = [
        'delete',
        'get_linked',
        'get_name',
        'get_tattoo',
        'get_visible',
        'get_image',
        'set_linked',
        'set_name',
        'set_tattoo',
        'set_visible',
        'set_image',
        'mask',  # deprecated for 'get_mask'
        'group?',    # delegate to Item (through Drawable)
        'text_layer?'
    ]
    
    Layer = GimpOO::ClassTemplate.build('gimp-layer-', blacklist,  nil, [], Gimp::Drawable)
    
    
    # There is no "text layer" Type in C 
    # extending Layer with TextLayer module features 
    module TextLayer
        
        def new(*var)
            PDB.gimp_text_layer_new(*var) 
        end
        module_function :new
        
        prefix = 'gimp-text-layer-'

        PDB['gimp-procedural-db-query'].call(prefix, *(['']*6))[1].each do |proc_name|
            method_name = proc_name[prefix.length..-1].gsub('-','_')
            
            next if ['new',         # clash with Layer.new, made avalaible as TextLayer.new
                     'resize',      # clash with Layer#resize, use gimp_text_layer_resize
                     'get_hinting'  # deprecated for 'get_hint_style'
                     # 'set_hinting' ?? not deprecated ?
            ].include? method_name
            
            self.module_eval """
                def #{method_name}(*args)
                    PDB['#{proc_name}'].call(self, *args)
                end
            """
        end
    end
    
    
    class Layer
        
        def initialize(id)
            super
            
            if PDB.gimp_item_is_text_layer(self)
                # adding text layer methods only to this Layer instance
                self.extend TextLayer
            end
        end
        
        def addMask(addMaskType)
            themask = PDB.gimp_layer_create_mask(self, addMaskType)
            PDB.gimp_layer_add_mask(self, themask)
            themask
        end
        
        def floating_sel?
            PDB.gimp_layer_is_floating_sel(self) == 1
        end
        
        def mergeDown(mergeType=CLIP_TO_IMAGE)
            PDB.gimp_image_merge_down(PDB.gimp_item_get_image(self), self, mergeType)
        end
        
        def resize(*args)
            if args.size == 4
                PDB.gimp_layer_resize(self, *args)
            elsif args.size == 2 && PDB.gimp_item_is_text_layer(self)
                PDB.gimp_text_layer_resize(self, *args)
            end
        end
        
    end
    
end


