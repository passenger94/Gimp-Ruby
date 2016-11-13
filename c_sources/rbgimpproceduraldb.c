/* GIMP-Ruby -- Allows GIMP plugins to be written in Ruby.
 * Copyright (C) 2006  Scott Lembcke
 * 
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor,Boston, MA
 * 02110-1301, USA.
 */

#include <ruby.h>
#include <libgimp/gimp.h>

#include "rbgimp.h"

/*TODO a lot of these function might as well be used from the pdb.
 figure out which ones. Beware though, they are not necessarily returning the same thing*/
 
static VALUE
rb_gimp_procedural_db_temp_name(VALUE  self)
{
  gchar *name;
  name = gimp_procedural_db_temp_name();

  return rb_str_new2(name);
}

static VALUE
rb_gimp_procedural_db_proc_info(VALUE  self,
                                 VALUE  procedure)
{
  gchar *blurb, *help, *author, *copyright, *date;
  GimpPDBProcType proc_type;
  gint num_args, num_return_values;
  GimpParamDef *args, *return_vals;

  gboolean success;
  success = gimp_procedural_db_proc_info(StringValuePtr(procedure),
                                         &blurb,
                                         &help,
                                         &author,
                                         &copyright,
                                         &date,
                                         &proc_type,
                                         &num_args,
                                         &num_return_values,
                                         &args,
                                         &return_vals);

  if (success)
    {
      volatile VALUE ary = rb_ary_new();
      if(blurb) rb_ary_push(ary, rb_str_new2(blurb));
      else rb_ary_push(ary, rb_str_new(NULL, 0));

      if(help) rb_ary_push(ary, rb_str_new2(help));
      else rb_ary_push(ary, rb_str_new(NULL, 0));

      if(author) rb_ary_push(ary, rb_str_new2(author));
      else rb_ary_push(ary, rb_str_new(NULL, 0));

      if(copyright) rb_ary_push(ary, rb_str_new2(copyright));
      else rb_ary_push(ary, rb_str_new(NULL, 0));

      if(date) rb_ary_push(ary, rb_str_new2(date));
      else rb_ary_push(ary, rb_str_new(NULL, 0));

      if(proc_type) rb_ary_push(ary, INT2NUM(proc_type));
      else rb_ary_push(ary, rb_str_new(NULL, 0));

      rb_ary_push(ary, GimpParamDefs2rb(args, num_args));

      rb_ary_push(ary, GimpParamDefs2rb(return_vals, num_return_values));

      return ary;
    }
  else
    {
      return Qnil;
    }
}

static VALUE
  rb_gimp_procedural_db_get_data(VALUE self, VALUE identifier)
{
  /*TODO*/
  // gboolean success;
  // gpointer c_data (pack/unpack bytes ?)
  // success = gimp_procedural_db_get_data( (gchar *)StringValuePtr(identifier), 
  //                                        &c_data )
  // if (success)
  //   return rb_data;
  rb_notimplement();
  return Qnil;
}

static VALUE 
  rb_gimp_procedural_db_set_data(VALUE self, VALUE identifier, VALUE rb_data)
{
  /*TODO*/
  // gboolean success;
  // c_data (pack/unpack bytes ?)
  // success = gimp_procedural_db_set_data( (gchar *)StringValuePtr(identifier), 
  //                                        (gconstpointer)c_data,
  //                                        (guint32)c_data_length_in_bytes )
  // if (success)
  //   return Qtrue;
  rb_notimplement();
  return Qnil;
}

static VALUE
  rb_gimp_procedural_db_get_data_size(VALUE self, VALUE identifier)
{
  gint bytes;
  bytes = gimp_procedural_db_get_data_size((gchar *)StringValuePtr(identifier));

  return INT2NUM(bytes);
}

static VALUE
rb_gimp_procedural_db_dump(VALUE  self,
                           VALUE  filename)
{
  gboolean success;
  success = gimp_procedural_db_dump((gchar *)StringValuePtr(filename));

  return success ? Qtrue : Qfalse;
}

static VALUE
rb_gimp_procedural_db_query(VALUE  self,
                            VALUE  name,
                            VALUE  blurb,
                            VALUE  help,
                            VALUE  author,
                            VALUE  copyright,
                            VALUE  date,
                            VALUE  proc_type)
{
  gint num_matches;
  gchar **procedure_names;

  gboolean success;
  success = gimp_procedural_db_query((gchar *)StringValuePtr(name),
                                     (gchar *)StringValuePtr(blurb),
                                     (gchar *)StringValuePtr(help),
                                     (gchar *)StringValuePtr(author),
                                     (gchar *)StringValuePtr(copyright),
                                     (gchar *)StringValuePtr(date),
                                     (gchar *)StringValuePtr(proc_type),
                                     &num_matches,
                                     &procedure_names);

  if (success)
    {
      volatile VALUE ary = rb_ary_new();

      int i;
      for(i=0; i<num_matches; i++)
        rb_ary_push(ary, rb_str_new2(procedure_names[i]));

      return ary;
    }
  else
    {
      return Qnil;
    }
}

static VALUE
rb_gimp_procedural_db_proc_arg(VALUE  self,
                               VALUE  procedure_name,
                               VALUE  arg_num)
{
  GimpPDBArgType arg_type;
  gchar *arg_name, *arg_desc;

  gboolean success;
  success = gimp_procedural_db_proc_arg((gchar *)StringValuePtr(procedure_name),
                                        (gint)NUM2INT(arg_num),
                                        &arg_type,
                                        &arg_name,
                                        &arg_desc);

  if (success)
    {
      return rb_struct_new(sGimpParamDef,
                           INT2NUM(arg_type),
                           rb_str_new2(arg_name),
                           rb_str_new2(arg_desc),
                           NULL);
    }
  else
    {
      return Qnil;
    }
}

static VALUE
rb_gimp_procedural_db_proc_val(VALUE  self,
                               VALUE  procedure_name,
                               VALUE  arg_num)
{
  GimpPDBArgType val_type;
  gchar *val_name, *val_desc;

  gboolean success; 
  success = gimp_procedural_db_proc_val((gchar *)StringValuePtr(procedure_name),
                                        (gint)NUM2INT(arg_num),
                                        &val_type,
                                        &val_name,
                                        &val_desc);

  if (success)
    {
      return rb_struct_new(sGimpParamDef,
                           INT2NUM(val_type),
                           rb_str_new2(val_name),
                           rb_str_new2(val_desc),
                           NULL);
    }
  else
    {
      return Qnil;
    }
}

void Init_gimpproceduraldb(void)
{
  rb_define_module_function(mGimp, "pdb_temp_name", rb_gimp_procedural_db_temp_name, 0);
  rb_define_module_function(mGimp, "pdb_proc_info", rb_gimp_procedural_db_proc_info, 1);
  rb_define_module_function(mGimp, "pdb_get_data", rb_gimp_procedural_db_get_data, 1);
  rb_define_module_function(mGimp, "pdb_set_data", rb_gimp_procedural_db_set_data, 2);
  rb_define_module_function(mGimp, "pdb_get_data_size", rb_gimp_procedural_db_get_data_size, 1);
  rb_define_module_function(mGimp, "pdb_dump", rb_gimp_procedural_db_dump, 1);
  rb_define_module_function(mGimp, "pdb_query", rb_gimp_procedural_db_query, 7);
  rb_define_module_function(mGimp, "pdb_proc_arg", rb_gimp_procedural_db_proc_arg, 2);
  rb_define_module_function(mGimp, "pdb_proc_val", rb_gimp_procedural_db_proc_val, 2);
}
