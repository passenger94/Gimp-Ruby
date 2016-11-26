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



require 'gimpext'
require 'pdb'

def _(str)
  Gimp.gettext(str)
end

def N_(str)
  str
end

def ruby2int_filter(value)
  case value
  when true   then 1
  when false  then 0
  when nil    then -1
  else value
  end
end

module Gimp
  
  def message(*messages)
    messages.each do |message|
      PDB.gimp_message(message.to_s)
    end
  end
  
  module_function :message
  
  
  module ParamTypes
    
    CheckType = {
      :INT32 => :to_int,
      :INT16 => :to_int,
      :INT8 => :to_int,
      :FLOAT => :to_f,
      :STRING => :to_str,
      :INT32ARRAY => :to_ary,
      :INT16ARRAY => :to_ary,
      :INT8ARRAY => :to_str,
      :FLOATARRAY => :to_ary,
      :STRINGARRAY => :to_ary,
      :COLOR => Gimp::Rgb,
      :DISPLAY => :to_int,
      :IMAGE => :to_int,
      :ITEM => :to_int,
      :LAYER => :to_int,
      :CHANNEL => :to_int,
      :DRAWABLE => :to_int,
      :SELECTION => :to_int,
      :BOUNDARY => :to_int,
      :VECTORS => :to_int,
      :PARASITE => Gimp::Parasite,
      :STATUS => :to_int,
    }
    
    INT2TYPE = Hash.new
    EnumNames::PDBArgType.each do |key, value|
      INT2TYPE[key] = value.gsub('PDB_', '').to_sym
    end
    
    def self.check_type(sym, data)
      check = CheckType[sym]
      
      good_type = case check
        when Class  then data.is_a? check
        when Symbol then data.respond_to? check
      end
      raise(TypeError, "#A #{sym} cannot be created from a #{data.class}") unless good_type
    end
    
    def self.check_method(sym, args, nargs)
      return false unless CheckType.member? sym
      
      arglen = args.length
      raise(ArgumentError, "Wrong number of arguments. (#{arglen} for #{nargs})") unless arglen == nargs
      
      return true
    end
  end
  

  class ParamDef
    
    def self.method_missing(sym, *args)
      super unless ParamTypes.check_method(sym, args, 2)
      
      return new(Gimp.const_get("PDB_#{sym}".to_sym), *args)
    end
    
    def check(value)
      name = EnumNames::PDBArgType[type]
      sym = name.sub('PDB_', '').to_sym
            
      ParamTypes.check_type(sym, value)
    end
  end
  

  class Param

    def self.method_missing(sym, *args)
      super unless ParamTypes.check_method(sym, args, 1)
      
      ParamTypes.check_type(sym, args[0])
      new(Gimp.const_get("PDB_#{sym}".to_sym), args[0])
    end
    
    def transform
      case type
      when PDB_DISPLAY
        Display.create(data)
      when PDB_IMAGE
        Image.create(data)
      when PDB_LAYER
        Layer.create(data)
      when PDB_CHANNEL
        Channel.create(data)
      when PDB_DRAWABLE
        # at run time third mandatory argument in Image context must be a Drawable
        # Sometimes we need to work on the subClass (Layer or Channel)
        # make sure we are working on the appropriate Type
        if PDB.gimp_item_is_layer(data).to_bool
          Layer.create(data)
        elsif PDB.gimp_item_is_channel(data).to_bool
          Channel.create(data)
        else # just in case
          Drawable.create(data)
        end
      when PDB_ITEM
        Item.create(data)
      when PDB_VECTORS
        Vectors.create(data)
      else
        self.data
      end
    end
    
    def to_s
      "GimpParam #{EnumNames::PDBArgType[type]}: #{data}"
    end
  end
  

  class Rgb
    
    def marshal_dump
      [r, g, b, a]
    end
    
    def marshal_load(arr)
      new(*arr)
    end

    def eql?(other)
      return false unless other.is_a? Rgb
      r == other.r && g == other.g && b == other.b && a == other.a
    end
    
    alias_method :==, :eql?
    
    def to_s
      "RGB<r=#{r}, g=#{g}, b=#{b}, a=#{a}>"
    end
  end
  

  # no ned to take care of the splat operator here
  # we are calling a C function which happens to take care of the number of arguments
  # and expect 0,3 or 4 arguments (1 would be an array because of the splat)
  def Color(*args)
    Rgb.new(*args)
  end
  module_function :Color
  

  module Shelf
    
    def self.[](key)
      begin
        bytes, data = PDB.gimp_procedural_db_get_data(key)
        return Marshal.load(data)
      rescue PDB::ExecutionError
        return nil
      end
    end
    
    def self.[]=(key, obj)
      data = Marshal.dump(obj)
      PDB.gimp_procedural_db_set_data(key, data.length, data)
    end
  end
  

  autoload(:Layer,     'gimp_oo_layer.rb')
  autoload(:Drawable,  'gimp_oo_drawable.rb')
  autoload(:Channel,   'gimp_oo_channel.rb')
  autoload(:Vectors,   'gimp_oo_vectors.rb')
  autoload(:Item,      'gimp_oo_item.rb')
  autoload(:Brush,     'gimp_oo_brush.rb')
  autoload(:Palette,   'gimp_oo_palette.rb')
  autoload(:Gradient,  'gimp_oo_gradient.rb')
  autoload(:Display,   'gimp_oo_display.rb')
  autoload(:Image,     'gimp_oo_image.rb')
  
  autoload(:TextLayer, 'gimp_oo_layer.rb') # a module not a Class
  autoload(:Context,   'gimp_oo_context.rb')
  autoload(:Edit,      'gimp_oo_edit.rb')
  autoload(:Progress,  'gimp_oo_progress.rb')
  autoload(:Selection, 'gimp_oo_selection.rb')
end
