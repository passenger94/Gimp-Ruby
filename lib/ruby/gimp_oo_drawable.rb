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
    'bytes',                # deprecated for 'bpp'
    'get_image',               # deprecated for Item equivalent methods
    'set_image',               #
    'get_name',                #
    'set_name',                #
    'get_visible',             #
    'set_visible',             #
    'get_tattoo',              #
    'set_tattoo',              #
    'get_linked',              #
    'set_linked',              #
    'is_layer',                #
    'is_channel',              #
    'is_text_layer',           #
    'is_valid',                #
    'is_layer_mask',           #
    'delete',                  #
    'transform_2d',            #
    'transform_flip',          #
    'transform_flip_simple',   #
    'transform_matrix',        #
    'transform_perspective',   #
    'transform_rotate',        #
    'transform_rotate_simple', #
    'transform_scale',         #
    'transform_shear',         #
    'parasite_attach',               # deprecated for Item methods (other method name)
    'parasite_detach',               #
    'parasite_find',                 #
    'parasite_list',                 #
    'transform_2d_default',          #
    'transform_flip_default',        #
    'transform_matrix_default',      #
    'transform_perspective_default', #
    'transform_rotate_default',      #
    'transform_scale_default',       #
    'transform_shear_default',       #
    'layer_mask?',      # delegate to Item
    'text_layer?',      #
    'layer?',           #
    'channel?',         #
    'valid?',           #
    'group?'            # comming from 'gimp-layer'
  ]
  
  Drawable = GimpOO::ClassTemplate.template('gimp-drawable-', blacklist, nil, [], Gimp::Item)
  
    class Drawable
        
        def rgb?
            PDB.gimp_drawable_is_rgb(self) == 1
        end
        
        def gray?
            PDB.gimp_drawable_is_gray(self) == 1
        end
        
        def indexed?
            PDB.gimp_drawable_is_indexed(self) == 1
        end
                
    end
end
