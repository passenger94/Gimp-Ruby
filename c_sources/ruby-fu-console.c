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
 
/* This file isn't actually part of the extension, but a helper
 * program used by the Ruby-Fu console. Hopefully this will be a
 * temporary solution. It simply uses the standard streams to
 * communicate with the console plugin.
 */
 
#include <string.h>
#include <libintl.h>

#include <gtk/gtk.h>
#include <gdk/gdkkeysyms.h>

//#include "../config.h"
//#include <libgimp/gimp.h>
//#include <libgimp/gimpui.h>


//#define GTK3 1 // TODO !

#define BUFFSIZE 1024

#define WIDTH 600
#define HEIGHT 400

GtkTextBuffer *textBuffer;
GtkAdjustment *scroll;

static gboolean
scroll_end_idle (gpointer ptr)
{
#ifdef GTK3 
  gtk_adjustment_set_value(scroll, gtk_adjustment_get_upper(scroll) - gtk_adjustment_get_page_size(scroll));
#else
  gtk_adjustment_set_value(scroll, scroll->upper - scroll->page_size);
#endif
  
  return FALSE;
}

static void
scroll_end_add (void)
{
  g_idle_add(scroll_end_idle, NULL);
}

static void
window_destroy (GtkWidget *widget,
                gpointer   data)
{
  g_print("%s\n", "quit");
  gtk_main_quit();
}

static void
browse_clbk(GtkButton *button,
            gpointer   user_data)
{
  g_print("%s\n", "PDB.call_interactive('plug_in_dbbrowser')");
  
  
//  plug_in_dbbrowser(GIMP_RUN_INTERACTIVE);
  
//  gint n_return_vals;
//  GimpParam *return_vals;
////  return_vals = gimp_run_procedure("plug-in-dbbrowser", &n_return_vals,
////                                    GIMP_PDB_INT32, GIMP_RUN_INTERACTIVE,
////                                    GIMP_PDB_END);
//  GimpParam args[1];
//  args[0].type = GIMP_PDB_INT32;
//  args[0].data.d_int32 = GIMP_RUN_INTERACTIVE;
//  return_vals = gimp_run_procedure2("plug-in-dbbrowser", &n_return_vals,
//                                    1, args);
//  gimp_destroy_params (args);
//  gimp_destroy_params (return_vals, n_return_vals);
  
//#define PLUG_IN_PROC   "plug-in-dbbrowser"
//#define PLUG_IN_BINARY "procedure-browser"
//#define PLUG_IN_ROLE   "gimp-procedure-browser"
//  GtkWidget *dialog;
//  gimp_ui_init (PLUG_IN_BINARY, FALSE);
//  dialog = gimp_proc_browser_dialog_new("Procedure Browser", PLUG_IN_BINARY,
//                                        gimp_standard_help_func, PLUG_IN_PROC,
//                                        GTK_STOCK_CLOSE, GTK_RESPONSE_CLOSE,
//                                        NULL);
//  gtk_dialog_run(GTK_DIALOG (dialog));
//  gtk_widget_destroy(dialog);
}

static gboolean
read_func (GIOChannel   *stream,
           GIOCondition  condition,
           gpointer      ptr)
{
  gchar str[BUFFSIZE];
  gsize bytes;
  //gchar *str;
  //gsize length;
  //gsize end_pos;
  GError *err = NULL;
  GIOStatus status;
  GtkTextIter iter;
  
  while ((status = g_io_channel_read_chars(stream, str, BUFFSIZE, &bytes, &err)))
  //while ((status = g_io_channel_read_line(stream, &str, &length, NULL, &err)))
    {    
      if (status == G_IO_STATUS_ERROR) {
          g_error ("Error reading: %s\n", err->message); 
          
      } else if (status == G_IO_STATUS_EOF) {
        
          /* If the plugin closes, we should quit too. */
          gtk_main_quit();
          return TRUE;
        
      } else if (status == G_IO_STATUS_AGAIN) {
        
          /* If we reach the end of the stream
           * scroll to the end and wait for more data */
          scroll_end_add();
          return TRUE;
      } else {
          gtk_text_buffer_get_end_iter(textBuffer, &iter);
          if (str != NULL && strncmp(str, "Switch to inspect mode", 20) != 0 && 
              strncmp(str, "PDB.call_interactive('plug_in_dbbrowser'", 39) != 0) {
              gtk_text_buffer_insert(textBuffer, &iter, str, bytes);
            //gtk_text_buffer_insert(textBuffer, &iter, str, length);
            //g_free(str);
          }
      }
    }
    
  return TRUE;
}

static gboolean
key_function (GtkWidget   *widget,
              GdkEventKey *event,
              gpointer     ptr)
{
  /* Catch the return key and process accordingly */
#if GTK3
  if (event->keyval == GDK_KEY_Return)
#else
  if (event->keyval == GDK_Return)
#endif
    {
      GtkEntry *entry = ptr;
      GtkTextIter iter;
      
      gchar *str = g_strdup_printf("%s\n", gtk_entry_get_text(entry));
      g_print(str);
      
      gtk_text_buffer_get_end_iter(textBuffer, &iter);
      gtk_text_buffer_insert_with_tags_by_name(textBuffer, &iter, str, -1,
                                               "bold", NULL);
      scroll_end_add();

      g_free(str);
      gtk_entry_set_text(entry, "");
    }

  return FALSE;
}

