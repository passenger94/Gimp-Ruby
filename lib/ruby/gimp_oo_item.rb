# GIMP-Ruby -- Allows GIMP plugins to be written in Ruby.
# Copyright (C) 2015  xy
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
    blacklist = []
  
    Item = GimpOO::ClassTemplate.template('gimp-item-', blacklist, nil, [])
    
    class Item
        
        def ==(other)
            return false unless other.is_a? Gimp::Item
            self.to_int == other.to_int
        end
        
        # PDB needed for cases we are not including "Access" into scripts
        # or when working in the internals of gimp-ruby
        def layer_mask?
            PDB.gimp_item_is_layer_mask(self) == 1 
        end
        
        def text_layer?
            PDB.gimp_item_is_text_layer(self) == 1
        end
        
        def layer?
            PDB.gimp_item_is_layer(self) == 1
        end
        
        def channel?
            PDB.gimp_item_is_channel(self) == 1
        end
        
        def drawable?
            PDB.gimp_item_is_drawable(self) == 1
        end
        
        def selection?
            PDB.gimp_item_is_selection(self) == 1
        end
        
        def vectors?
            PDB.gimp_item_is_vectors(self) == 1
        end
        
        def valid?
            PDB.gimp_item_is_valid(self) == 1
        end
        
        def group?
	        PDB.gimp_item_is_group(self) == 1
	    end
    end
end
