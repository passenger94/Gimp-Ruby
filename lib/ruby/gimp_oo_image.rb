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
    'active_drawable',
    'add_layer_mask',
    'remove_layer_mask',
    'add_layer',
    'add_channel',
    'add_vectors',
    'get_layer_position',
    'get_channel_position',
    'get_vectors_position',
    'lower_layer',
    'lower_channel',
    'lower_vectors',
    'lower_layer_to_bottom',
    'lower_vectors_to_bottom',
    'raise_layer',
    'raise_channel',
    'raise_vectors',
    'raise_layer_to_top',
    'raise_vectors_to_top',
    'parasite_attach',
    'parasite_detach',
    'parasite_find',  
    'parasite_list',
    'scale_full',
    'free_shadow',
    'get_cmap',
    'set_cmap',
    'floating_selection',
    'list',
  ]
  
  Image = GimpOO::ClassTemplate.build('gimp-image-', blacklist, nil, [])
  
  class Image
    add_class_method('list', 'gimp-image-list')
    
    def dirty?
        PDB.gimp_image_is_dirty(self) == 1
    end
    
    def valid?
        PDB.gimp_image_is_valid(self) == 1
    end
    
    def undo_enabled?
        PDB.imp_image_undo_is_enabled(self) == 1
    end
    
    def selection_empty?
        PDB.gimp_selection_is_empty(self)
    end
    
    def layersID
        PDB.gimp_image_get_layers(self)[1]
    end
    def layersOO
        PDB.gimp_image_get_layers(self)[1].map {|l| Layer.create(l)}
    end    
    
    def channelsID
        PDB.gimp_image_get_channels(self)[1]
    end
    def channelsOO
        PDB.gimp_image_get_channels(self)[1].map {|ch| Channel.create(ch)}
    end
    
    def vectorsID
        PDB.gimp_image_get_vectors(self)[1]
    end
    def vectorsOO
        PDB.gimp_image_get_vectors(self)[1].map {|v| Vectors.create(v)}
    end

    def addLayer(width, height, type, name, opacity, mode, stack = -1)
        newlayer = Layer.new(self, width, height, type, name, opacity, mode)
        PDB.gimp_image_insert_layer(self, newlayer, nil, stack)
        newlayer
    end
    
    def addLayer_from_drawable(drawable, stack = -1)
        newlayer = PDB.gimp_layer_new_from_drawable(drawable, self)
        self.insert_layer(newlayer, nil, stack)
        newlayer
    end
    
    def addLayer_from_visible(dest_image, name, stack = -1)
        newlayer = Layer.new_from_visible(self, dest_image, name)
        PDB.gimp_image_insert_layer(self, newlayer, nil, stack)
        newlayer
    end
    
    alias_method :old_undo_group_start, :undo_group_start

    def undo_group_start
      old_undo_group_start
      if block_given?
        begin
          yield
        ensure
          undo_group_end
        end
      end
    end
    
    alias_method :old_undo_disable, :undo_disable

    def undo_disable
      old_undo_disable
      if block_given?
        begin
          yield
        ensure
          undo_enable
        end
      end
    end
  end
end
