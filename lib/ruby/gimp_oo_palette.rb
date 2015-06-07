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
    'get_background',
    'get_foreground',
    'refresh',
    'set_background',
    'set_foreground',
    'set_default_colors',
    'swap_colors',
    
  ]
  
  class_blacklist = [
    'get_palette',
    'get_palette_entry',
    'set_palette',
  ]
  
  Palette = GimpOO::ClassTemplate.template('gimp-palette-', blacklist,
                                           'gimp-palettes-', class_blacklist)
  
    class Palette
        # class methods even though it isn't prefixed with 'gimp-palettes'
        def self.editable?(name)
            PDB.gimp_palette_is_editable(name) == 1 ? true : false
        end                                      
    end
end