int main(int argc, char **argv)
{
  gtk_init(&argc, &argv);

  /* make window */ 
  GtkWidget *window = gtk_window_new(GTK_WINDOW_TOPLEVEL);
  gtk_window_set_title(GTK_WINDOW(window), gettext("Interactive Ruby-Fu Console"));
  gtk_window_set_default_size(GTK_WINDOW(window), WIDTH, HEIGHT);
  g_signal_connect(window, "destroy", G_CALLBACK(window_destroy), NULL);

  /* make vbox */
#if GTK3
  GtkWidget *vbox = gtk_box_new(GTK_ORIENTATION_VERTICAL, 12);
#else
  GtkWidget *vbox = gtk_vbox_new(FALSE, 12);
#endif
  gtk_container_set_border_width (GTK_CONTAINER (vbox), 12);
  gtk_container_add(GTK_CONTAINER(window), vbox);

  /* make scrolled window */
  GtkWidget *scrolled_window = gtk_scrolled_window_new(NULL, NULL);
  gtk_scrolled_window_set_policy(GTK_SCROLLED_WINDOW(scrolled_window),
                                 GTK_POLICY_AUTOMATIC,
                                 GTK_POLICY_ALWAYS);
  scroll = gtk_scrolled_window_get_vadjustment(
                                 GTK_SCROLLED_WINDOW(scrolled_window));
  gtk_box_pack_start (GTK_BOX (vbox), scrolled_window, TRUE, TRUE, 0);

  /* make text buffer */
  textBuffer = gtk_text_buffer_new(NULL);
  gtk_text_buffer_create_tag(textBuffer, "bold",
                             "weight", PANGO_WEIGHT_BOLD,
                             NULL);

  /* make text view */
  GtkWidget *view = gtk_text_view_new_with_buffer(textBuffer);
  gtk_text_view_set_editable(GTK_TEXT_VIEW(view), FALSE);
  gtk_text_view_set_left_margin(GTK_TEXT_VIEW(view), 6);
  gtk_text_view_set_right_margin(GTK_TEXT_VIEW(view), 6);
  gtk_container_add(GTK_CONTAINER(scrolled_window), view);

  /* make hbox */
#if GTK3
  GtkWidget *hbox = gtk_box_new(GTK_ORIENTATION_HORIZONTAL, 0);
#else
  GtkWidget *hbox = gtk_hbox_new(FALSE, 0);
#endif
  gtk_box_pack_start (GTK_BOX (vbox), hbox, FALSE, TRUE, 0);
  
  /* make prompt */
  GtkWidget *label = gtk_label_new(">> ");
  gtk_box_pack_start (GTK_BOX (hbox), label, FALSE, TRUE, 0);

  /* make text entry */
  GtkWidget *entry = gtk_entry_new();
  g_signal_connect(entry, "key-press-event",
                   G_CALLBACK(key_function), entry);
  gtk_box_pack_start (GTK_BOX(hbox), entry, TRUE, TRUE, 0);
  
  /* make buttons hbox */
#if GTK3
  GtkWidget *bhbox = gtk_button_box_new(GTK_ORIENTATION_HORIZONTAL);
#else
  GtkWidget *bhbox = gtk_hbutton_box_new();
#endif
  gtk_button_box_set_layout(GTK_BUTTON_BOX(bhbox), GTK_BUTTONBOX_END);
  gtk_box_set_spacing(GTK_BOX(bhbox), 30);
  gtk_box_pack_start (GTK_BOX(vbox), bhbox, FALSE, TRUE, 0);
  
  /* make buttons*/
  GtkWidget *browsedb_button = gtk_button_new_with_label("Browse Pdb");
  //gtk_widget_set_margin_right(browsedb_button, 30);
  g_signal_connect(browsedb_button, "clicked", G_CALLBACK(browse_clbk), NULL);
  gtk_box_pack_start (GTK_BOX(bhbox), browsedb_button, FALSE, TRUE, 0);
  
  GtkWidget *close_button = gtk_button_new_with_label("Close");
  g_signal_connect(close_button, "clicked", G_CALLBACK(window_destroy), NULL);
  gtk_box_pack_start (GTK_BOX(bhbox), close_button, FALSE, TRUE, 0);
  
    
  /* open stdin in non-blocking mode */
  GError *err = NULL;
  GIOChannel *stream;
  
  stream = g_io_channel_unix_new(0);
  GIOFlags flags = g_io_channel_get_flags(stream);
  flags |= G_IO_FLAG_NONBLOCK;
  g_io_channel_set_flags(stream, flags, &err);
  
  guint ret;
  ret = g_io_add_watch(stream, G_IO_IN |G_IO_HUP, &read_func, NULL);
  if (!ret) g_error ("Error creating watch!\n");
  
  gtk_widget_show_all(window);
  gtk_widget_grab_focus(entry);

  gtk_main();

  return 0;
}
