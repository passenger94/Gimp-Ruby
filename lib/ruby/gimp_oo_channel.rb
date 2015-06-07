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
    'get_name',
    'get_tattoo',
    'get_visible',
    'set_name',
    'set_tattoo',
    'set_visible',
    'ops_duplicate',    # deprecated for 'gimp_image_duplicate'
    'ops_offset'        # deprecated for 'gimp_drawable_offset'
  ]
  
  Channel = GimpOO::ClassTemplate.template('gimp-channel-', blacklist,
                                           nil, [],
                                           Gimp::Drawable)
end