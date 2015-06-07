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
        'get_image',    # deprecated for Item equivalent methods
        'set_image',    #
        'get_name',     #
        'set_name',     #
        'get_visible',  #
        'set_visible',  #
        'get_tattoo',   #
        'set_tattoo',   #
        'get_linked',   #
        'set_linked',   #
        'is_valid',     #
        'parasite_attach',  # deprecated for new item methods
        'parasite_detach',  #
        'parasite_find',    #
        'parasite_list',    #
        'to_selection',     # deprecated for 'gimp_image_select_item'
        'valid?'    # delegate to Item
    ]
    
    Vectors = GimpOO::ClassTemplate.template('gimp-vectors-', blacklist,
                                                nil, [], 
                                                Gimp::Item)
end
