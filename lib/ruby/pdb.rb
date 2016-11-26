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


 
  
module G2RbBool
  def to_bool
      self == 0 ? false : true
  end
end
Integer.include G2RbBool 

module PDB
  
  class PDBException < RuntimeError; end

  class NoProcedure < PDBException
    attr_reader :message
    def initialize(proc_name)
      @message = "#{proc_name} is not in the PDB"
    end
  end
  
  class ExecutionError < PDBException
    attr_reader :message
    def initialize(proc_name)
      @message = "#{proc_name} returned an execution error."
    end
  end
  
  class CallingError < PDBException
    attr_reader :message
    def initialize(proc_name)
      @message = "#{proc_name} returned a calling error."
    end
  end
  

  class Procedure
    attr_reader :name, :blurb, :help, :author, :copyright, :date,
                :proc_type, :args, :return_vals
    
    @@cache = {}
    
    def self.new(name)
      @@cache[name] = super unless @@cache.include? name
      @@cache[name]
    end
    
    def initialize(name)
      @name = name
      
      values = Gimp.pdb_proc_info(name)
      raise(NoProcedure, name) unless values
      
      @blurb, @help, @author, @copyright, @date, @proc_type, @args, @return_vals = values
    end
    
    def convert_args(args)
      arglen = args.length
      prmlen = @args.length
      raise(ArgumentError, "Wrong number of parameters. #{arglen} for #{prmlen} expected") unless arglen == prmlen

      begin
        args.zip(@args).map do |arg, paramdef|
          arg = ruby2int_filter(arg)
          paramdef.check(arg)
          Gimp::Param.new(paramdef.type, arg)
        end
      rescue TypeError
        raise(TypeError, "Bad Argument: #{$!.message}")
      end
    end
    
    def convert_return_values(values)
      case values.shift.data
      when Gimp::PDB_CALLING_ERROR    then raise(CallingError, @name)
      when Gimp::PDB_EXECUTION_ERROR  then raise(ExecutionError, @name)
      end
      
      values.map { |param| param.transform }
    end
    
    def call(*args)
      if @args[0] and @args[0].name == 'run-mode'
        args.unshift(Gimp::RUN_NONINTERACTIVE)
      end
      
      puts "PDB call: #@name(#{args.map(&:inspect).join(', ')})" if PDB.verbose

      retvals = convert_return_values(Gimp.run_procedure(@name, convert_args(args)))
      retvals.size == 1 ? retvals[0] : retvals
    end
    
    def to_s
      [
        "       name: #@name",
        "      blurb: #@blurb",
        "       help: #@help",
        "     author: #@author",
        "  copyright: #@copyright",
        "       date: #@date",
        "  proc_type: #@proc_type",
        "       args: #@args",
        "return_vals: #@return_vals",
      ].join("\n")
    end
    
    def to_proc
      -> (*args) { self.call(*args) }
    end
  end
  

  class << self
    attr_accessor :verbose
    @verbose = false
    
    def [](name)
      Procedure.new(name)
    end
    
    def call_interactive(name, image = nil, drawable = nil)
        ## some plug_ins don't work in current gimp2.9 version (05/2015)
        ## "plug_in_gauss" doesn't but "plug_in_edge" does !?
      proc = Procedure.new(name)
      arg = proc.args[0]
      
      if arg and arg.name == 'run-mode'
        arg1 = proc.args[1]
        arg2 = proc.args[2]
        args = [Gimp::Param.INT32(Gimp::RUN_INTERACTIVE)]
        
        if arg1 and arg2 and arg1.name == 'image' and arg2.name == 'drawable'
          args += [Gimp::Param.IMAGE(image), Gimp::Param.DRAWABLE(drawable)]
        end
        
        retvals = proc.convert_return_values(Gimp.run_procedure(name, args))
        retvals.size == 1 ? retvals[0] : retvals
      else
        raise 'poop'
      end
    end
  end
  

  module Access
    SKIP = [:to_hash, :to_str, :to_ary, :to_a, :to_io, :to_int]

    def method_missing(sym, *args)
        
      return if SKIP.include?(sym) # WTF ??

      Procedure.new(sym.to_s.gsub('_', '-')).call(*args)

      rescue NoProcedure
        Gimp.message "NoProcedure !! #{$!.message}"
        warn "NoProcedure !! #{$!.message}"
        super
    end
    module_function :method_missing

  end
  
  extend Access
  
end
