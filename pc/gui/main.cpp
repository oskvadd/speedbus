#include <gtk/gtk.h>
#include <string>
#include <stdio.h>
#include <stdlib.h>
#include <execinfo.h>
#include <signal.h>

// Speedbus
#include <SerialStream.h>
#include <iostream>
#include <unistd.h>
#include <cstdlib>
#include <cstring>
#include <pthread.h>
#include <libconfig.h>
#include <dirent.h>
#include <libconfig.h>
#include <math.h>

#define IS_GUI 1
#define BACKEND_DIR "./"


#include "main.h"
#include "spb.backend.cpp"
#ifndef __SPEEDBLIB_H_INCLUDED__
#define __SPEEDBLIB_H_INCLUDED__
#include "../protocoll/speedblib.cpp"
#endif
#include "http_post.cpp"

#include "ssl.socket.h"

// Pre declared functions
static void rspeed_gui(gpointer * data);
//

enum
{
  COL_NAME = 0,
  COL_AGE,
  NUM_COLS
};


typedef struct _ProgressData
{
  gboolean open;
  gboolean remote;

  GtkWidget *window;
  GtkWidget *label1;
  GtkWidget *combo;
  GtkWidget *label2;
  GtkWidget *label3;
  GtkWidget *login_name;
  GtkWidget *login_pwd;
  GtkWidget *label_name;
  GtkWidget *label_pwd;
  GtkWidget *server_adress;
  GtkWidget *server_label;

  GtkWidget *auto_connect;
  GtkWidget *save_login;
  GtkWidget *connect_button;

  GtkWidget *menu, *menuItemConnect, *menuItemMainUI, *menuItemExit;
  GtkWidget *menuBar, *menuItemTopLvl, *mainMenu, *mainMenuItemExit;
  GtkStatusIcon *trayIcon;
  gpointer *share;
  bool serial_mode;
  config_t main_cfg;

  sslclient sslc;
  bool connected;
  bool save_con;
  gboolean is_admin;

} ProgressData;

typedef struct _rspeed_gui_rep
{
  gboolean open;
  gboolean remote;

  pthread_t printr;

  GtkWidget *window;
  GtkWidget *label;
  GtkWidget *devbutton;
  GtkWidget *debug_button;
  GtkWidget *combo;
  GtkWidget *box1;
  GtkWidget *box2;
  GtkWidget *box3;
  gboolean box3_set;
  GtkWidget *box4;
  GtkWidget *box5;

  // Things related to box3
  GtkWidget *label1;
  //
  GtkWidget *separator1;


  GtkWidget *pbar;
  GtkWidget *scan_list;

  // spb loader
  GtkWidget *spb_widgets[MAX_WIDGETS];
  int spb_widget_c;
  GtkWidget *spb_widget_row[MAX_ROWS];
  int spb_widget_row_c;
  int spb_widget_event[MAX_WIDGETS];
  int c_devid;			// Represent:s the current devid, opened in the gui
  //
  int spb_widget_vars_data[MAX_VARIABLE];
  int spb_widget_vars[MAX_WIDGETS][3];
  char spb_widget_vars_printf[MAX_WIDGETS][MAX_BUFFER];

  int spb_widget_variable_source[MAX_VARIABLE];
  char spb_widget_variable_type[MAX_VARIABLE][MAX_BUFFER];

  char spb_widget_getvars_data[MAX_EVENTS][10];	// Just an identifier for the right package, max 10chars
  //
  char addr1;
  char addr2;

  // Config fetch
  char got_rec;
  char config_byte;
  //

  main_backend *backe;
  gpointer *share;

  int timer;
  short scan_counter;
  GtkWidget *scan_button;
  gboolean scan_lock;

  // rdev gui window
  GtkWidget *rdev_gui;
  GtkWidget *rdev_box1;
  GtkWidget *rdev_box2;
  GtkWidget *rdev_box1_addr1;
  GtkWidget *rdev_box1_addr2;

  GtkWidget *rdev_label_addr1;
  GtkWidget *rdev_label_addr2;
  GtkWidget *rdev_addr_tbox1;
  GtkWidget *rdev_addr_tbox2;

  GtkWidget *rdev_stamp_button;
  GtkWidget *rdev_stamp_label;
  //

  GtkWidget *rdev_is_admin_button;
  GtkWidget *rdev_show_notify;
  GtkWidget *rdev_surve_screen_button;


  GtkWidget *rdev_dev_edit_button;

  sslclient sslc;
  gboolean is_admin;

  // rserver_settings
  GtkWidget *rserv_gui;
  GtkWidget *rserv_box0;
  GtkWidget *rserv_box1;
  GtkWidget *rserv_box2;
  GtkWidget *rserv_box3;
  GtkWidget *rserv_box4;
  GtkWidget *rserv_box5;


  GtkWidget *rserv_users_box;
  GtkTreeModel *rserv_model_user;
  GtkListStore *rserv_store_user;
  GtkTreeIter rserv_iter;

  GtkWidget *rserv_users_update;
  GtkWidget *rserv_adduser_button;
  GtkWidget *rserv_deluser_button;
  GtkWidget *rserv_moduser_button;


  GtkWidget *rserv_entry_moduser_user;
  GtkWidget *rserv_entry_user;
  GtkWidget *rserv_entry_pass;
  GtkWidget *rserv_entry_pass_c;
  GtkWidget *rserv_is_admin;
  GtkWidget *rserv_entry_your_pass;

  GtkWidget *rserv_label_moduser_user;
  GtkWidget *rserv_label_user;
  GtkWidget *rserv_label_pass;
  GtkWidget *rserv_label_pass_c;
  GtkWidget *rserv_label_is_admin;
  GtkWidget *rserv_label_your_pass;

  GtkWidget *rserv_box_moduser_user;
  GtkWidget *rserv_box_user;
  GtkWidget *rserv_box_pass;
  GtkWidget *rserv_box_pass_c;
  GtkWidget *rserv_box_is_admin;
  GtkWidget *rserv_box_button;
  GtkWidget *rserv_box_your_pass;

  GtkWidget *rserv_status_label;
  int rserv_your_clear_timeout;
  short rserv_your_clear_counter;
  short rserv_your_text_counter;

  GtkWidget *rserv_separator1;
  GtkWidget *rserv_separator2;
  GtkWidget *rserv_separator3;
  GtkWidget *rserv_tty_update;
  GtkWidget *rserv_tty_box;
  GtkTreeModel *rserv_model_tty;
  GtkListStore *rserv_store_tty;
  GtkWidget *rserv_tty_entry_box;
  GtkWidget *rserv_tty_label;
  GtkWidget *rserv_tty_entry;
  GtkWidget *rserv_tty_list_units;
  GtkWidget *rserv_tty_open;
  GtkWidget *rserv_tty_close;
  //

  // rdev_editor
  GtkWidget *rdeve_gui;
  GtkWidget *rdeve_box1;
  GtkWidget *rdeve_box2;
  GtkWidget *rdeve_box3;
  GtkWidget *rdeve_box4;
  GtkWidget *rdeve_devid_entry;
  GtkWidget *rdeve_devid_load;

  GtkWidget *rdeve_text_editor;
  GtkWidget *rdeve_text_editor_vscroll;
  GtkWidget *rdeve_text_editor_hscroll;
  GtkTextBuffer *rdeve_text_buffer;
  GtkTextIter rdeve_text_iter;
  GtkWidget *rdeve_status_bar;
  GtkWidget *rdeve_config_upload;
  GtkWidget *rdeve_config_check;
  GtkWidget *rdeve_event_edit;
  int rdeve_event_number;


  /// rdev_event_editor
  GtkWidget *rdevee_gui;
  GtkWidget *rdevee_box1;
  GtkWidget *rdevee_box2;
  GtkWidget *rdevee_box3;
  GtkWidget *rdevee_ebox;
  GtkWidget *rdevee_ebox1;
  GtkWidget *rdevee_load_event_label;
  GtkWidget *rdevee_load_event_entry;
  GtkWidget *rdevee_load_event_button;
  GtkWidget *rdevee_save_event_button;
  GtkWidget *rdevee_status_bar;
  bool rdevee_event_loaded;
  int rdevee_loaded_nr;
  int rdevee_load_type_hardcode;
  GtkWidget *rdevee_combo_opt;

  GtkWidget *rdevee_elem_box[MAX_WIDGETS];
  GtkWidget *rdevee_elem_input[MAX_WIDGETS];
  GtkWidget *rdevee_elem_label[MAX_WIDGETS];
  ///
  /// rnotify_show
  GtkWidget *rnotify_gui;
  GtkWidget *rnotify_box1;
  GtkWidget *rnotify_list;
  GtkTreeModel *rnotify_list_tree;
  GtkListStore *rnotify_list_list;
  GtkTreeIter rnotify_list_iter;
  GtkWidget *rnotify_label;
  GtkWidget *rnotify_update_notify;

  /// rsurve_screen_show
  GtkWidget *rsurve_gui;
  GtkWidget *rsurve_box1;
  GtkWidget *rsurve_box2;
  GtkWidget *rsurve_box3;
  GtkWidget *rsurve_box4;
    

  GtkWidget *rsurve_screen; 
  GtkWidget *rsurve_separator1; 
  GtkWidget *rsurve_separator2; 
  GtkWidget *rsurve_separator3;
  GtkWidget *rsurve_label1; 
  GtkWidget *rsurve_label2; 
  GtkWidget *rsurve_button1; 
  
 
  //


} rspeed_gui_rep;


void
m_send(void *ptr, char *data, int len)
{
  rspeed_gui_rep *rdata = (rspeed_gui_rep *) ptr;

  if (rdata->remote)
    {
      if (!((ProgressData *) rdata->share)->connected)
	{
	  gtk_label_set_text(GTK_LABEL(rdata->label), "ERROR: Not connected");
	  return;
	}
      char prepare[RECV_MAX];
      sprintf(prepare, "send ");
      if (len < 95)
	{
	  memcpy(prepare + 5, data, len);
	  rdata->sslc.send_data(prepare, len + 5);
	}
      else
	printf("ERROR PACKAGE TO BIGG\n");
    }
  else
    send(data, len);
}

void
exec_package(void *ptr, char *data, int counter)
{
  rspeed_gui_rep *rdata = (rspeed_gui_rep *) ptr;
  int devid = 0;

  if (debug)
    {
      std::cerr << std::endl;
      switch ((unsigned char)data[6])
	{
	case 0:
	  std::cerr <<
	    "Recived broadcast aknowlegde (0x00) from '" <<
	    std::dec << (data[2] & 0xff) << "." << (data[3] &
	    0xff) << "' to '" << std::dec << (data[0] & 0xff) << "." << (data[1] & 0xff) << "'";
	  break;
	case 1:
	  std::cerr << "Recived device list aknowlegde (0x01) from '" << std::dec << (data[2] & 0xff) << "." << (data[3] & 0xff) << "'";
	  break;
	case 3:
	  std::cerr << "Recived config fetch (0x03) from '" << std::dec << (data[2] & 0xff) << "." << (data[3] & 0xff) << "'";
	  break;
	case 170:
	  wtime();
	  std::cerr << "Recived ALARM (0xAA) from '" << std::dec << (data[2] & 0xff) << "." << (data[3] &
	    0xff) <<
	    "' Sig: (" << std::hex << (static_cast <
	    int >(data[7]) & 0xff)<<") Dec: (" << std::hex << (static_cast < int >(data[8]) & 0xff)<<")";
	  break;
	default:
	  std::cerr << "SUCESS: Recived package from: '" <<
	    std::dec << (static_cast < int >(data[2]) & 0xff)<<"." << (static_cast < int >(data[3]) & 0xff)<<"' With data: '";
	}
      for (int i = 0; i < counter - 9; i++)
	{
	  if (debug)
	    std::cerr << std::hex << (static_cast < int >(data[i + 6]) & 0xff);
	  if (i < counter - 10)
	    {
	      std::cerr << " ";
	    }
	  std::cerr << "'";
	}
    }
  if ((unsigned char)data[0] == addr1 && (unsigned char)data[1] == addr2)
    {
      get_vars_load(rdata, data, counter);
      switch ((unsigned char)data[6])
	{
	case 0:
	  got_resp = 1;
	  break;
	case 1:
	  if (counter < 11)
	    {			// If counter is less than 11, there is a usual 0x01, "ping" package,return
	      break;
	    }
	  devid = 0;
	  for (int i = 0; i < counter - 10; i++)
	    {			// Run this backwards to get the bytes right
	      devid <<= 8;
	      devid += data[i + 7];
	    }
	  device_add(rdata, data[2], data[3], devid);
	  rdata->got_rec = (unsigned char)data[6];
	  break;
	case 3:
	  rdata->got_rec = (unsigned char)data[6];
	  switch ((unsigned char)data[7])
	    {
	    case 0:
	      rdata->config_byte = data[8];
	      break;
	    }
	  break;
	}
    }
  else if ((unsigned char)data[0] == 0xFF && (unsigned char)data[1] == 0xFF)
    {
      switch ((unsigned char)data[6])
	{
	case 3:
	  rdata->got_rec = (unsigned char)data[6];
	  switch ((unsigned char)data[7])
	    {
	    case 1:
	      devid = 0;
	      for (int i = 0; i < counter - 11; i++)
		{		// Run this backwards to get the bytes right                                                                                      
		  devid <<= 8;
		  devid += (unsigned char)data[i + 8];
		}
	      char print[50];
	      device_add(rdata, data[2], data[3], devid);
	      speedbus_fill_devlist(rdata);
	      sprintf(print, "Recived IAH from: %d.%d (%d)", (unsigned char)data[2], (unsigned char)data[3], devid);
	      gtk_label_set_text(GTK_LABEL(rdata->label), print);
	      break;
	    }
	  break;
	}
    }
}


void *
client_handler(void *ptr)
{
  rspeed_gui_rep *rdata = (rspeed_gui_rep *) ptr;
  char data[RECV_MAX];
  int len;
  while (1)
    {
      len = rdata->sslc.recv_data(data);
      if (len > 0)
	{
	  if (strncmp(data, "send ", 5) == 0)
	    {
	      if (data[5] != data[6] != 0xFF)
		{
		  data[5] = addr1;
		  data[6] = addr2;
		}
	      exec_package(rdata, data + 5, len - 5);
	    }
	  if (strncmp(data, "userlist ", 9) == 0)
	    {
	      if (strlen(data) > MAX_LOGIN_TEXT)
		continue;
	      char username[MAX_LOGIN_TEXT + 9];
	      int is_admin;
	      sscanf(data, "userlist %s %d\n", username, &is_admin);
	      gtk_list_store_append(rdata->rserv_store_user, &rdata->rserv_iter);
	      gtk_list_store_set(rdata->rserv_store_user, &rdata->rserv_iter, COL_NAME, username, COL_AGE, is_admin, -1);
	      rdata->rserv_model_user = GTK_TREE_MODEL(rdata->rserv_store_user);
	      gtk_tree_view_set_model(GTK_TREE_VIEW(rdata->rserv_users_box), rdata->rserv_model_user);
	    }
	  if (strncmp(data, "sinfo ", 6) == 0)
	    {
	      data[RECV_MAX] = '\0';
	      gtk_label_set_text(GTK_LABEL(rdata->rserv_status_label), data + 6);
	    }
	  if (strncmp(data, "info ", 5) == 0)
	    {
	      data[RECV_MAX] = '\0';
	      gtk_label_set_text(GTK_LABEL(rdata->label), data + 5);
	    }
	  if (strncmp(data, "ttylist ", 8) == 0)
	    {
	      if (strlen(data) > RECV_MAX)
		continue;
	      char tty[RECV_MAX];
	      sscanf(data, "ttylist %s\n", tty);
	      gtk_list_store_append(rdata->rserv_store_tty, &rdata->rserv_iter);
	      gtk_list_store_set(rdata->rserv_store_tty, &rdata->rserv_iter, COL_NAME, tty, -1);
	      rdata->rserv_model_tty = GTK_TREE_MODEL(rdata->rserv_store_tty);
	      gtk_tree_view_set_model(GTK_TREE_VIEW(rdata->rserv_tty_box), rdata->rserv_model_tty);
	    }
	  if (strncmp(data, "ctty ", 5) == 0)
	    {
	      if (strlen(data) > RECV_MAX)
		continue;
	      char ctty[RECV_MAX];
	      sscanf(data, "ctty %s\n", ctty);
	      gtk_entry_set_text(GTK_ENTRY(rdata->rserv_tty_entry), ctty);
	    }
	  if (strncmp(data, "devlistadd ", 11) == 0)
	    {
	      if (strlen(data) > RECV_MAX)
		continue;
	      int addr1, addr2, devid;
	      sscanf(data, "devlistadd %d.%d %d\n", &addr1, &addr2, &devid);
	      device_add(rdata, addr1, addr2, devid);
	    }
	  if (strncmp(data, "udevlist ", 9) == 0)
	    {
	      if (rdata->open)
		speedbus_fill_devlist(rdata);
	    }
	  if (strncmp(data, "devec ", 6) == 0)
	    {
	      gtk_text_buffer_set_text(rdata->rdeve_text_buffer, "\0\0", -1);
	    }
	  if (strncmp(data, "devei ", 6) == 0)
	    {
	      gtk_text_buffer_get_end_iter(rdata->rdeve_text_buffer, &rdata->rdeve_text_iter);
	      gtk_text_buffer_insert(rdata->rdeve_text_buffer, &rdata->rdeve_text_iter, data + 6, strlen(data) - 6);
	    }
	  if (strncmp(data, "deveinfo ", 9) == 0)
	    {
	      gtk_statusbar_push(GTK_STATUSBAR(rdata->rdeve_status_bar), 0, data + 9);
	    }
	  if (strncmp(data, "notifyc ", 8) == 0)
	    {
	      int notifc;
	      // Take care of the notify message number
	      sscanf(data, "notifyc %d\n", &notifc);

	    }
	  if (strncmp(data, "notifya ", 8) == 0)
	    {
	      int date, id, priorty;
	      char msg[200], time[50];
	      if (len < 210 && sscanf(data, "notifya %d %d %d", &date, &id, &priorty) == 3)
		{
		  // Take care of the notify message number
		  sprintf(msg, "notifya %d %d %d", date, id, priorty);
		  int tmp_len = strlen(msg);
		  memset(msg, 0, 200);
		  if (tmp_len < 15)
		    return 0;
		  strncpy(msg, data + tmp_len, len - tmp_len);
		  char *tmp = strchr(msg, '\n');
		  *tmp = '\0';
		  struct tm *timeinfo = localtime((const time_t *)&date);
		  strftime(time, 50, "%y-%m-%d %H:%M:%S", timeinfo);
		  gtk_list_store_append(rdata->rnotify_list_list, &rdata->rnotify_list_iter);
		  gtk_list_store_set(rdata->rnotify_list_list,
		    &rdata->rnotify_list_iter, COL_NAME, time, COL_AGE, id, 2, priorty, 3, msg, -1);
		  rdata->rnotify_list_tree = GTK_TREE_MODEL(rdata->rnotify_list_list);
		  gtk_tree_view_set_model(GTK_TREE_VIEW(rdata->rnotify_list), rdata->rnotify_list_tree);
		}
	    }

	}
      else if (len == 0)
	{
	  printf("Connection seems to have died %d :/\n", len);
	  gtk_widget_show(((ProgressData *) rdata->share)->window);
	  gtk_label_set_text(GTK_LABEL(((ProgressData *) rdata->share)->label1), "Disconnected");
	  ((ProgressData *) rdata->share)->sslc.sslfree();
	  ((ProgressData *) rdata->share)->connected = 0;
	  gtk_button_set_label(GTK_BUTTON(((ProgressData *) rdata->share)->connect_button), "Connect to server");
	  return 0;
	}
    }
}

void *
print_ser_gui(void *ptr)
{
  rspeed_gui_rep *rdata = (rspeed_gui_rep *) ptr;

  int counter = 0;
  bool e = 0;
  bool justcap = 0;
  char data[100];

  while (1)
    {
      // Keep reading data from serial port and print it to the screen.
      //
      if (got_resp)
	usleep(500000);
      else
	usleep(5000);
      while (serial_port.rdbuf()->in_avail() > 0)
	{
	  char next_byte;
	  serial_port.get(next_byte);
	  if (next_byte == 0x7e && e == 1)
	    {
	      //bool loopback = memcmp(data, tx_data, counter);
	      unescape(data, &counter);	// Unescape the incomming package, check rfc1662 for escape rules
	      if (crcstrc(data, counter) && counter > 5)
		{		// Min packet length 5
		  if ((unsigned char)data[0] == addr1 && (unsigned char)data[1] == addr2 && ((unsigned char)data[5] == 1
		      && (unsigned char)data[6] != 0))
		    {		// IMPORTANT to check that the 
		      usleep(10000);	// there not is a response
		      send_response(data[2], data[3]);	// package.
		    }
		  // Got a great package!
		  exec_package(rdata, data, counter);
		  //
		  justcap = 1;
		  e = 0;
		}
	      else
		{
		  if (verbose)
		    {
		      std::cerr << "ERROR: recived damaged package";
		      counter = 0;
		    }
		  memset(data, 0x00, 100);
		}
	    }
	  if (e && next_byte != 0x7e)
	    {
	      data[counter] = next_byte;
	      counter++;
	    }
	  if (next_byte == 0x7e && e == 0 && justcap == 0)
	    {
	      counter = 0;
	      e = 1;
	    }
	  if (counter > 99)
	    {
	      counter = 0;
	      if (debug)
		{
		  std::cerr << "Killed package longer than 99bytes" << std::endl;
		}
	    }
	  if (debug)
	    std::cerr << std::hex << static_cast < int >(next_byte & 0xFF) << " ";
	  usleep(40);
	  justcap = 0;
	}
}}



static void
tty_to_combo(GtkWidget * combo)
{
  GList *glist = NULL;
  FILE *pipe = popen("find /dev/ -name ttyUSB*|tr -d '\n'", "r");	// Get USB tty:S for list, chose one to use at speedbus
  size_t len = 0;
  int lwen;
  char *tty;
  if (pipe == NULL)
    {
      g_print("Faild to open");
      exit(1);
    }
  while (lwen = getline(&tty, &len, pipe) > 0)
    {
      glist = g_list_append(glist, (gpointer *) tty);
      tty = NULL;
    }
  pclose(pipe);
  gtk_combo_set_popdown_strings(GTK_COMBO(combo), glist);
}


/* This is a callback function. The data arguments are ignored
 * in this example. More on callbacks below. */
static bool
open_tty_button(GtkWidget * widget, gpointer data)
{
  addr1 = 20;
  addr2 = 20;
  ProgressData *pdata = (ProgressData *) data;
  pdata->serial_mode = 1;

  char *string = NULL;
  string = (char *)gtk_entry_get_text(GTK_ENTRY(GTK_COMBO(pdata->combo)->entry));
  if (speed_open_tty(string))
    {
      //gtk_label_set_text (GTK_LABEL(pdata->label),"Sucess! Loading GUI...");
      gtk_label_set_text(GTK_LABEL(pdata->label1), "");
      gtk_widget_hide(GTK_WIDGET(pdata->window));
      pdata->open = 0;
      pdata->remote = 0;
      rspeed_gui((gpointer *) pdata);
      return 1;
    }
  else
    {
      gtk_label_set_text(GTK_LABEL(pdata->label1), "Error, look at stdout");
      return 0;
    }


}



static gboolean
delete_event(GtkWidget * widget, GdkEvent * event, gpointer data)
{
  /*
   * If you return FALSE in the "delete-event" signal handler,
   * * GTK will emit the "destroy" signal. Returning TRUE means
   * * you don't want the window to be destroyed.
   * * This is useful for popping up 'are you sure you want to quit?'
   * * type dialogs. 
   */

  //g_print ("delete event occurred\n");

  /*
   * Change TRUE to FALSE and the main window will be destroyed with
   * * a "delete-event". 
   */
  gboolean *gb;
  gb = (gboolean *) data;
  *gb = 0;
  gtk_widget_hide(GTK_WIDGET(widget));
  return TRUE;
}

/* Another callback */
static void
destroy(GtkWidget * widget, gpointer data)
{
  gboolean *gb;
  gb = (gboolean *) data;
  *gb = 0;
  gtk_widget_hide(GTK_WIDGET(widget));
}

static void
speedbus_fill_devlist(gpointer data)
{
  rspeed_gui_rep *rdata = (rspeed_gui_rep *) data;
  GtkTreeModel *model;
  GtkListStore *store;
  GtkTreeIter iter;


  store = gtk_list_store_new(NUM_COLS, G_TYPE_UINT, G_TYPE_STRING);


  for (int i = 0; i < device_num; i++)
    {
      /*
       * Append a row and fill in some data 
       */
      gtk_list_store_append(store, &iter);
      gtk_list_store_set(store, &iter, COL_NAME, device_id[i], COL_AGE, device_addr[i], -1);
    }
  model = GTK_TREE_MODEL(store);
  gtk_tree_view_set_model(GTK_TREE_VIEW(rdata->scan_list), model);
  usleep(200000);		// to prevent concurancy
}


static GtkWidget *
new_scan_list(void)
{
  GtkCellRenderer *renderer;
  GtkWidget *view;
  view = gtk_tree_view_new();
  renderer = gtk_cell_renderer_text_new();
  gtk_tree_view_insert_column_with_attributes(GTK_TREE_VIEW(view), -1, "Dev ID", renderer, "text", COL_NAME, NULL);
  renderer = gtk_cell_renderer_text_new();
  gtk_tree_view_insert_column_with_attributes(GTK_TREE_VIEW(view), -1, "Adress", renderer, "text", COL_AGE, NULL);
  return view;
}

static gboolean
speedbus_pbar_scanning_pack_send(gpointer data)
{
  rspeed_gui_rep *rdata = (rspeed_gui_rep *) data;
  int len = 8;
  char getdevs[20] = { 0xFF, 0xFF, addr1, addr2, 0x03, 0x01, 0x01, 0x00 };
  m_send(rdata, getdevs, len);
  rdata->scan_counter++;
  if (rdata->scan_counter >= 1)
    return 0;
  else
    return 1;
}


static gboolean
speedbus_pbar_scanning(gpointer data)
{
  rspeed_gui_rep *rdata = (rspeed_gui_rep *) data;
  gdouble new_val;
  char hej[50];
  /*
   * Calculate the value of the progress bar using the
   * * value range set in the adjustment object 
   */

  new_val = gtk_progress_bar_get_fraction(GTK_PROGRESS_BAR(rdata->pbar)) + 0.013;
  if (new_val > 1.0)
    {
      sprintf(hej, "100%%");
      gtk_progress_bar_set_text(GTK_PROGRESS_BAR(rdata->pbar), hej);
      rdata->scan_lock = 0;
      sprintf(hej, "Scanning done, found %d Devices", device_num);
      gtk_label_set_text(GTK_LABEL(rdata->label), hej);
      // 
      speedbus_fill_devlist(rdata);
      //
      return 0;
    }
  /*
   * Set the new value 
   */
  sprintf(hej, "%2.0f%%", (new_val * 100));
  gtk_progress_bar_set_text(GTK_PROGRESS_BAR(rdata->pbar), hej);
  gtk_progress_bar_set_fraction(GTK_PROGRESS_BAR(rdata->pbar), new_val);
  return 1;
}


static void
speedbus_unit_scan(GtkWidget * some, gpointer data)
{
  rspeed_gui_rep *rdata = (rspeed_gui_rep *) data;
  if (!rdata->scan_lock)
    {
      gtk_progress_bar_set_fraction(GTK_PROGRESS_BAR(rdata->pbar), 0);
      rdata->timer = g_timeout_add(100, speedbus_pbar_scanning, rdata);
      rdata->scan_lock = 1;
      rdata->scan_counter = 0;
      speedbus_pbar_scanning_pack_send(rdata);
      g_timeout_add(4000, speedbus_pbar_scanning_pack_send, rdata);
    }

}


static int
get_variable_gui(void *data, int var_id, bool from_gui)
{
  rspeed_gui_rep *rdata = (rspeed_gui_rep *) data;
  // Get variable as >256, subtract it in this function
  int devids = 0;
  for (int i = 0; i < device_num; i++)
    {
      if (device_id[i] == rdata->c_devid)
	{			// Device id is found in the MAIN device list
	  devids = i;
	  break;
	}
    }

  var_id -= 257;
  if (from_gui)
    {
      if (strcmp(rdata->spb_widget_variable_type[var_id], "scale") == 0)
	{
	  return (char)gtk_adjustment_get_value
	    (gtk_range_get_adjustment(GTK_RANGE(rdata->spb_widgets[rdata->spb_widget_variable_source[var_id]])));
	}
    }
  else
    {
      return backend_exec_ops(rdata->backe, devids, var_id + 257, rdata->spb_widget_vars_data[var_id], 0);
    }
}

static char
set_variable_gui(void *data, int var_id, int v_data)
{
  rspeed_gui_rep *rdata = (rspeed_gui_rep *) data;
  var_id -= 257;
  rdata->spb_widget_vars_data[var_id] = v_data;
  char print[200];
  int widget_id = rdata->spb_widget_variable_source[var_id];
  if (strcmp(rdata->spb_widget_variable_type[var_id], "label") == 0)
    {
      sprintf(print, rdata->spb_widget_vars_printf[widget_id],
	get_variable_gui(rdata,
	  rdata->spb_widget_vars[widget_id][1] +
	  257, 0), get_variable_gui(rdata,
	  rdata->spb_widget_vars[widget_id][2] + 257, 0), get_variable_gui(rdata, rdata->spb_widget_vars[widget_id][3] + 257, 0));
      gtk_label_set_text(GTK_LABEL(rdata->spb_widgets[widget_id]), print);
    }
  if (strcmp(rdata->spb_widget_variable_type[var_id], "scale") == 0)
    {
      GtkAdjustment *adj;
      adj = gtk_range_get_adjustment(GTK_RANGE(rdata->spb_widgets[widget_id]));
      gtk_adjustment_set_value(adj, get_variable_gui(rdata, var_id + 257, 0));
      gtk_range_set_adjustment(GTK_RANGE(rdata->spb_widgets[widget_id]), adj);
    }

}

static void
get_vars_load(void *data, char *p_data, int counter)
{
  rspeed_gui_rep *rdata = (rspeed_gui_rep *) data;
  for (int i = 0; i < device_num; i++)
    {
      if (device_id[i] == rdata->c_devid)
	{			// Device id is found in the MAIN device list
	  for (int ii = 0; ii < MAX_EVENT; ii++)
	    {
	      if ((rdata->backe->event_exist[ii]) && strcmp(rdata->backe->event_exec[i][ii], "getvars") == 0)
		{
		  int count = (unsigned char)rdata->backe->event_data[i][ii][0];
		  for (int iii = 0; iii < count; iii++)
		    {
		      if ((unsigned char)rdata->backe->event_data[i][ii][1 + iii] == (unsigned char)p_data[6 + iii])
			{
			  if ((iii + 1) == count)
			    {
			      count = (unsigned char)rdata->backe->event_data1[i][ii][0];
			      for (int iiii = 0; iiii < count; iiii++)
				{
				  set_variable_gui
				    (rdata,
				    rdata->backe->event_data1
				    [i][ii][iiii + 1], (unsigned char)p_data[rdata->backe->event_data2[i][ii][iiii + 1] + 6]);
				}

			    }
			}
		      else
			{
			  break;
			}
		    }
		}
	    }
	}
    }
}


static void
spb_device_event(GtkWidget * some, gpointer data)
{
  rspeed_gui_rep *rdata = (rspeed_gui_rep *) data;
  for (int i = 0; i < rdata->spb_widget_c; i++)
    {
      if (rdata->spb_widgets[i] == some)
	{
	  // If i is the number of the current widget

	  backend_exec(rdata->backe, rdata->spb_widget_event[i], rdata->c_devid, 1);

	}
    }

}

static void
load_device(gpointer data, int devid)
{
  rspeed_gui_rep *rdata = (rspeed_gui_rep *) data;
  config_t cfg;
  config_setting_t *setting;
  const char *str;
  char tmp[50];
  config_init(&cfg);
  // Clear vars
  memset(rdata->spb_widget_vars_data, 0x00, MAX_VARIABLE);
  //
  gtk_widget_show(rdata->devbutton);
  //
  sprintf(tmp, "devs/%d.spb", devid);
  /*
   * Read the file. If there is an error, report it and exit. 
   */
  if (!config_read_file(&cfg, tmp))
    {
      char tmp2[50];
      sprintf(tmp2, "ls devs/|grep %d.spb", devid);
      FILE *pipe = popen(tmp2, "r");
      if (fgets(tmp2, 50, pipe) == NULL)
	{
	  sprintf(tmp, "No File devs/%d.spb", devid);
	  gtk_label_set_text(GTK_LABEL(rdata->label), tmp);
	}
      else
	{

	  sprintf(tmp, "Line %d: %s\n", config_error_line(&cfg), config_error_text(&cfg));
	  config_destroy(&cfg);
	  gtk_label_set_text(GTK_LABEL(rdata->label), tmp);
	}
      gtk_widget_hide(rdata->separator1);
      return;
    }
  rdata->c_devid = devid;

  sprintf(tmp, "Sucess devs/%d.spb", devid);
  gtk_label_set_text(GTK_LABEL(rdata->label), tmp);
  gtk_widget_show(rdata->separator1);
  int source_width = 0;

  config_lookup_int(&cfg, "source_width", &source_width);	// Fetch width

  gtk_box_pack_start(GTK_BOX(rdata->box2), rdata->box3, FALSE, FALSE, source_width);


  rdata->spb_widget_c = 0;
  rdata->spb_widget_row_c = 0;

  /*
   * Get the device type name. 
   */
  if (config_lookup_string(&cfg, "name", &str))
    {
      rdata->label1 = gtk_label_new(str);
    }
  else
    {
      rdata->label1 = gtk_label_new("No name");
      fprintf(stderr, "No 'name' setting in configuration file.\n");
    }
  gtk_box_pack_start(GTK_BOX(rdata->box3), rdata->label1, FALSE, FALSE, 0);
  /*
   * Load widgets and events 
   */

  setting = config_lookup(&cfg, "spb.frontend");
  if (setting != NULL)
    {
      int count = config_setting_length(setting);

      for (int i = 0; i < count; ++i)
	{
	  config_setting_t *book = config_setting_get_elem(setting, i);

	  /*
	   * Only output the record if all of the expected fields are present. 
	   */
	  const char *type;
	  int row;

	  if (!(config_setting_lookup_string(book, "type", &type)))
	    continue;

	  if (config_setting_lookup_int(book, "row", &row) || rdata->spb_widget_row_c == 0)
	    {
	      for (; rdata->spb_widget_row_c <= row; rdata->spb_widget_row_c++)
		{
		  rdata->spb_widget_row[rdata->spb_widget_row_c] = gtk_hbox_new(FALSE, 0);
		  gtk_box_pack_start(GTK_BOX(rdata->box3), rdata->spb_widget_row[rdata->spb_widget_row_c], FALSE, FALSE, 0);
		  gtk_widget_show(rdata->spb_widget_row[rdata->spb_widget_row_c]);
		}
	    }


	  if (strcmp(type, "button") == 0)
	    {
	      const char *label;	// Check for lable, add button
	      if (!(config_setting_lookup_string(book, "label", &label)))
		rdata->spb_widgets[rdata->spb_widget_c] = gtk_button_new();
	      else
		rdata->spb_widgets[rdata->spb_widget_c] = gtk_button_new_with_label(label);
	      gtk_box_pack_start(GTK_BOX(rdata->spb_widget_row[row]), rdata->spb_widgets[rdata->spb_widget_c], FALSE, FALSE, 0);
	      // Add event number to widget
	      int event = 0;
	      if (!(config_setting_lookup_int(book, "event", &event)))
		rdata->spb_widget_event[rdata->spb_widget_c] = 0;
	      else
		rdata->spb_widget_event[rdata->spb_widget_c] = event;

	      g_signal_connect(rdata->spb_widgets[rdata->spb_widget_c], "clicked", G_CALLBACK(spb_device_event), rdata);
	      gtk_widget_show(rdata->spb_widgets[rdata->spb_widget_c++]);
	    }

	  if (strcmp(type, "scale") == 0)
	    {
	      int min;		// min max
	      int max;		// min max
	      int step;		// min max
	      if (!
		(config_setting_lookup_int
		  (book, "min", &min))
		|| !(config_setting_lookup_int(book, "max", &max)) || !(config_setting_lookup_int(book, "step", &step)))
		rdata->spb_widgets[rdata->spb_widget_c] = gtk_hscale_new_with_range(0, 255, 1);	// Nothing added, use one byte;
	      else
		rdata->spb_widgets[rdata->spb_widget_c] = gtk_hscale_new_with_range(min, max, step);
	      gtk_box_pack_start(GTK_BOX(rdata->spb_widget_row[row]), rdata->spb_widgets[rdata->spb_widget_c], TRUE, TRUE, 0);
	      // Add event number to widget
	      int event = 0;
	      if (!(config_setting_lookup_int(book, "event", &event)))
		rdata->spb_widget_event[rdata->spb_widget_c] = 0;
	      else
		rdata->spb_widget_event[rdata->spb_widget_c] = event;
	      int variable;
	      if ((config_setting_lookup_int(book, "variable", &variable)))
		{
		  int var_id = variable - 257;	// 257 = 0, 258 = 1 osv osv
		  rdata->spb_widget_variable_source[var_id] = rdata->spb_widget_c;
		  strcpy(rdata->spb_widget_variable_type[var_id], "scale");
		}

	      gtk_widget_show(rdata->spb_widgets[rdata->spb_widget_c++]);
	    }

	  if (strcmp(type, "label") == 0)
	    {
	      char print[200];
	      char var[10];
	      const char *label;	// min max
	      int tmp;
	      if (config_setting_lookup_string(book, "label", &label))
		{
		  strcpy(rdata->spb_widget_vars_printf[rdata->spb_widget_c], label);
		  if (!config_setting_lookup_int(book, "var1", &tmp))
		    {
		      rdata->spb_widgets[rdata->spb_widget_c] = gtk_label_new(label);
		    }
		  else
		    {
		      for (int i = 1; i < 4; i++)
			{
			  rdata->spb_widget_vars[rdata->spb_widget_c][i] = 0;
			  sprintf(var, "var%d", i);
			  if (config_setting_lookup_int(book, var, &tmp))
			    {
			      int var_id = rdata->spb_widget_vars[rdata->spb_widget_c][i] = tmp - 257;
			      rdata->spb_widget_variable_source[var_id] = rdata->spb_widget_c;
			      strcpy(rdata->spb_widget_variable_type[var_id], "label");
			    }
			}
		      sprintf(print, label, 0, 0, 0, 0, 0);
		      rdata->spb_widgets[rdata->spb_widget_c] = gtk_label_new(print);

		    }
		  gtk_box_pack_start(GTK_BOX(rdata->spb_widget_row[row]), rdata->spb_widgets[rdata->spb_widget_c], FALSE, FALSE, 0);
		  gtk_widget_show(rdata->spb_widgets[rdata->spb_widget_c++]);
		}

	    }

	}
    }
  // Autorun device event, after opening the device in gui

  setting = config_lookup(&cfg, "spb.events");
  if (setting != NULL)
    {
      int count = config_setting_length(setting);
      for (int i = 0; i < count; ++i)
	{
	  config_setting_t *book = config_setting_get_elem(setting, i);
	  int event, runon_open;
	  const char *type;
	  if (!
	    (config_setting_lookup_int
	      (book, "event", &event))
	    || !(config_setting_lookup_string(book, "type", &type)) || !(config_setting_lookup_int(book, "runon_open", &runon_open)))
	    continue;
	  if (sizeof(event) > MAX_EVENT || sizeof(type) > MAX_BUFFER)
	    continue;
	  if (runon_open)
	    backend_exec(rdata->backe, event, rdata->c_devid, 1);
	}
    }


  gtk_widget_show(rdata->box3);
  gtk_widget_show(rdata->label1);
}

void
view_onRowActivated(GtkTreeView * treeview, GtkTreePath * path, GtkTreeViewColumn * col, gpointer data)
{
  rspeed_gui_rep *rdata = (rspeed_gui_rep *) data;
  GtkTreeModel *model;
  GtkTreeIter iter;
  model = gtk_tree_view_get_model(treeview);
  if (gtk_tree_model_get_iter(model, &iter, path))
    {
      int devid;
      gtk_tree_model_get(model, &iter, 0, (gpointer) & devid, -1);
      const char *addr;
      gtk_tree_model_get(model, &iter, 1, (gpointer) & addr, -1);
      // Get addr...
      std::string waddr(addr);
      int dot = waddr.find(".");
      std::string tmp = waddr.substr(0, dot);
      rdata->addr1 = (char)atoi(tmp.c_str());
      tmp = waddr.substr(dot + 1, strlen(addr) - 1);
      rdata->addr2 = (char)atoi(tmp.c_str());

      // g_free(&devid); hmm, error here? Dont think it is needed tho, keep it for later.
      gtk_widget_destroy(rdata->box3);
      rdata->box3 = gtk_vbox_new(FALSE, 10);
      load_device(rdata, devid);
    }
}

gboolean
rdev_stamp(GtkWidget * some, gpointer data)
{
  rspeed_gui_rep *rdata = (rspeed_gui_rep *) data;
  const char *getcaddr1 = gtk_entry_get_text(GTK_ENTRY(rdata->rdev_addr_tbox1));
  const char *getcaddr2 = gtk_entry_get_text(GTK_ENTRY(rdata->rdev_addr_tbox2));
  int getaddr1 = atoi(getcaddr1);
  int getaddr2 = atoi(getcaddr2);
  if ((getaddr1 == 0 && getcaddr1[0] != '0')
    || (getaddr2 == 0 && getcaddr2[0] != '0') || getaddr1 > 255 || getaddr2 < 0 || getaddr2 > 255 || getaddr2 < 0)
    {
      gtk_label_set_text(GTK_LABEL(rdata->rdev_stamp_label), "That does not look like a vaild adress!");
      return 1;
    }
  char tmp[100];
  sprintf(tmp, "Stamping adress %d.%d...", getaddr1, getaddr2);
  gtk_label_set_text(GTK_LABEL(rdata->rdev_stamp_label), tmp);
  //std::cout << "Address: " << getaddr1 << "." << getaddr2 << "\n";
  got_resp = 0;
  for (int i = 0; i <= 5; i++)
    {
      if (i > 5)
	{
	  sprintf(tmp, "No response on stamp...", getaddr1, getaddr2);
	  gtk_label_set_text(GTK_LABEL(rdata->rdev_stamp_label), tmp);
	  break;
	}
      int len = 11;
      char getdevs[50] = { rdata->addr1, rdata->addr2, addr1, addr2, 0x03, 0x00,
	0x03, 0x01, getaddr1, getaddr2, 0x00
      };
      m_send(rdata, getdevs, len);
      usleep(500000);
      if (got_resp)
	{
	  sprintf(tmp, "Succefully stamped %d.%d...", getaddr1, getaddr2);
	  gtk_label_set_text(GTK_LABEL(rdata->rdev_stamp_label), tmp);
	  goto rdev_stamp_done;
	}
      else
	{
	  rdata->got_rec = 0;
	  int len2 = 7;
	  char getdevs2[50] = { getaddr1, getaddr2, addr1, addr2, 0x03, 0x00,
	    0x01, 0x00
	  };
	  m_send(rdata, getdevs2, len2);
	  usleep(500000);
	  if (rdata->got_rec == 1)
	    {
	      sprintf(tmp, "Succefully stamped %d.%d...", getaddr1, getaddr2);
	      gtk_label_set_text(GTK_LABEL(rdata->rdev_stamp_label), tmp);
	      goto rdev_stamp_done;
	    }
	}
    rdev_stamp_done:
      rdata->addr1 = getaddr1;
      rdata->addr2 = getaddr2;
      device_add(rdata, rdata->addr1, rdata->addr2, rdata->c_devid);
      backend_check_update_addr(rdata->backe, rdata->c_devid);	// Well, this should be updated automaticly when an event ocurres, 
      // but to prevent bugs in the future, i do an update here to
      return 1;
    }
}

gboolean
rdev_gui_destroy(GtkWidget * some, gpointer data)
{
  rspeed_gui_rep *rdata = (rspeed_gui_rep *) data;
  gtk_widget_set_sensitive(rdata->devbutton, true);
  gtk_widget_destroy(some);
  return 1;
}

gboolean
rdev_gui_delete(GtkWidget * some, GdkEvent * event, gpointer data)
{
  rspeed_gui_rep *rdata = (rspeed_gui_rep *) data;
  gtk_widget_set_sensitive(rdata->devbutton, true);
  gtk_widget_destroy(some);
  return 1;
}

void
rserver_settings_users_box(GtkTreeView * treeview, GtkTreePath * path, GtkTreeViewColumn * col, gpointer data)
{
  rspeed_gui_rep *rdata = (rspeed_gui_rep *) data;
  GtkTreeModel *model;
  GtkTreeIter iter;
  model = gtk_tree_view_get_model(treeview);
  if (gtk_tree_model_get_iter(model, &iter, path))
    {
      const char *username;
      gtk_tree_model_get(model, &iter, 0, (gpointer) & username, -1);
      int is_admin;
      gtk_tree_model_get(model, &iter, 1, (gpointer) & is_admin, -1);
      // Get addr...
      gtk_entry_set_text(GTK_ENTRY(rdata->rserv_entry_moduser_user), username);
      if (is_admin)
	gtk_toggle_button_set_active(GTK_TOGGLE_BUTTON(rdata->rserv_is_admin), TRUE);
      else
	gtk_toggle_button_set_active(GTK_TOGGLE_BUTTON(rdata->rserv_is_admin), FALSE);
    }
}

void
rserver_settings_moduser(GtkWidget * some, gpointer data)
{
  rspeed_gui_rep *rdata = (rspeed_gui_rep *) data;
  rdata->rserv_your_clear_counter = 0;
  if (!((ProgressData *) rdata->share)->connected)
    {
      gtk_label_set_text(GTK_LABEL(rdata->rserv_status_label), "ERROR: Not connected");
      return;
    }
  else
    {
      rdata->rserv_store_user = gtk_list_store_new(NUM_COLS, G_TYPE_STRING, G_TYPE_UINT);
      char *modusr, *usr, *pwd, *pwd_c;
      int is_admin;
      modusr = (char *)gtk_entry_get_text(GTK_ENTRY(rdata->rserv_entry_moduser_user));
      usr = (char *)gtk_entry_get_text(GTK_ENTRY(rdata->rserv_entry_user));
      if (strlen(usr) < 1)
	{
	  usr = new char[strlen(modusr)];
	  strcpy(usr, modusr);
	}
      pwd = (char *)gtk_entry_get_text(GTK_ENTRY(rdata->rserv_entry_pass));
      pwd_c = (char *)gtk_entry_get_text(GTK_ENTRY(rdata->rserv_entry_pass_c));
      is_admin = gtk_toggle_button_get_active(GTK_TOGGLE_BUTTON(rdata->rserv_is_admin));
      if (strcmp(pwd, pwd_c) == 0)
	{
	  char send_data[RECV_MAX];
	  if (strlen(pwd) < 1)
	    {
	      pwd = new char[2];
	      pwd[0] = '\x03';
	      pwd[1] = '\0';
	    }
	  sprintf(send_data, "moduser %s \t %d \t %s \t %s\n", modusr, is_admin, usr, pwd);
	  rdata->sslc.send_data(send_data, strlen(send_data));
	}
      else
	{
	  gtk_label_set_text(GTK_LABEL(rdata->rserv_status_label), "Passwords does not match");
	}
    }
}

void
rserver_settings_adduser(GtkWidget * some, gpointer data)
{
  rspeed_gui_rep *rdata = (rspeed_gui_rep *) data;
  rdata->rserv_your_clear_counter = 0;
  if (!((ProgressData *) rdata->share)->connected)
    {
      gtk_label_set_text(GTK_LABEL(rdata->rserv_status_label), "ERROR: Not connected");
      return;
    }
  else
    {
      rdata->rserv_store_user = gtk_list_store_new(NUM_COLS, G_TYPE_STRING, G_TYPE_UINT);
      char *usr;
      char *pwd;
      char *pwd_c;
      int is_admin;
      usr = (char *)gtk_entry_get_text(GTK_ENTRY(rdata->rserv_entry_user));
      pwd = (char *)gtk_entry_get_text(GTK_ENTRY(rdata->rserv_entry_pass));
      pwd_c = (char *)gtk_entry_get_text(GTK_ENTRY(rdata->rserv_entry_pass_c));
      is_admin = gtk_toggle_button_get_active(GTK_TOGGLE_BUTTON(rdata->rserv_is_admin));
      if (strcmp(pwd, pwd_c) == 0)
	{
	  char send_data[RECV_MAX];
	  sprintf(send_data, "adduser %s %s %d\n", usr, pwd, is_admin);
	  rdata->sslc.send_data(send_data, strlen(send_data));
	}
      else
	{
	  gtk_label_set_text(GTK_LABEL(rdata->rserv_status_label), "Passwords does not match");
	}
    }
}


void
rserver_settings_deluser(GtkWidget * some, gpointer data)
{
  rspeed_gui_rep *rdata = (rspeed_gui_rep *) data;
  rdata->rserv_your_clear_counter = 0;
  if (!((ProgressData *) rdata->share)->connected)
    {
      gtk_label_set_text(GTK_LABEL(rdata->rserv_status_label), "ERROR: Not connected");
      return;
    }
  else
    {
      rdata->rserv_store_user = gtk_list_store_new(NUM_COLS, G_TYPE_STRING, G_TYPE_UINT);
      char *usr;
      usr = (char *)gtk_entry_get_text(GTK_ENTRY(rdata->rserv_entry_moduser_user));
      char send_data[RECV_MAX];
      sprintf(send_data, "deluser %s\n", usr);
      rdata->sslc.send_data(send_data, strlen(send_data));
    }
}

void
rserver_settings_tty_list(GtkWidget * some, gpointer data)
{
  rspeed_gui_rep *rdata = (rspeed_gui_rep *) data;
  rdata->rserv_your_clear_counter = 0;
  if (!((ProgressData *) rdata->share)->connected)
    {
      gtk_label_set_text(GTK_LABEL(rdata->rserv_status_label), "ERROR: Not connected");
      return;
    }
  else
    {
      rdata->rserv_store_tty = gtk_list_store_new(1, G_TYPE_STRING);
      char *pattern;
      pattern = (char *)gtk_entry_get_text(GTK_ENTRY(rdata->rserv_tty_entry));
      char send_data[RECV_MAX];
      sprintf(send_data, "ttylist %s\n", pattern);
      rdata->sslc.send_data(send_data, strlen(send_data));
    }
}

void
rserver_settings_tty_open(GtkWidget * some, gpointer data)
{
  rspeed_gui_rep *rdata = (rspeed_gui_rep *) data;
  rdata->rserv_your_clear_counter = 0;
  if (!((ProgressData *) rdata->share)->connected)
    {
      gtk_label_set_text(GTK_LABEL(rdata->rserv_status_label), "ERROR: Not connected");
      return;
    }
  else
    {
      char *pattern;
      pattern = (char *)gtk_entry_get_text(GTK_ENTRY(rdata->rserv_tty_entry));
      char send_data[RECV_MAX];
      sprintf(send_data, "ttyopen %s\n", pattern);
      rdata->sslc.send_data(send_data, strlen(send_data));
    }
}

void
rserver_settings_tty_close(GtkWidget * some, gpointer data)
{
  rspeed_gui_rep *rdata = (rspeed_gui_rep *) data;
  rdata->rserv_your_clear_counter = 0;
  if (!((ProgressData *) rdata->share)->connected)
    {
      gtk_label_set_text(GTK_LABEL(rdata->rserv_status_label), "ERROR: Not connected");
      return;
    }
  else
    {
      rdata->sslc.send_data("ttyclose", strlen("ttyclose"));
    }
}

void
rserver_settings_update_tty(GtkWidget * some, gpointer data)
{
  rspeed_gui_rep *rdata = (rspeed_gui_rep *) data;
  rdata->rserv_your_clear_counter = 0;
  if (!((ProgressData *) rdata->share)->connected)
    {
      gtk_label_set_text(GTK_LABEL(rdata->rserv_status_label), "ERROR: Not connected");
      return;
    }
  else
    {
      rdata->rserv_store_tty = gtk_list_store_new(1, G_TYPE_STRING);
      rdata->sslc.send_data("get-tty", 7);
      return;
    }
}

void
rserver_settings_update_users(GtkWidget * some, gpointer data)
{
  rspeed_gui_rep *rdata = (rspeed_gui_rep *) data;
  rdata->rserv_your_clear_counter = 0;
  if (!((ProgressData *) rdata->share)->connected)
    {
      gtk_label_set_text(GTK_LABEL(rdata->rserv_status_label), "ERROR: Not connected");
      return;
    }
  else
    {
      rdata->rserv_store_user = gtk_list_store_new(NUM_COLS, G_TYPE_STRING, G_TYPE_UINT);
      rdata->sslc.send_data("userlist", 8);
      return;
    }
}

gboolean
rserver_settings_destroy(GtkWidget * some, gpointer data)
{
  rspeed_gui_rep *rdata = (rspeed_gui_rep *) data;
  g_source_remove(rdata->rserv_your_clear_timeout);
  gtk_widget_destroy(some);
  return 1;
}

gboolean
rserver_settings_delete(GtkWidget * some, GdkEvent * event, gpointer data)
{
  rspeed_gui_rep *rdata = (rspeed_gui_rep *) data;
  g_source_remove(rdata->rserv_your_clear_timeout);
  gtk_widget_destroy(some);
  return 1;
}

static gboolean
rserver_settings_your_clear(gpointer data)
{
  rspeed_gui_rep *rdata = (rspeed_gui_rep *) data;
  char *usr;
  usr = (char *)gtk_entry_get_text(GTK_ENTRY(rdata->rserv_entry_your_pass));
  int textc = strlen(usr);

  if (textc == rdata->rserv_your_text_counter && textc > 0)
    {
      rdata->rserv_your_clear_counter++;
    }
  else
    {
      rdata->rserv_your_clear_counter = 0;
    }
  if (rdata->rserv_your_clear_counter > 119)
    {
      gtk_entry_set_text(GTK_ENTRY(rdata->rserv_entry_your_pass), "");
      rdata->rserv_your_clear_counter = 0;
      gtk_label_set_text(GTK_LABEL(rdata->rserv_status_label), "Your password cleared due to inactivity(120sec)");
    }

  rdata->rserv_your_text_counter = textc;
  return 1;
}

static gboolean
rdeve_load_devid_unlock(gpointer data)
{
  rspeed_gui_rep *rdata = (rspeed_gui_rep *) data;
  gtk_widget_set_sensitive(rdata->rdeve_devid_load, TRUE);
  return 0;
}

gboolean
rdeve_load_devid(GtkWidget * buffer, gpointer data)
{
  rspeed_gui_rep *rdata = (rspeed_gui_rep *) data;
  const char *devid = gtk_entry_get_text(GTK_ENTRY(rdata->rdeve_devid_entry));
  char send_str[strlen(devid) + 10];
  if (atoi(devid) < 0)
    {
      gtk_statusbar_push(GTK_STATUSBAR(rdata->rdeve_status_bar), 0, "Check devid number, error...");
      return 1;
    }
  gtk_text_buffer_set_text(rdata->rdeve_text_buffer, "\0\0", -1);
  sprintf(send_str, "deveid %s\n", devid);
  rdata->sslc.send_data(send_str, strlen(send_str));
  rdata->rdeve_event_number = atoi(devid);
  g_timeout_add(1000, rdeve_load_devid_unlock, rdata);
  gtk_widget_set_sensitive(buffer, FALSE);
}


gboolean
rdeve_update_statusbar(GtkTextBuffer * buffer, gpointer data)
{
  rspeed_gui_rep *rdata = (rspeed_gui_rep *) data;

  gchar *msg;
  gint row, col;
  GtkTextIter iter;

  gtk_statusbar_pop(GTK_STATUSBAR(rdata->rdeve_status_bar), 0);

  gtk_text_buffer_get_iter_at_mark(buffer, &iter, gtk_text_buffer_get_insert(buffer));

  row = gtk_text_iter_get_line(&iter);
  col = gtk_text_iter_get_line_offset(&iter);

  msg = g_strdup_printf("Col %d Ln %d", col + 1, row + 1);

  gtk_statusbar_push(GTK_STATUSBAR(rdata->rdeve_status_bar), 0, msg);

  g_free(msg);
}

gboolean
rdeve_mark_set_callback(GtkTextBuffer * buffer, const GtkTextIter * new_location, GtkTextMark * mark, gpointer data)
{
  rspeed_gui_rep *rdata = (rspeed_gui_rep *) data;
  rdeve_update_statusbar(buffer, data);
}

bool
rdeve_fetch_config(gpointer data)
{
  rspeed_gui_rep *rdata = (rspeed_gui_rep *) data;

  GtkTextIter start, end;
  gtk_text_buffer_get_bounds(rdata->rdeve_text_buffer, &start, &end);
  char *ctext = gtk_text_buffer_get_text(rdata->rdeve_text_buffer, &start,
    &end, FALSE);

  FILE *p = NULL;
  p = fopen(".tmp.conf", "w");
  if (p == NULL)
    {
      gtk_statusbar_push(GTK_STATUSBAR(rdata->rdeve_status_bar), 0, "Error opening .tmp.conf premissions?");
      return 0;
    }
  int len = strlen(ctext);
  fwrite(ctext, len, 1, p);
  //  free(ctext);
  fclose(p);
  return 1;
}

bool
rdeve_open_config(gpointer data, config_t * cfg)
{

  rspeed_gui_rep *rdata = (rspeed_gui_rep *) data;

  config_init(cfg);

  if (!config_read_file(cfg, ".tmp.conf"))
    {
      char msg[200];
      sprintf(msg, "Error at Line %d: %s", config_error_line(cfg), config_error_text(cfg));
      config_destroy(cfg);
      gtk_statusbar_push(GTK_STATUSBAR(rdata->rdeve_status_bar), 0, msg);
      config_destroy(cfg);
      return 0;
    }
  else
    {
      gtk_statusbar_push(GTK_STATUSBAR(rdata->rdeve_status_bar), 0, "Config seems OK");
      return 1;
    }

}

gboolean
rdeve_config_upload(GtkWidget * buffer, gpointer data)
{
  rspeed_gui_rep *rdata = (rspeed_gui_rep *) data;

  config_t cfg;
  if (!rdeve_fetch_config(rdata) || !rdeve_open_config(rdata, &cfg))
    return 0;

  config_write_file(&cfg, ".tmp.conf");
  config_destroy(&cfg);

  FILE *dfile;
  dfile = fopen(".tmp.conf", "rb");
  if (dfile == NULL)
    {
      gtk_statusbar_push(GTK_STATUSBAR(rdata->rdeve_status_bar), 0, "Cant open .tmp.conf");
      return 0;
    }
  char tbuffer[RECV_MAX];
  char sbuffer[RECV_MAX];
  int i = 0;

  char arg[50];
  sprintf(arg, "devec %d\n", rdata->rdeve_event_number);

  rdata->sslc.send_data(arg, strlen(arg));
  usleep(10000);
  i = fread(tbuffer, 1, 970, dfile);
  while (i > 0)
    {
      tbuffer[i + 1] = '\0';
      sprintf(sbuffer, "devei %d %s", rdata->rdeve_event_number, tbuffer);
      rdata->sslc.send_data(sbuffer, strlen(sbuffer));
      usleep(50000);
      i = fread(tbuffer, 1, 970, dfile);

    }
  fclose(dfile);
  // Send a config reload
  rdata->sslc.send_data("devecr \n", strlen("devecr \n"));


}

gboolean
rdeve_config_check(GtkWidget * buffer, gpointer data)
{
  rspeed_gui_rep *rdata = (rspeed_gui_rep *) data;

  config_t cfg;
  if (!rdeve_fetch_config(rdata) || !rdeve_open_config(rdata, &cfg))
    return 0;

  config_destroy(&cfg);
}

gboolean
rdeve_config_reload(gpointer data)
{
  rspeed_gui_rep *rdata = (rspeed_gui_rep *) data;
  gtk_text_buffer_set_text(rdata->rdeve_text_buffer, "", 0);

  FILE *fr;
  char line[4096];

  fr = fopen(".tmp.conf", "rt");

  while (fgets(line, 4096, fr) != NULL)
    {
      gtk_text_buffer_get_end_iter(rdata->rdeve_text_buffer, &rdata->rdeve_text_iter);
      gtk_text_buffer_insert(rdata->rdeve_text_buffer, &rdata->rdeve_text_iter, line, strlen(line));
    }
  fclose(fr);


}


gboolean
rdeve_event_change(GtkWidget * buffer, gpointer data)
{
  rspeed_gui_rep *rdata = (rspeed_gui_rep *) data;
  rdata->rdevee_load_type_hardcode = gtk_combo_box_get_active(GTK_COMBO_BOX(rdata->rdevee_combo_opt)) + 1;
  rdeve_event_load(buffer, rdata);
}


gboolean
rdeve_event_save(GtkWidget * buffer, gpointer data)
{
  rspeed_gui_rep *rdata = (rspeed_gui_rep *) data;

  config_t cfg;
  if (!rdeve_fetch_config(rdata) || !rdeve_open_config(rdata, &cfg) || !rdata->rdevee_event_loaded)
    return 0;

  config_setting_t *setting;
  setting = config_lookup(&cfg, "spb.events");
  if (setting != NULL)
    {
      int count = config_setting_length(setting);
      for (int i = 0; i < count; ++i)
	{
	  config_setting_t *book = config_setting_get_elem(setting, i);
	  int event;
	  const char *type;
	  if (!(config_setting_lookup_int(book, "event", &event)) || !(config_setting_lookup_string(book, "type", &type)))
	    continue;
	  if (sizeof(event) > MAX_EVENT || sizeof(type) > MAX_BUFFER)
	    continue;
	  if (event == rdata->rdevee_loaded_nr)
	    {
	      if (strcmp(type, "send") == 0)
		{
		  printf("Type: %s\n", type);

		  config_setting_t *gdata_t;
		  gdata_t = config_setting_get_member(book, "data");
		  int edcount = config_setting_length(gdata_t);
		  int edata[edcount];
		  int ed;
		  for (int i = 0; i < edcount; ++i)
		    {
		      ed = config_setting_get_int_elem(gdata_t, i);
		      edata[i] = ed;
		    }


		  config_setting_t *deves;
		  deves = config_lookup(&cfg, "deve");
		  if (deves != NULL)
		    {
		      int di = gtk_combo_box_get_active(GTK_COMBO_BOX(rdata->rdevee_combo_opt));
		      config_setting_t *dvel = config_setting_get_elem(deves, di);
		      config_setting_t *data_t, *bits_t, *at_t;
		      bits_t = config_setting_get_member(dvel, "bits");
		      at_t = config_setting_get_member(dvel, "at");
		      data_t = config_setting_get_member(dvel, "data");
		      if (data_t != NULL && bits_t != NULL && at_t != NULL)
			{
			  //              int bits_c = config_setting_length(bits_t);
			  //int at_c = config_setting_length(at_t);
			  //int data_c = config_setting_length(data_t);
			  //if(bits_c == at_c && at_c == data_c){
			  // for(int i = 0; i < data_c; ++i)
			  //          {
			  //    long bits = config_setting_get_int_elem(bits_t, i);
			  //    long at = config_setting_get_int_elem(at_t, i);
			  //    long data = config_setting_get_int_elem(data_t, i);
			  //    int at_byte = at/8;
			  //    printf("at: %d data: %d bits: %d \n", at, data, bits);
			  //    char end_data[MAX_BUFFER];
			  //    
			  //  }
			  config_setting_t *opts_t;
			  opts_t = config_setting_get_member(dvel, "options");
			  if (opts_t != NULL)
			    {
			      int max_bytes = 0;	// this is in what byte the biggest value is, how many bytes doeas we need for the package
			      int opts_c = config_setting_length(opts_t);
			      if (opts_c)
				{
				  for (int oi = 0; oi < opts_c; ++oi)
				    {
				      config_setting_t *opts_e = config_setting_get_elem(opts_t, oi);
				      const char *oname;
				      int oat, obits;
				      bool is_set = 1;
				      if (config_setting_lookup_string(opts_e, "name", &oname)
					&& config_setting_lookup_int(opts_e, "at", &oat)
					&& config_setting_lookup_int(opts_e, "bits", &obits))
					{

					  int nval;
					  if (obits > 1)
					    {
					      const char *sval = gtk_entry_get_text(GTK_ENTRY(rdata->rdevee_elem_input[oi]));
					      if (!sscanf(sval, "%d", &nval))
						{
						  if (strcmp(sval, "Unset") == 0)
						    {
						      // If the val is unset
						      is_set = 0;
						      nval = 0;
						      //
						    }
						  else
						    {
						      char ftext[MAX_BUFFER];
						      memset(ftext, 0x00, MAX_BUFFER);
						      if (sizeof(oname) < (MAX_BUFFER - 25))
							sprintf(ftext, "number is fail at: %s", oname);
						      else
							{
							  sprintf(ftext, "number is fail at: ");
							  strncpy(ftext + 19, oname, MAX_BUFFER - 25);
							}
						      gtk_statusbar_push(GTK_STATUSBAR(rdata->rdevee_status_bar), 0, ftext);
						      return 1;
						    }
						}
					    }
					  else
					    nval = gtk_toggle_button_get_active(GTK_TOGGLE_BUTTON(rdata->rdevee_elem_input[oi]));

					  if (!is_set)
					    {

					    }
					  else
					    {
					      if (((oat + obits) / 8) > max_bytes)
						max_bytes = ((oat + obits) / 8);

					      if (nval > pow(2, obits))
						{
						  char ftext[MAX_BUFFER];
						  memset(ftext, 0x00, MAX_BUFFER);
						  if (sizeof(oname) < (MAX_BUFFER - 25))
						    sprintf(ftext, "number to high at: %s", oname);
						  else
						    {
						      sprintf(ftext, "number to high at: ");
						      strncpy(ftext + 21, oname, MAX_BUFFER - 25);
						    }
						  gtk_statusbar_push(GTK_STATUSBAR(rdata->rdevee_status_bar), 0, ftext);
						  return 1;
						}

					      int oat_byte = oat / 8;
					      int indata = edata[oat_byte];

					      int bstart = oat - (oat_byte * 8);
					      int bstop = bstart + obits;

					      int pattern;
					      for (int p1 = 0; p1 < 7; p1++)
						{	// UNSTABLE 121230 , i was not able to test this as much as i really should, so be aware of Bugs that may show up --- START
						  if (p1 < bstart)
						    {
						      pattern <<= 1;
						      pattern |= 0b1;
						    }
						  else if (p1 <= bstop)
						    {
						      pattern <<= 1;
						    }
						  else
						    {
						      pattern <<= 1;
						      pattern |= 0b1;
						    }
						}
					      indata &= pattern;
					      nval <<= (8 - bstop);
					      indata |= nval;
					      edata[oat_byte] = indata;
					    }
					}
				    }	// UNSTABLE 121230 ---- END
				  for (int ei = 0; ei < max_bytes; ei++)
				    {
				    }

				  for (int e_r = 0; e_r <= edcount; e_r++)
				    {
				      config_setting_remove_elem(gdata_t, e_r);
				    }

				  config_setting_set_int_elem(gdata_t, 0, (int)edata[0]);	// Dunno, but seems like you cant remove all the elements, so, this sets the first elem thats
				  for (int e_r = 1; e_r < max_bytes; e_r++)
				    {	// not removed, and after that we add new ones
				      config_setting_t *c_t;
				      c_t = config_setting_add(gdata_t, NULL, CONFIG_TYPE_INT);
				      config_setting_set_int_elem(gdata_t, e_r, (int)edata[e_r]);
				    }
				  config_write_file(&cfg, ".tmp.conf");
				  rdeve_config_reload(rdata);
				  config_destroy(&cfg);
				  return 1;

				}
			    }
			}
		    }
		}
	    }
	}
    }
}


gboolean
rdeve_event_load(GtkWidget * buffer, gpointer data)
{
  rspeed_gui_rep *rdata = (rspeed_gui_rep *) data;

  config_t cfg;
  if (!rdeve_fetch_config(rdata) || !rdeve_open_config(rdata, &cfg))
    return 0;


  if (rdata->rdevee_event_loaded)
    {
      if (!rdata->rdevee_load_type_hardcode)
	{
	  gtk_widget_destroy(rdata->rdevee_ebox1);
	  rdata->rdevee_ebox1 = gtk_vbox_new(FALSE, 10);
	  gtk_box_pack_start(GTK_BOX(rdata->rdevee_box3), rdata->rdevee_ebox1, FALSE, TRUE, 0);
	}

      gtk_widget_destroy(rdata->rdevee_ebox);
      rdata->rdevee_ebox = gtk_vbox_new(FALSE, 10);

      gtk_box_pack_start(GTK_BOX(rdata->rdevee_box3), rdata->rdevee_ebox, FALSE, TRUE, 0);
      //gtk_widget_set_size_request(rdata->rdevee_ebox, 600, 250);
    }
  rdata->rdevee_event_loaded = 1;



  int levent;
  sscanf((char *)gtk_entry_get_text(GTK_ENTRY(rdata->rdevee_load_event_entry)), "%d", &levent);
  if (levent < 1)
    {
      gtk_statusbar_push(GTK_STATUSBAR(rdata->rdevee_status_bar), 0, "Cant load, number is fail");
      return 0;
    }
  rdata->rdevee_loaded_nr = levent;


  config_setting_t *setting;
  setting = config_lookup(&cfg, "spb.events");
  if (setting != NULL)
    {
      int count = config_setting_length(setting);
      for (int i = 0; i < count; ++i)
	{
	  config_setting_t *book = config_setting_get_elem(setting, i);
	  int event;
	  const char *type;
	  if (!(config_setting_lookup_int(book, "event", &event)) || !(config_setting_lookup_string(book, "type", &type)))
	    continue;
	  if (sizeof(event) > MAX_EVENT || sizeof(type) > MAX_BUFFER)
	    continue;
	  if (event == levent)
	    {
	      if (strcmp(type, "send") == 0)
		{
		  printf("Type: %s\n", type);

		  config_setting_t *gdata_t;
		  gdata_t = config_setting_get_member(book, "data");
		  int edcount = config_setting_length(gdata_t);
		  int edata[edcount];
		  int ed;
		  for (int i = 0; i < edcount; ++i)
		    {
		      ed = config_setting_get_int_elem(gdata_t, i);
		      edata[i] = ed;
		    }
		  // -> Event editor load
		  config_setting_t *deves;
		  deves = config_lookup(&cfg, "deve");
		  if (deves != NULL)
		    {
		      int d_c = config_setting_length(deves);
		      for (int di = 0; di < d_c; ++di)
			{
			  config_setting_t *dvel = config_setting_get_elem(deves, di);
			  config_setting_t *data_t, *bits_t, *at_t;
			  bits_t = config_setting_get_member(dvel, "bits");
			  at_t = config_setting_get_member(dvel, "at");
			  data_t = config_setting_get_member(dvel, "data");
			  if (data_t != NULL && bits_t != NULL && at_t != NULL)
			    {
			      int bits_c = config_setting_length(bits_t);
			      int at_c = config_setting_length(at_t);
			      int data_c = config_setting_length(data_t);
			      if (bits_c == at_c && at_c == data_c)
				{
				  for (int i = 0; i < data_c; ++i)
				    {
				      int bits = config_setting_get_int_elem(bits_t, i);
				      int at = config_setting_get_int_elem(at_t, i);
				      int data = config_setting_get_int_elem(data_t, i);
				      int at_byte = at / 8;
				      int filter = 0;
				      at -= at_byte * 8;
				      int rf = 8 - (bits + at);

				      for (int fi = 0; fi < 7; fi++)
					{
					  if (at > 1)
					    {
					      filter <<= 1;
					      at--;
					    }
					  else if (bits > 0)
					    {
					      filter <<= 1;
					      filter |= 0b00000001;
					      bits--;
					    }
					  else
					    {
					      filter <<= 1;
					    }
					}
				      int evalue = edata[at_byte];
				      evalue &= filter;
				      evalue >>= rf;
				      if ((evalue == data && i == (data_c - 1) && !rdata->rdevee_load_type_hardcode)
					|| di + 1 == rdata->rdevee_load_type_hardcode)
					{
					  if (rdata->rdevee_load_type_hardcode)
					    {
					      for (int en_i = 0; en_i < data_c; en_i++)
						{
						  int bits = config_setting_get_int_elem(bits_t, en_i);
						  int at = config_setting_get_int_elem(at_t, en_i);
						  int data = config_setting_get_int_elem(data_t, en_i);

						  int at_byte = at / 8;
						  int indata = edata[at_byte];

						  int bstart = at - (at_byte * 8);
						  int bstop = bstart + bits;

						  int pattern;
						  for (int p1 = 0; p1 < 7; p1++)
						    {
						      // UNSTABLE 121230, i was not able to test this as much as i really should, so be aware of Bugs that may show up --- START
						      if (p1 < bstart)
							{
							  pattern <<= 1;
							  pattern |= 0b1;
							}
						      else if (p1 <= bstop)
							{
							  pattern <<= 1;
							}
						      else
							{
							  pattern <<= 1;
							  pattern |= 0b1;
							}
						    }
						  indata &= pattern;
						  data <<= (8 - bstop);
						  indata |= data;
						  edata[at_byte] = indata;
						  // UNSTABLE 121230
						}
					    }

					  if (!rdata->rdevee_load_type_hardcode)
					    {
					      const char *name;
					      config_setting_lookup_string(dvel, "name", &name);
					      rdata->rdevee_combo_opt = gtk_combo_box_new_text();
					      for (int opt_i = 0; opt_i < d_c; opt_i++)
						{
						  config_setting_lookup_string(config_setting_get_elem(deves, opt_i), "name", &name);
						  gtk_combo_box_append_text(GTK_COMBO_BOX(rdata->rdevee_combo_opt), name);
						}
					      gtk_combo_box_set_active(GTK_COMBO_BOX(rdata->rdevee_combo_opt), di);
					      g_signal_connect
						(G_OBJECT(rdata->rdevee_combo_opt), "changed", G_CALLBACK(rdeve_event_change), rdata);

					      gtk_box_pack_start(GTK_BOX(rdata->rdevee_ebox1), rdata->rdevee_combo_opt, FALSE, TRUE, 0);
					    }
					  // This is nott needed, se below gtk_box_pack_start (GTK_BOX (rdata->rdevee_ebox), rdata->rdevee_combo_opt, FALSE, FALSE, 0);
					  // -> Got a match in the dev list, load the options and the name, type of specified deve <
					  config_setting_t *opts_t;
					  opts_t = config_setting_get_member(dvel, "options");
					  if (opts_t != NULL)
					    {
					      int opts_c = config_setting_length(opts_t);
					      if (opts_c)
						{
						  for (int oi = 0; oi < opts_c; ++oi)
						    {
						      if (oi > MAX_WIDGETS)
							{
							  gtk_statusbar_push
							    (GTK_STATUSBAR
							    (rdata->rdeve_status_bar),
							    0,
							    "The number of options exceeded MAX_WIDGETS, please extend the value and recompile, if this is a problem");
							  break;
							}
						      config_setting_t *opts_e = config_setting_get_elem(opts_t, oi);
						      const char *oname;
						      int oat, obits;
						      if (config_setting_lookup_string(opts_e, "name", &oname)
							&& config_setting_lookup_int(opts_e, "at", &oat)
							&& config_setting_lookup_int(opts_e, "bits", &obits))
							{
							  rdata->rdevee_elem_box[oi] = gtk_hbox_new(FALSE, 10);

							  int oobits = obits;
							  int oat_byte = oat / 8;
							  int ofilter = 0;
							  oat -= oat_byte * 8;
							  int orf = 8 - (obits + oat);
							  for (int ofi = 0; ofi < 7; ofi++)
							    {
							      if (oat > 1)
								{
								  ofilter <<= 1;
								  oat--;
								}
							      else if (obits > 0)
								{
								  ofilter <<= 1;
								  ofilter |= 0b1;
								  obits--;
								}
							      else
								{
								  ofilter <<= 1;
								}
							    }
							  int oevalue = edata[oat_byte];
							  oevalue &= ofilter;
							  oevalue >>= orf;


							  if (oobits > 1)
							    {
							      rdata->rdevee_elem_input[oi] = gtk_entry_new();
							      char tval[50];
							      if (oat_byte + 1 > edcount)
								sprintf(tval, "Unset", edata[oat_byte]);
							      else if (edata[oat_byte] > 255)
								sprintf(tval, "(%d)", edata[oat_byte], oat_byte, edcount);
							      else
								sprintf(tval, "%d", oevalue);
							      gtk_entry_set_text(GTK_ENTRY(rdata->rdevee_elem_input[oi]), tval);
							    }
							  else
							    {
							      rdata->rdevee_elem_input[oi] = gtk_check_button_new();
							      if (oevalue)
								gtk_toggle_button_set_active
								  (GTK_TOGGLE_BUTTON(rdata->rdevee_elem_input[oi]), 1);
							    }
							  rdata->rdevee_elem_label[oi] = gtk_label_new(oname);
							  gtk_box_pack_start
							    (GTK_BOX
							    (rdata->rdevee_elem_box[oi]), rdata->rdevee_elem_input[oi], FALSE, FALSE, 0);
							  gtk_box_pack_start
							    (GTK_BOX
							    (rdata->rdevee_elem_box[oi]), rdata->rdevee_elem_label[oi], FALSE, FALSE, 0);
							  gtk_box_pack_start
							    (GTK_BOX(rdata->rdevee_ebox), rdata->rdevee_elem_box[oi], FALSE, FALSE, 0);

							}
						    }

						  gtk_widget_show_all(rdata->rdevee_ebox);

						  if (!rdata->rdevee_load_type_hardcode)
						    gtk_widget_show_all(rdata->rdevee_ebox1);
						  rdata->rdevee_load_type_hardcode = 0;
						  config_destroy(&cfg);
						  return 1;
						}
					    }
					  //
					}
				      else if (evalue != data)
					{
					  continue;
					}
				    }
				}
			      else
				{
				  gtk_statusbar_push
				    (GTK_STATUSBAR(rdata->rdeve_status_bar), 0, "data, at, bits do not have the same number of elements");
				}
			    }
			}
		    }
		  //
		}
	      else
		{
		  gtk_statusbar_push(GTK_STATUSBAR(rdata->rdeve_status_bar), 0, "Event type is not recognized");
		}
	    }
	}
    }



  config_destroy(&cfg);
}

gboolean
rdeve_event_edit(GtkWidget * buffer, gpointer data)
{
  rspeed_gui_rep *rdata = (rspeed_gui_rep *) data;

  config_t cfg;
  if (!rdeve_fetch_config(rdata) || !rdeve_open_config(rdata, &cfg))
    return 0;

  rdata->rdevee_event_loaded = 0;
  rdata->rdevee_load_type_hardcode = 0;
  rdata->rdevee_gui = gtk_window_new(GTK_WINDOW_TOPLEVEL);
  gtk_window_set_position(GTK_WINDOW(rdata->rdevee_gui), GTK_WIN_POS_CENTER);
  //gtk_window_set_default_size(GTK_WINDOW(rdata->rdevee_gui), 600, 250);
  g_signal_connect(rdata->rdevee_gui, "delete-event", G_CALLBACK(delete_event), rdata);
  g_signal_connect(rdata->rdevee_gui, "destroy", G_CALLBACK(destroy), rdata);

  rdata->rdevee_box1 = gtk_vbox_new(FALSE, 10);
  rdata->rdevee_box2 = gtk_hbox_new(FALSE, 10);
  rdata->rdevee_box3 = gtk_vbox_new(FALSE, 10);
  rdata->rdevee_ebox = gtk_vbox_new(FALSE, 10);
  rdata->rdevee_ebox1 = gtk_vbox_new(FALSE, 10);
  //gtk_widget_set_size_request(rdata->rdevee_box3, 600, 250);

  gtk_container_add(GTK_CONTAINER(rdata->rdevee_gui), rdata->rdevee_box1);
  rdata->rdevee_load_event_label = gtk_label_new("Event number: ");
  rdata->rdevee_load_event_entry = gtk_entry_new();
  rdata->rdevee_load_event_button = gtk_button_new_with_label("Load event");
  rdata->rdevee_save_event_button = gtk_button_new_with_label("Save event");
  gtk_box_pack_start(GTK_BOX(rdata->rdevee_box2), rdata->rdevee_load_event_label, FALSE, FALSE, 0);
  gtk_box_pack_start(GTK_BOX(rdata->rdevee_box2), rdata->rdevee_load_event_entry, FALSE, FALSE, 0);
  gtk_box_pack_start(GTK_BOX(rdata->rdevee_box2), rdata->rdevee_load_event_button, FALSE, FALSE, 0);
  gtk_box_pack_start(GTK_BOX(rdata->rdevee_box2), rdata->rdevee_save_event_button, FALSE, FALSE, 0);
  gtk_box_pack_start(GTK_BOX(rdata->rdevee_box1), rdata->rdevee_box2, FALSE, FALSE, 0);
  g_signal_connect(rdata->rdevee_load_event_button, "clicked", G_CALLBACK(rdeve_event_load), rdata);
  g_signal_connect(rdata->rdevee_save_event_button, "clicked", G_CALLBACK(rdeve_event_save), rdata);


  gtk_box_pack_start(GTK_BOX(rdata->rdevee_box1), rdata->rdevee_box3, FALSE, FALSE, 0);
  gtk_box_pack_start(GTK_BOX(rdata->rdevee_box3), rdata->rdevee_ebox1, FALSE, TRUE, 0);
  gtk_box_pack_start(GTK_BOX(rdata->rdevee_box3), rdata->rdevee_ebox, FALSE, FALSE, 0);

  rdata->rdevee_status_bar = gtk_statusbar_new();
  gtk_box_pack_start(GTK_BOX(rdata->rdevee_box1), rdata->rdevee_status_bar, FALSE, FALSE, 0);
  gtk_widget_show_all(rdata->rdevee_gui);
  config_destroy(&cfg);
}


void
rdev_editor(GtkWidget * some, gpointer data)
{
  rspeed_gui_rep *rdata = (rspeed_gui_rep *) data;
  rdata->rdeve_gui = gtk_window_new(GTK_WINDOW_TOPLEVEL);
  gtk_window_set_position(GTK_WINDOW(rdata->rdeve_gui), GTK_WIN_POS_CENTER);
  //gtk_window_set_default_size(GTK_WINDOW(rdata->rdeve_gui), 600, 750);
  g_signal_connect(rdata->rdeve_gui, "delete-event", G_CALLBACK(delete_event), rdata);
  g_signal_connect(rdata->rdeve_gui, "destroy", G_CALLBACK(destroy), rdata);

  rdata->rdeve_box1 = gtk_vbox_new(FALSE, 2);
  rdata->rdeve_box2 = gtk_hbox_new(FALSE, 10);
  rdata->rdeve_box3 = gtk_hbox_new(FALSE, 10);
  rdata->rdeve_box4 = gtk_hbox_new(FALSE, 2);

  //
  gtk_container_add(GTK_CONTAINER(rdata->rdeve_gui), rdata->rdeve_box1);
  GtkWidget *label = gtk_label_new("Devid to edit: ");
  rdata->rdeve_devid_entry = gtk_entry_new();
  rdata->rdeve_devid_load = gtk_button_new_with_label("Load devid");
  gtk_box_pack_start(GTK_BOX(rdata->rdeve_box2), label, FALSE, FALSE, 0);
  gtk_box_pack_start(GTK_BOX(rdata->rdeve_box2), rdata->rdeve_devid_entry, FALSE, FALSE, 0);
  gtk_box_pack_start(GTK_BOX(rdata->rdeve_box2), rdata->rdeve_devid_load, FALSE, FALSE, 0);
  gtk_box_pack_start(GTK_BOX(rdata->rdeve_box1), rdata->rdeve_box2, FALSE, FALSE, 0);



  rdata->rdeve_text_editor = gtk_text_view_new();
  rdata->rdeve_text_buffer = gtk_text_view_get_buffer(GTK_TEXT_VIEW(rdata->rdeve_text_editor));
  rdata->rdeve_status_bar = gtk_statusbar_new();
  rdata->rdeve_text_editor_vscroll = gtk_vscrollbar_new(gtk_text_view_get_vadjustment(GTK_TEXT_VIEW(rdata->rdeve_text_editor)));
  rdata->rdeve_text_editor_hscroll = gtk_hscrollbar_new(gtk_text_view_get_hadjustment(GTK_TEXT_VIEW(rdata->rdeve_text_editor)));
  gtk_widget_set_size_request(rdata->rdeve_text_editor, 600, 600);
  gtk_text_buffer_set_text(rdata->rdeve_text_buffer, "", 0);

  gtk_box_pack_start(GTK_BOX(rdata->rdeve_box4), rdata->rdeve_text_editor, TRUE, TRUE, 0);
  gtk_box_pack_start(GTK_BOX(rdata->rdeve_box4), rdata->rdeve_text_editor_vscroll, FALSE, FALSE, 0);
  gtk_box_pack_start(GTK_BOX(rdata->rdeve_box1), rdata->rdeve_box4, FALSE, FALSE, 0);
  gtk_box_pack_start(GTK_BOX(rdata->rdeve_box1), rdata->rdeve_text_editor_hscroll, FALSE, FALSE, 0);

  g_signal_connect(rdata->rdeve_devid_load, "clicked", G_CALLBACK(rdeve_load_devid), rdata);
  g_signal_connect(rdata->rdeve_text_buffer, "changed", G_CALLBACK(rdeve_update_statusbar), rdata);
  g_signal_connect(rdata->rdeve_text_buffer, "mark_set", G_CALLBACK(rdeve_mark_set_callback), rdata);

  gtk_widget_grab_focus(rdata->rdeve_text_editor);
  rdata->rdeve_config_upload = gtk_button_new_with_label("Upload config");
  gtk_box_pack_start(GTK_BOX(rdata->rdeve_box3), rdata->rdeve_config_upload, FALSE, FALSE, 0);
  rdata->rdeve_config_check = gtk_button_new_with_label("Check config");
  gtk_box_pack_start(GTK_BOX(rdata->rdeve_box3), rdata->rdeve_config_check, FALSE, FALSE, 0);
  rdata->rdeve_event_edit = gtk_button_new_with_label("Edit events");
  gtk_box_pack_start(GTK_BOX(rdata->rdeve_box3), rdata->rdeve_event_edit, FALSE, FALSE, 0);
  g_signal_connect(rdata->rdeve_config_upload, "clicked", G_CALLBACK(rdeve_config_upload), rdata);
  g_signal_connect(rdata->rdeve_config_check, "clicked", G_CALLBACK(rdeve_config_check), rdata);
  g_signal_connect(rdata->rdeve_event_edit, "clicked", G_CALLBACK(rdeve_event_edit), rdata);

  gtk_box_pack_start(GTK_BOX(rdata->rdeve_box1), rdata->rdeve_box3, FALSE, FALSE, 0);
  gtk_box_pack_start(GTK_BOX(rdata->rdeve_box1), rdata->rdeve_status_bar, FALSE, FALSE, 0);

  gtk_widget_show_all(rdata->rdeve_gui);
}


void
rserver_settings(GtkWidget * some, gpointer data)
{
  rspeed_gui_rep *rdata = (rspeed_gui_rep *) data;
  rdata->rserv_gui = gtk_window_new(GTK_WINDOW_TOPLEVEL);
  gtk_window_set_position(GTK_WINDOW(rdata->rserv_gui), GTK_WIN_POS_CENTER);
  gtk_window_set_resizable(GTK_WINDOW(rdata->rserv_gui), FALSE);
  g_signal_connect(rdata->rserv_gui, "delete-event", G_CALLBACK(rserver_settings_delete), rdata);
  g_signal_connect(rdata->rserv_gui, "destroy", G_CALLBACK(rserver_settings_destroy), rdata);

  rdata->rserv_box5 = gtk_vbox_new(FALSE, 10);
  rdata->rserv_box2 = gtk_vbox_new(FALSE, 10);
  rdata->rserv_box1 = gtk_hbox_new(FALSE, 10);
  rdata->rserv_box0 = gtk_vbox_new(FALSE, 10);
  rdata->rserv_box4 = gtk_vbox_new(FALSE, 10);
  rdata->rserv_box3 = gtk_vbox_new(FALSE, 10);
  //
  rdata->rserv_users_update = gtk_button_new_with_label("Update users");
  g_signal_connect(rdata->rserv_users_update, "clicked", G_CALLBACK(rserver_settings_update_users), rdata);
  //
  GtkCellRenderer *renderer;
  rdata->rserv_users_box = gtk_tree_view_new();
  renderer = gtk_cell_renderer_text_new();
  gtk_tree_view_insert_column_with_attributes(GTK_TREE_VIEW(rdata->rserv_users_box), -1, "Username", renderer, "text", COL_NAME, NULL);
  renderer = gtk_cell_renderer_text_new();
  gtk_tree_view_insert_column_with_attributes(GTK_TREE_VIEW(rdata->rserv_users_box), -1, "Is_admin", renderer, "text", COL_AGE, NULL);
  //
  g_signal_connect(rdata->rserv_users_box, "row-activated", G_CALLBACK(rserver_settings_users_box), rdata);

  rdata->rserv_adduser_button = gtk_button_new_with_label("Add user");
  g_signal_connect(rdata->rserv_adduser_button, "clicked", G_CALLBACK(rserver_settings_adduser), rdata);
  gtk_container_add(GTK_CONTAINER(rdata->rserv_gui), rdata->rserv_box5);
  gtk_box_pack_start(GTK_BOX(rdata->rserv_box5), rdata->rserv_box1, FALSE, FALSE, 0);
  gtk_box_pack_start(GTK_BOX(rdata->rserv_box0), rdata->rserv_users_update, FALSE, FALSE, 0);
  gtk_box_pack_start(GTK_BOX(rdata->rserv_box0), rdata->rserv_users_box, FALSE, FALSE, 0);
  gtk_box_pack_start(GTK_BOX(rdata->rserv_box0), rdata->rserv_adduser_button, FALSE, FALSE, 0);
  gtk_box_pack_start(GTK_BOX(rdata->rserv_box1), rdata->rserv_box0, FALSE, FALSE, 0);
  gtk_box_pack_start(GTK_BOX(rdata->rserv_box1), rdata->rserv_box2, FALSE, FALSE, 0);
  rdata->rserv_box_moduser_user = gtk_hbox_new(FALSE, 10);
  rdata->rserv_box_user = gtk_hbox_new(FALSE, 10);
  rdata->rserv_box_pass = gtk_hbox_new(FALSE, 10);
  rdata->rserv_box_pass_c = gtk_hbox_new(FALSE, 10);
  rdata->rserv_box_is_admin = gtk_hbox_new(FALSE, 10);
  rdata->rserv_box_button = gtk_hbox_new(FALSE, 10);
  rdata->rserv_box_your_pass = gtk_hbox_new(FALSE, 10);
  gtk_box_pack_start(GTK_BOX(rdata->rserv_box2), rdata->rserv_box_moduser_user, FALSE, FALSE, 0);
  gtk_box_pack_start(GTK_BOX(rdata->rserv_box2), rdata->rserv_box_user, FALSE, FALSE, 0);
  gtk_box_pack_start(GTK_BOX(rdata->rserv_box2), rdata->rserv_box_pass, FALSE, FALSE, 0);
  gtk_box_pack_start(GTK_BOX(rdata->rserv_box2), rdata->rserv_box_pass_c, FALSE, FALSE, 0);
  gtk_box_pack_start(GTK_BOX(rdata->rserv_box2), rdata->rserv_box_is_admin, FALSE, FALSE, 0);
  gtk_box_pack_start(GTK_BOX(rdata->rserv_box2), rdata->rserv_box_button, FALSE, FALSE, 0);
  //
  rdata->rserv_entry_moduser_user = gtk_entry_new();
  rdata->rserv_label_moduser_user = gtk_label_new("moduser user:\t");
  gtk_box_pack_start(GTK_BOX(rdata->rserv_box_moduser_user), rdata->rserv_label_moduser_user, FALSE, FALSE, 0);
  gtk_box_pack_start(GTK_BOX(rdata->rserv_box_moduser_user), rdata->rserv_entry_moduser_user, FALSE, FALSE, 0);
  //
  rdata->rserv_entry_user = gtk_entry_new();
  rdata->rserv_label_user = gtk_label_new("new username:\t");
  gtk_box_pack_start(GTK_BOX(rdata->rserv_box_user), rdata->rserv_label_user, FALSE, FALSE, 0);
  gtk_box_pack_start(GTK_BOX(rdata->rserv_box_user), rdata->rserv_entry_user, FALSE, FALSE, 0);
  //
  rdata->rserv_entry_pass = gtk_entry_new();
  rdata->rserv_label_pass = gtk_label_new("new password:\t");
  gtk_entry_set_visibility(GTK_ENTRY(rdata->rserv_entry_pass), FALSE);
  gtk_box_pack_start(GTK_BOX(rdata->rserv_box_pass), rdata->rserv_label_pass, FALSE, FALSE, 0);
  gtk_box_pack_start(GTK_BOX(rdata->rserv_box_pass), rdata->rserv_entry_pass, FALSE, FALSE, 0);
  //
  rdata->rserv_entry_pass_c = gtk_entry_new();
  rdata->rserv_label_pass_c = gtk_label_new("confirm pass:\t\t");
  gtk_entry_set_visibility(GTK_ENTRY(rdata->rserv_entry_pass_c), FALSE);
  gtk_box_pack_start(GTK_BOX(rdata->rserv_box_pass_c), rdata->rserv_label_pass_c, FALSE, FALSE, 0);
  gtk_box_pack_start(GTK_BOX(rdata->rserv_box_pass_c), rdata->rserv_entry_pass_c, FALSE, FALSE, 0);
  //
  rdata->rserv_is_admin = gtk_check_button_new();
  rdata->rserv_label_is_admin = gtk_label_new("is admin:\t\t\t");
  gtk_box_pack_start(GTK_BOX(rdata->rserv_box_is_admin), rdata->rserv_label_is_admin, FALSE, FALSE, 0);
  gtk_box_pack_start(GTK_BOX(rdata->rserv_box_is_admin), rdata->rserv_is_admin, FALSE, FALSE, 0);
  //
  rdata->rserv_deluser_button = gtk_button_new_with_label("Del user");
  rdata->rserv_moduser_button = gtk_button_new_with_label("Mod user");
  gtk_box_pack_start(GTK_BOX(rdata->rserv_box_button), rdata->rserv_deluser_button, FALSE, FALSE, 0);
  gtk_box_pack_start(GTK_BOX(rdata->rserv_box_button), rdata->rserv_moduser_button, FALSE, FALSE, 0);
  g_signal_connect(rdata->rserv_deluser_button, "clicked", G_CALLBACK(rserver_settings_deluser), rdata);
  g_signal_connect(rdata->rserv_moduser_button, "clicked", G_CALLBACK(rserver_settings_moduser), rdata);
  //
  rdata->rserv_separator2 = gtk_hseparator_new();
  gtk_box_pack_start(GTK_BOX(rdata->rserv_box5), rdata->rserv_separator2, FALSE, FALSE, 0);
  //
  rdata->rserv_entry_your_pass = gtk_entry_new();
  rdata->rserv_label_your_pass = gtk_label_new("your pass:\t\t");
  gtk_entry_set_visibility(GTK_ENTRY(rdata->rserv_entry_your_pass), FALSE);
  gtk_box_pack_start(GTK_BOX(rdata->rserv_box_your_pass), rdata->rserv_label_your_pass, FALSE, FALSE, 0);
  gtk_box_pack_start(GTK_BOX(rdata->rserv_box_your_pass), rdata->rserv_entry_your_pass, FALSE, FALSE, 0);
  gtk_box_pack_start(GTK_BOX(rdata->rserv_box5), rdata->rserv_box_your_pass, FALSE, FALSE, 0);
  //
  rdata->rserv_separator3 = gtk_hseparator_new();
  gtk_box_pack_start(GTK_BOX(rdata->rserv_box5), rdata->rserv_separator3, FALSE, FALSE, 0);
  //
  rdata->rserv_status_label = gtk_label_new("Your pass is cleared within 120sec of inactivity");
  gtk_box_pack_start(GTK_BOX(rdata->rserv_box5), rdata->rserv_status_label, FALSE, FALSE, 0);
  //
  // Set tty part: 
  rdata->rserv_separator1 = gtk_vseparator_new();
  gtk_box_pack_start(GTK_BOX(rdata->rserv_box1), rdata->rserv_separator1, FALSE, FALSE, 0);
  gtk_box_pack_start(GTK_BOX(rdata->rserv_box1), rdata->rserv_box3, FALSE, FALSE, 0);
  gtk_box_pack_start(GTK_BOX(rdata->rserv_box1), rdata->rserv_box4, FALSE, FALSE, 0);

  rdata->rserv_tty_update = gtk_button_new_with_label("Update ttys");
  g_signal_connect(rdata->rserv_users_update, "clicked", G_CALLBACK(rserver_settings_update_tty), rdata);
  //
  GtkCellRenderer *renderer_tty;
  rdata->rserv_tty_box = gtk_tree_view_new();
  renderer_tty = gtk_cell_renderer_text_new();
  gtk_tree_view_insert_column_with_attributes(GTK_TREE_VIEW(rdata->rserv_tty_box), -1, "TTY", renderer_tty, "text", COL_NAME, NULL);
  //
  g_signal_connect(rdata->rserv_users_box, "row-activated", G_CALLBACK(rserver_settings_users_box), rdata);
  gtk_box_pack_start(GTK_BOX(rdata->rserv_box3), rdata->rserv_tty_update, FALSE, FALSE, 0);
  gtk_box_pack_start(GTK_BOX(rdata->rserv_box3), rdata->rserv_tty_box, FALSE, FALSE, 0);


  rdata->rserv_tty_entry_box = gtk_hbox_new(FALSE, 10);
  rdata->rserv_tty_label = gtk_label_new("tty pattern: ");
  rdata->rserv_tty_entry = gtk_entry_new();
  gtk_box_pack_start(GTK_BOX(rdata->rserv_tty_entry_box), rdata->rserv_tty_label, FALSE, FALSE, 0);
  gtk_box_pack_start(GTK_BOX(rdata->rserv_tty_entry_box), rdata->rserv_tty_entry, FALSE, FALSE, 0);
  gtk_box_pack_start(GTK_BOX(rdata->rserv_box4), rdata->rserv_tty_entry_box, FALSE, FALSE, 0);
  rdata->rserv_tty_list_units = gtk_button_new_with_label("List pattern");
  gtk_box_pack_start(GTK_BOX(rdata->rserv_box4), rdata->rserv_tty_list_units, FALSE, FALSE, 0);
  g_signal_connect(rdata->rserv_tty_list_units, "clicked", G_CALLBACK(rserver_settings_tty_list), rdata);
  rdata->rserv_tty_open = gtk_button_new_with_label("Open pattern and write to config");
  gtk_box_pack_start(GTK_BOX(rdata->rserv_box4), rdata->rserv_tty_open, FALSE, FALSE, 0);
  g_signal_connect(rdata->rserv_tty_open, "clicked", G_CALLBACK(rserver_settings_tty_open), rdata);
  rdata->rserv_tty_close = gtk_button_new_with_label("Close current tty");
  gtk_box_pack_start(GTK_BOX(rdata->rserv_box4), rdata->rserv_tty_close, FALSE, FALSE, 0);
  g_signal_connect(rdata->rserv_tty_close, "clicked", G_CALLBACK(rserver_settings_tty_close), rdata);
  //
  gtk_widget_show_all(rdata->rserv_gui);

  rdata->rserv_your_clear_timeout = g_timeout_add(1000, rserver_settings_your_clear, rdata);
  rdata->rserv_your_clear_counter = 0;

  rdata->rserv_store_user = gtk_list_store_new(NUM_COLS, G_TYPE_STRING, G_TYPE_UINT);
  rdata->rserv_store_tty = gtk_list_store_new(1, G_TYPE_STRING);

  rdata->sslc.send_data("userlist", 8);
  usleep(50000);
  rdata->sslc.send_data("get-tty", 7);
  usleep(10000);
}

void
rdev_gui(GtkWidget * some, gpointer data)
{
  rspeed_gui_rep *rdata = (rspeed_gui_rep *) data;
  // Fetch the speedlib config details from the specific unit
  set_variable_gui(rdata, 260, 123);
  rdata->got_rec = 0;
  for (int i = 0; i <= 10; i++)
    {
      if (i > 9)
	{
	  gtk_widget_set_sensitive(rdata->devbutton, true);
	  gtk_label_set_text(GTK_LABEL(rdata->label), "No respone...");
	  return;
	}
      int len = 8;
      char getdevs[20] = { rdata->addr1, rdata->addr2, addr1, addr2, 0x03, 0x00,
	0x03, 0x00
      };
      m_send(rdata, getdevs, len);
      usleep(500000);
      if (rdata->got_rec == 3)
	break;
    }

  rdata->rdev_gui = gtk_window_new(GTK_WINDOW_TOPLEVEL);
  gtk_window_set_position(GTK_WINDOW(rdata->rdev_gui), GTK_WIN_POS_CENTER);
  gtk_window_set_resizable(GTK_WINDOW(rdata->rdev_gui), FALSE);
  g_signal_connect(rdata->rdev_gui, "delete-event", G_CALLBACK(rdev_gui_delete), rdata);
  g_signal_connect(rdata->rdev_gui, "destroy", G_CALLBACK(rdev_gui_destroy), rdata);

  rdata->rdev_box2 = gtk_vbox_new(FALSE, 10);
  rdata->rdev_box1 = gtk_hbox_new(FALSE, 10);
  gtk_container_add(GTK_CONTAINER(rdata->rdev_gui), rdata->rdev_box2);
  gtk_box_pack_start(GTK_BOX(rdata->rdev_box2), rdata->rdev_box1, FALSE, FALSE, 0);
  rdata->rdev_box1_addr1 = gtk_vbox_new(FALSE, 10);
  rdata->rdev_box1_addr2 = gtk_vbox_new(FALSE, 10);
  gtk_box_pack_start(GTK_BOX(rdata->rdev_box1), rdata->rdev_box1_addr1, FALSE, FALSE, 0);
  gtk_box_pack_start(GTK_BOX(rdata->rdev_box1), rdata->rdev_box1_addr2, FALSE, FALSE, 0);
  rdata->rdev_label_addr1 = gtk_label_new("addr1");
  rdata->rdev_label_addr2 = gtk_label_new("addr2");
  rdata->rdev_addr_tbox1 = gtk_entry_new();
  rdata->rdev_addr_tbox2 = gtk_entry_new();
  rdata->rdev_stamp_button = gtk_button_new_with_label("Stamp");
  g_signal_connect(rdata->rdev_stamp_button, "clicked", G_CALLBACK(rdev_stamp), rdata);
  if (rdata->config_byte & 0x00000010)
    rdata->rdev_stamp_label = gtk_label_new("Adress is stamped");
  else
    rdata->rdev_stamp_label = gtk_label_new("Adress not stamped");

  gtk_box_pack_start(GTK_BOX(rdata->rdev_box1_addr1), rdata->rdev_label_addr1, FALSE, FALSE, 0);
  gtk_box_pack_start(GTK_BOX(rdata->rdev_box1_addr1), rdata->rdev_addr_tbox1, FALSE, FALSE, 0);
  gtk_box_pack_start(GTK_BOX(rdata->rdev_box1_addr2), rdata->rdev_label_addr2, FALSE, FALSE, 0);
  gtk_box_pack_start(GTK_BOX(rdata->rdev_box1_addr2), rdata->rdev_addr_tbox2, FALSE, FALSE, 0);
  gtk_box_pack_start(GTK_BOX(rdata->rdev_box1), rdata->rdev_stamp_button, FALSE, FALSE, 0);
  gtk_box_pack_start(GTK_BOX(rdata->rdev_box2), rdata->rdev_stamp_label, FALSE, FALSE, 0);
  char tmp[30];
  sprintf(tmp, "%d", (int)rdata->addr1);
  gtk_entry_set_text(GTK_ENTRY(rdata->rdev_addr_tbox1), tmp);
  sprintf(tmp, "%d", (int)rdata->addr2);
  gtk_entry_set_text(GTK_ENTRY(rdata->rdev_addr_tbox2), tmp);

  gtk_widget_show(rdata->rdev_gui);
  gtk_widget_show(rdata->rdev_box1);
  gtk_widget_show(rdata->rdev_box2);
  gtk_widget_show(rdata->rdev_box1_addr1);
  gtk_widget_show(rdata->rdev_box1_addr2);
  gtk_widget_show(rdata->rdev_label_addr1);
  gtk_widget_show(rdata->rdev_label_addr2);
  gtk_widget_show(rdata->rdev_addr_tbox1);
  gtk_widget_show(rdata->rdev_addr_tbox2);
  gtk_widget_show(rdata->rdev_stamp_button);
  gtk_widget_show(rdata->rdev_stamp_label);


  //
  GtkWidget *tmpw = rdata->devbutton;
  gtk_widget_set_sensitive(tmpw, false);
  //
  return;
}

void
rspeed_set_debug(GtkWidget * some, gpointer data)
{
  rspeed_gui_rep *rdata = (rspeed_gui_rep *) data;
  if (debug)
    {
      gtk_label_set_text(GTK_LABEL(rdata->label), "Debug Off");
      debug = 0;
    }
  else
    {
      gtk_label_set_text(GTK_LABEL(rdata->label), "Debug On");
      debug = 1;
    }
}

// Notify screen

void
rnotify_show(GtkWidget * some, gpointer data)
{
  rspeed_gui_rep *rdata = (rspeed_gui_rep *) data;

  rdata->rnotify_gui = gtk_window_new(GTK_WINDOW_TOPLEVEL);
  gtk_window_set_position(GTK_WINDOW(rdata->rnotify_gui), GTK_WIN_POS_CENTER);
  gtk_window_set_resizable(GTK_WINDOW(rdata->rnotify_gui), FALSE);
  gtk_window_set_title(GTK_WINDOW(rdata->rnotify_gui), "Notification list");
  g_signal_connect(rdata->rnotify_gui, "delete-event", G_CALLBACK(delete_event), &rdata->open);
  g_signal_connect(rdata->rnotify_gui, "destroy", G_CALLBACK(destroy), &rdata->open);
  GtkCellRenderer *renderer;
  rdata->rnotify_list = gtk_tree_view_new();
  rdata->rnotify_list_list = gtk_list_store_new(4, G_TYPE_STRING, G_TYPE_UINT, G_TYPE_UINT, G_TYPE_STRING);
  renderer = gtk_cell_renderer_text_new();
  gtk_tree_view_insert_column_with_attributes(GTK_TREE_VIEW(rdata->rnotify_list), -1, "Date", renderer, "text", COL_NAME, NULL);
  renderer = gtk_cell_renderer_text_new();
  gtk_tree_view_insert_column_with_attributes(GTK_TREE_VIEW(rdata->rnotify_list), -1, "Id", renderer, "text", COL_AGE, NULL);
  renderer = gtk_cell_renderer_text_new();
  gtk_tree_view_insert_column_with_attributes(GTK_TREE_VIEW(rdata->rnotify_list), -1, "Prio", renderer, "text", 2, NULL);
  renderer = gtk_cell_renderer_text_new();
  gtk_tree_view_insert_column_with_attributes(GTK_TREE_VIEW(rdata->rnotify_list), -1, "Message", renderer, "text", 3, NULL);

  rdata->rnotify_label = gtk_label_new("");
  rdata->rnotify_box1 = gtk_vbox_new(FALSE, 10);
  gtk_container_add(GTK_CONTAINER(rdata->rnotify_gui), rdata->rnotify_box1);
  gtk_box_pack_start(GTK_BOX(rdata->rnotify_box1), rdata->rnotify_list, FALSE, FALSE, 0);
  gtk_box_pack_start(GTK_BOX(rdata->rnotify_box1), rdata->rnotify_label, FALSE, FALSE, 0);

  gtk_widget_show_all(rdata->rnotify_gui);

  if (!((ProgressData *) rdata->share)->connected)
    {
      gtk_label_set_text(GTK_LABEL(rdata->rnotify_label), "ERROR: Not connected");
      return;
    }
  else
    {
      rdata->sslc.send_data("get-notify", strlen("get-notify"));
      gtk_label_set_text(GTK_LABEL(rdata->rnotify_label), "");
    }
}

// Surveillance screen OVH functions

void
rsurve_screen_change(GtkWidget * some, gpointer data){
  rspeed_gui_rep *rdata = (rspeed_gui_rep *) data;

  gtk_image_set_from_file (GTK_IMAGE(rdata->rsurve_screen), "spg2.jpg");
}


// Surveillance screen

void
rsurve_screen_show(GtkWidget * some, gpointer data)
{
  rspeed_gui_rep *rdata = (rspeed_gui_rep *) data;

  rdata->rsurve_gui = gtk_window_new(GTK_WINDOW_TOPLEVEL);
  gtk_window_set_position(GTK_WINDOW(rdata->rsurve_gui), GTK_WIN_POS_CENTER);
  gtk_window_set_resizable(GTK_WINDOW(rdata->rsurve_gui), FALSE);
  gtk_window_set_title(GTK_WINDOW(rdata->rsurve_gui), "Surveillance Screen");
  g_signal_connect(rdata->rsurve_gui, "delete-event", G_CALLBACK(delete_event), &rdata->open);
  g_signal_connect(rdata->rsurve_gui, "destroy", G_CALLBACK(destroy), &rdata->open);
  // Screen
  rdata->rsurve_box1 = gtk_vbox_new(FALSE, 10);
  rdata->rsurve_screen = gtk_image_new_from_file ("spg1.jpg");
  rdata->rsurve_separator1 = gtk_hseparator_new();
  
  // Cams
  rdata->rsurve_box2 = gtk_hbox_new(FALSE, 10);
  rdata->rsurve_separator2 = gtk_vseparator_new();
  rdata->rsurve_box3 = gtk_vbox_new(FALSE, 10);  
  rdata->rsurve_label1 = gtk_label_new("Cameras");

  // Commands
  rdata->rsurve_box4 = gtk_vbox_new(FALSE, 10);
  rdata->rsurve_separator3 = gtk_vseparator_new();  
  rdata->rsurve_label2 = gtk_label_new("Commands");
  rdata->rsurve_button1 = gtk_button_new_with_label("Change");


  gtk_container_add(GTK_CONTAINER(rdata->rsurve_gui), rdata->rsurve_box1);
  // Screen
  gtk_box_pack_start(GTK_BOX(rdata->rsurve_box1), rdata->rsurve_screen, FALSE, FALSE, 0);
  gtk_box_pack_start(GTK_BOX(rdata->rsurve_box1), rdata->rsurve_separator1, FALSE, FALSE, 0);

  // Cams
  gtk_box_pack_start(GTK_BOX(rdata->rsurve_box1), rdata->rsurve_box2, FALSE, FALSE, 0);
  gtk_box_pack_start(GTK_BOX(rdata->rsurve_box2), rdata->rsurve_box3, FALSE, FALSE, 0);
  gtk_box_pack_start(GTK_BOX(rdata->rsurve_box3), rdata->rsurve_label1, FALSE, FALSE, 0);

  // Commands
  gtk_box_pack_start(GTK_BOX(rdata->rsurve_box2), rdata->rsurve_separator2, FALSE, FALSE, 0);
  gtk_box_pack_start(GTK_BOX(rdata->rsurve_box2), rdata->rsurve_box4, FALSE, FALSE, 0);
  gtk_box_pack_start(GTK_BOX(rdata->rsurve_box4), rdata->rsurve_label2, FALSE, FALSE, 0);
  gtk_box_pack_start(GTK_BOX(rdata->rsurve_box4), rdata->rsurve_button1, FALSE, FALSE, 0);


  g_signal_connect(rdata->rsurve_button1, "clicked", G_CALLBACK(rsurve_screen_change), rdata);

  gtk_widget_show_all(rdata->rsurve_gui);

}

// Real SpeedBusGUI

void
rspeed_gui(gpointer * data)
{
  ProgressData *pdata = (ProgressData *) data;
  rspeed_gui_rep *rdata;
  rdata = (rspeed_gui_rep *) g_malloc(sizeof(rspeed_gui_rep));
  rdata->open = 1;
  rdata->remote = pdata->remote;
  rdata->sslc = pdata->sslc;
  rdata->is_admin = pdata->is_admin;
  pdata->share = (gpointer *) rdata;
  rdata->share = data;
  rdata->scan_lock = 0;
  device_num = 0;
  rdata->box3 = gtk_vbox_new(FALSE, 10);

  // Start the device backend AFTER the serial has been opened
  rdata->backe = init_backend();

  rdata->backe->rdata = rdata;

  rdata->window = gtk_window_new(GTK_WINDOW_TOPLEVEL);
  gtk_window_set_position(GTK_WINDOW(rdata->window), GTK_WIN_POS_CENTER);
  gtk_window_set_resizable(GTK_WINDOW(rdata->window), FALSE);
  g_signal_connect(rdata->window, "delete-event", G_CALLBACK(delete_event), &rdata->open);
  g_signal_connect(rdata->window, "destroy", G_CALLBACK(destroy), &rdata->open);


  rdata->scan_button = gtk_button_new_with_label("Scan");
  g_signal_connect(rdata->scan_button, "clicked", G_CALLBACK(speedbus_unit_scan), rdata);
  rdata->label = gtk_label_new("Linked to bus!");
  rdata->box1 = gtk_vbox_new(FALSE, 1);
  rdata->box2 = gtk_hbox_new(FALSE, 10);
  rdata->box3 = gtk_vbox_new(FALSE, 10);	// Just allocate this temporaryly, because the folowing destroy, wants somthing to destroy... just to make things work
  rdata->box4 = gtk_hbox_new(FALSE, 10);
  rdata->box5 = gtk_hbox_new(FALSE, 10);

  rdata->separator1 = gtk_hseparator_new();
  rdata->pbar = gtk_progress_bar_new();
  rdata->scan_list = new_scan_list();
  rdata->debug_button = gtk_button_new_with_label("Debug");
  rdata->devbutton = gtk_button_new_with_label("Open Device");
  if (rdata->is_admin && rdata->remote)
    rdata->rdev_dev_edit_button = gtk_button_new_with_label("Dev editor");
  if (rdata->is_admin && rdata->remote)
    rdata->rdev_is_admin_button = gtk_button_new_with_label("Settings");
  rdata->rdev_show_notify = gtk_button_new_with_label("Notifications");
  rdata->rdev_surve_screen_button = gtk_button_new_with_label("Surveillance Screen");
  gtk_container_add(GTK_CONTAINER(rdata->window), rdata->box2);
  gtk_box_pack_start(GTK_BOX(rdata->box2), rdata->box1, FALSE, FALSE, 0);
  gtk_box_pack_start(GTK_BOX(rdata->box2), rdata->separator1, FALSE, TRUE, 5);
  gtk_box_pack_start(GTK_BOX(rdata->box1), rdata->scan_button, FALSE, FALSE, 0);
  gtk_box_pack_start(GTK_BOX(rdata->box1), rdata->pbar, FALSE, FALSE, 0);
  gtk_box_pack_start(GTK_BOX(rdata->box1), rdata->scan_list, FALSE, FALSE, 0);
  gtk_box_pack_start(GTK_BOX(rdata->box4), rdata->debug_button, FALSE, FALSE, 0);
  gtk_box_pack_start(GTK_BOX(rdata->box4), rdata->devbutton, TRUE, TRUE, 0);
  if (rdata->is_admin && rdata->remote)
    gtk_box_pack_start(GTK_BOX(rdata->box4), rdata->rdev_dev_edit_button, TRUE, TRUE, 0);
  gtk_box_pack_start(GTK_BOX(rdata->box1), rdata->box4, FALSE, FALSE, 0);
  if (rdata->is_admin && rdata->remote)
    gtk_box_pack_start(GTK_BOX(rdata->box5), rdata->rdev_is_admin_button, FALSE, FALSE, 0);
  gtk_box_pack_start(GTK_BOX(rdata->box5), rdata->rdev_show_notify, FALSE, FALSE, 0);
  gtk_box_pack_start(GTK_BOX(rdata->box1), rdata->box5, FALSE, FALSE, 0);
  gtk_box_pack_start(GTK_BOX(rdata->box1), rdata->rdev_surve_screen_button, FALSE, FALSE, 0);
  gtk_box_pack_start(GTK_BOX(rdata->box1), rdata->label, FALSE, FALSE, 0);
  // Signals
  g_signal_connect(rdata->scan_list, "row-activated", G_CALLBACK(view_onRowActivated), rdata);
  g_signal_connect(rdata->debug_button, "clicked", G_CALLBACK(rspeed_set_debug), rdata);
  g_signal_connect(rdata->devbutton, "clicked", G_CALLBACK(rdev_gui), rdata);
  if (rdata->is_admin && rdata->remote)
    g_signal_connect(rdata->rdev_dev_edit_button, "clicked", G_CALLBACK(rdev_editor), rdata);
  if (rdata->is_admin && rdata->remote)
    g_signal_connect(rdata->rdev_is_admin_button, "clicked", G_CALLBACK(rserver_settings), rdata);
  g_signal_connect(rdata->rdev_show_notify, "clicked", G_CALLBACK(rnotify_show), rdata);
  g_signal_connect(rdata->rdev_surve_screen_button, "clicked", G_CALLBACK(rsurve_screen_show), rdata);
  //
  gtk_widget_show(rdata->box5);
  gtk_widget_show(rdata->box4);
  gtk_widget_show(rdata->debug_button);
  if (rdata->is_admin && rdata->remote)
    gtk_widget_show(rdata->rdev_dev_edit_button);
  if (rdata->is_admin && rdata->remote)
    gtk_widget_show(rdata->rdev_is_admin_button);
  gtk_widget_show(rdata->rdev_show_notify);
  gtk_widget_show(rdata->rdev_surve_screen_button);
  gtk_widget_show(rdata->box2);
  gtk_widget_show(rdata->box1);
  gtk_widget_show(rdata->label);
  gtk_widget_show(rdata->pbar);
  gtk_widget_show(rdata->scan_button);
  gtk_widget_show(rdata->scan_list);
  gtk_widget_show(rdata->window);


  // Startup Speedbus Backgruond thread
  if (pdata->remote)
    {
      pthread_create(&rdata->printr, NULL, &client_handler, (void *)rdata);
    }
  else
    {
      pthread_create(&rdata->printr, NULL, &print_ser_gui, (void *)rdata);
    }
  // I put it here, because the thread must be started AFTER the serialport has been opened


  // Fill dev list
  speedbus_fill_devlist(rdata);
  //

}


static void
trayConnect(GtkMenuItem * item, gpointer data)
{
  ProgressData *pdata = (ProgressData *) data;
  pdata->open = 1;
  gtk_widget_show(GTK_WIDGET(pdata->window));
  gtk_window_deiconify(GTK_WINDOW(pdata->window));
}


static void
trayMainUI(GtkMenuItem * item, gpointer data)
{
  ProgressData *pdata = (ProgressData *) data;
  if (pdata->share != NULL)
    {
      rspeed_gui_rep *rdata = (rspeed_gui_rep *) (pdata->share);
      rdata->open = 1;
      gtk_widget_show(GTK_WIDGET(rdata->window));
      gtk_window_deiconify(GTK_WINDOW(rdata->window));
    }
}

static void
trayExit(GtkMenuItem * item, gpointer user_data)
{
  printf("exit");
  gtk_main_quit();
}

static void
trayIconPopup(GtkStatusIcon * status_icon, guint button, guint32 activate_time, gpointer popUpMenu)
{

  gtk_menu_popup(GTK_MENU(popUpMenu), NULL, NULL, gtk_status_icon_position_menu, status_icon, button, activate_time);
}

static void
trayIconActivated(GObject * trayIcon, gpointer data)
{
  ProgressData *pdata = (ProgressData *) data;
  if (pdata->share == NULL)
    {
      if (pdata->open)
	{
	  pdata->open = 0;
	  gtk_widget_hide(GTK_WIDGET(pdata->window));
	}
      else
	{
	  pdata->open = 1;
	  gtk_widget_show(GTK_WIDGET(pdata->window));
	}
    }
  else
    {
      rspeed_gui_rep *rdata = (rspeed_gui_rep *) (pdata->share);
      if (rdata->open)
	{
	  rdata->open = 0;
	  gtk_widget_hide(GTK_WIDGET(rdata->window));
	}
      else
	{
	  rdata->open = 1;
	  gtk_widget_show(GTK_WIDGET(rdata->window));
	}
    }
}

bool
show_ok(const gchar * msg, const gchar * title, gpointer data, GtkMessageType type)
{
  ProgressData *pdata = (ProgressData *) data;
  GtkWidget *dialog;
  dialog = gtk_message_dialog_new(GTK_WINDOW(pdata->window), GTK_DIALOG_DESTROY_WITH_PARENT, type, GTK_BUTTONS_OK, "%s", msg);
  gtk_window_set_title(GTK_WINDOW(dialog), title);
  gtk_dialog_run(GTK_DIALOG(dialog));
  gtk_widget_destroy(dialog);
}

bool
show_yes_no(const char *msg, const gchar * title, gpointer data, GtkMessageType type)
{
  ProgressData *pdata = (ProgressData *) data;
  GtkWidget *dialog;
  dialog = gtk_message_dialog_new(GTK_WINDOW(pdata->window), GTK_DIALOG_DESTROY_WITH_PARENT, type, GTK_BUTTONS_YES_NO, "%s", msg);
  gtk_window_set_title(GTK_WINDOW(dialog), title);
  int resp = gtk_dialog_run(GTK_DIALOG(dialog));
  gtk_widget_destroy(dialog);
  if (resp == GTK_RESPONSE_YES)
    return 1;
  return 0;
}

static bool
set_autoconnect(GtkWidget * button, gpointer data)
{
  ProgressData *pdata = (ProgressData *) data;

  if (gtk_toggle_button_get_active(GTK_TOGGLE_BUTTON(pdata->auto_connect)))
    {
      gtk_toggle_button_set_active(GTK_TOGGLE_BUTTON(pdata->save_login), TRUE);
      gtk_widget_set_sensitive(pdata->save_login, FALSE);
    }
  else
    {
      gtk_widget_set_sensitive(pdata->save_login, TRUE);
    }
  config_t cfg;
  config_setting_t *auto_login, *password;
  config_init(&cfg);
  config_read_file(&cfg, "main.cfg");
  auto_login = config_lookup(&cfg, "auto_login");
  password = config_lookup(&cfg, "password");
  if (!auto_login)
    auto_login = config_setting_add(config_root_setting(&cfg), "auto_login", CONFIG_TYPE_BOOL);
  if (!password)
    password = config_setting_add(config_root_setting(&cfg), "password", CONFIG_TYPE_STRING);

  config_setting_set_bool(auto_login, gtk_toggle_button_get_active(GTK_TOGGLE_BUTTON(pdata->auto_connect)));
  if (gtk_toggle_button_get_active(GTK_TOGGLE_BUTTON(pdata->auto_connect)))
    {
      config_setting_set_string(password, (char *)gtk_entry_get_text(GTK_ENTRY(pdata->login_pwd)));
    }
  else
    {
      config_setting_set_string(password, "");
    }

  config_write_file(&cfg, "main.cfg");
  config_destroy(&cfg);

}

static bool
set_save_login(GtkWidget * button, gpointer data)
{
  ProgressData *pdata = (ProgressData *) data;
  config_t cfg;
  config_setting_t *host, *username;
  config_init(&cfg);
  config_read_file(&cfg, "main.cfg");
  host = config_lookup(&cfg, "server_host");
  username = config_lookup(&cfg, "username");

  if (!host)
    host = config_setting_add(config_root_setting(&cfg), "server_host", CONFIG_TYPE_STRING);
  if (!username)
    username = config_setting_add(config_root_setting(&cfg), "username", CONFIG_TYPE_STRING);
  if (gtk_toggle_button_get_active(GTK_TOGGLE_BUTTON(pdata->save_login)))
    {
      config_setting_set_string(host, (char *)gtk_entry_get_text(GTK_ENTRY(pdata->server_adress)));
      config_setting_set_string(username, (char *)gtk_entry_get_text(GTK_ENTRY(pdata->login_name)));
    }
  else
    {
      config_setting_set_string(host, "");
      config_setting_set_string(username, "");

    }

  config_write_file(&cfg, "main.cfg");
  config_destroy(&cfg);
}


static bool
connect_to_server(GtkWidget * button, gpointer data)
{
  ProgressData *pdata = (ProgressData *) data;
  set_save_login(NULL, data);
  set_autoconnect(NULL, data);

  if (pdata->connected)
    {
      if (pdata->share != NULL)
	pthread_cancel(((rspeed_gui_rep *) pdata->share)->printr);

      gtk_label_set_text(GTK_LABEL(pdata->label1), "Disconnected");
      pdata->sslc.sslfree();
      pdata->connected = 0;
      gtk_button_set_label(GTK_BUTTON(pdata->connect_button), "Connect to server");
      return 1;
    }
  // Write to config file
  if (pdata->save_con)
    {
      char tmp[50];
      int auto_open = 0;
      int auto_login = 0;
      pdata->share = NULL;
      config_init(&pdata->main_cfg);
      if (!config_read_file(&pdata->main_cfg, "main.cfg"))
	{
	  memset(tmp, 0x00, 50);
	  sprintf(tmp, "ls|grep \"main.cfg\"");
	  FILE *pipe = popen(tmp, "r");
	  if (fgets(tmp, 50, pipe) == NULL)
	    {
	      printf("No File main.cfg\n");
	    }
	  else
	    {
	      printf("Line %d: %s\n", config_error_line(&pdata->main_cfg), config_error_text(&pdata->main_cfg));
	    }

	}
      config_destroy(&pdata->main_cfg);
    }
  //

  struct hostent *he;
  char *adr;
  char *usr;
  char *pwd;
  char login[400];
  usr = (char *)gtk_entry_get_text(GTK_ENTRY(pdata->login_name));
  pwd = (char *)gtk_entry_get_text(GTK_ENTRY(pdata->login_pwd));
  adr = (char *)gtk_entry_get_text(GTK_ENTRY(pdata->server_adress));
  he = gethostbyname(adr);
  sprintf(login, "%s\n%s", usr, pwd);

  // Fixed reconnect, so the connection not is reset on popup messages...
  int do_retry = 0;
do_reconnect:
  if (!pdata->sslc.sslsocket(inet_ntoa(*(struct in_addr *)he->h_addr), 306))
    {
      gtk_label_set_text(GTK_LABEL(pdata->label1), "Connection Failed");
      //pdata->sslc.sslfree(); Do not free, the connection is off anyway
      return 0;
    }
  if (!pdata->sslc.loadssl())
    {
      gtk_label_set_text(GTK_LABEL(pdata->label1), "SSL Handshake Failed");
      pdata->sslc.sslfree();
      return 0;
    }
  char host_entry[200];
  char finger[100];
  char host[100];
  strncpy(host, adr, 100);
  pdata->sslc.get_ssl_finger(finger);
  sprintf(host_entry, "Host: %s | Fingerprint: %s", host, finger);
  int sig = pdata->sslc.find_known_hosts(host_entry);
  if (sig < 1)
    {
      if (sig == -1)
	{
	  if (show_yes_no
	    ("POTENSIAL MIME ATTACK!!!!\nDANGERUS!!! Do NOT proced if your not werry sure that the certificate has been replaced!!!\nDo you want to proceed?",
	      "Alert!", pdata, GTK_MESSAGE_ERROR))
	    {
	      if (show_yes_no("Add to known hosts? (yes/no): ", "Question", pdata, GTK_MESSAGE_QUESTION))
		{
		  if (!pdata->sslc.add_known_hosts(host_entry))
		    {
		      show_ok("Unable to write to file, known_hosts", "Info", pdata, GTK_MESSAGE_WARNING);
		    }
		}
	    }
	  else
	    {
	      gtk_label_set_text(GTK_LABEL(pdata->label1), "Connection Cancled");
	      pdata->sslc.sslfree();
	      return 0;
	    }
	}
      if (sig == 0)
	{
	  if (show_yes_no("The host where not recognized, add to known hosts? (yes/no): ", "Question", pdata, GTK_MESSAGE_QUESTION))
	    {
	      if (!pdata->sslc.add_known_hosts(host_entry))
		{
		  show_ok("Unable to write to file, known_hosts", "Info", pdata, GTK_MESSAGE_WARNING);
		}
	    }
	}
    }
  else if (sig == 2)
    {
      show_ok("Found the CA fingerprint in known_host, addning new record with this IP", "Info", pdata, GTK_MESSAGE_INFO);
      if (!pdata->sslc.add_known_hosts(host_entry))
	show_ok("Unable to write to file, known_hosts", "Info", pdata, GTK_MESSAGE_WARNING);
    }


  if (pdata->sslc.send_data(login, strlen(login)))
    {
      char data[RECV_MAX];
      int len;
      if (len = pdata->sslc.recv_data(data))
	{
	  if (strcmp(data, "Login Failed\n") == 0)
	    {
	      gtk_label_set_text(GTK_LABEL(pdata->label1), "Login failed");
	      pdata->sslc.sslfree();
	      return 0;
	    }
	  if (strcmp(data, "root\n") == 0)
	    {
	      pdata->is_admin = 1;
	      printf("Got admin!\n");
	    }
	  if (strcmp(data, "user\n") == 0)
	    {
	      pdata->is_admin = 0;
	      printf("I am not admin :/\n");
	    }
	}
      else
	{
	  gtk_label_set_text(GTK_LABEL(pdata->label1), "Connection reset");
	  if (do_retry < 1)
	    {
	      goto do_reconnect;
	      do_retry++;
	    }
	  pdata->sslc.sslfree();

	}
    }
  gtk_button_set_label(GTK_BUTTON(pdata->connect_button), "Disconnect");
  pdata->connected = 1;
  gtk_label_set_text(GTK_LABEL(pdata->label1), "Connected!");
  gtk_widget_hide(GTK_WIDGET(pdata->window));
  pdata->open = 0;
  pdata->remote = 1;
  if (pdata->share == NULL || ((rspeed_gui_rep *) pdata->share)->open != 1)
    {
      rspeed_gui((gpointer *) pdata);
    }
  else
    {
      if (pdata->is_admin != ((rspeed_gui_rep *) pdata->share)->is_admin)
	{
	  pthread_cancel(((rspeed_gui_rep *) pdata->share)->printr);
	  gtk_widget_destroy(GTK_WIDGET(((rspeed_gui_rep *) pdata->share)->window));
	  rspeed_gui((gpointer *) pdata);
	}
      else
	{
	  pthread_create(&((rspeed_gui_rep *) pdata->share)->printr, NULL, &client_handler, pdata->share);
	}
      ((rspeed_gui_rep *) pdata->share)->sslc = pdata->sslc;

    }
  return 1;
  //pdata->sslc.send_data("hej");

}

void
sig_handler(int sig)
{
  const int maxbtsize = 50;
  int btsize;
  void *bt[maxbtsize];
  char **strs = 0;
  int i = 0;
  btsize = backtrace(bt, maxbtsize);
  strs = backtrace_symbols(bt, btsize);
  char send_stack[4096];
  sprintf(send_stack, "dbg=");
  for (i = 0; i < btsize; i += 1)
    {
      sprintf(send_stack, "%s%d.) %s\n", send_stack, i, strs[i]);
    }
  sprintf(send_stack, "%s&platform=pc-gui", send_stack);
  std::string message;
  request("speedbus.org", "/debug.php", send_stack, message);
  free(strs);
  signal(sig, &sig_handler);
}


int
main(int argc, char *argv[])
{
  /*
   * GtkWidget is the storage type for widgets 
   */
  ProgressData *pdata;
  GtkWidget *button1;
  GtkWidget *box1;
  GtkWidget *box2;
  GtkWidget *box3;
  GtkWidget *box4;
  pdata = (ProgressData *) g_malloc(sizeof(ProgressData));

  //
  signal(SIGSEGV, &sig_handler);
  //

  char tmp[50];
  int auto_open = 0;
  int auto_login = 0;
  pdata->share = NULL;
  config_init(&pdata->main_cfg);
  if (!config_read_file(&pdata->main_cfg, "main.cfg"))
    {
      memset(tmp, 0x00, 50);
      sprintf(tmp, "ls|grep \"main.cfg\"");
      FILE *pipe = popen(tmp, "r");
      if (fgets(tmp, 50, pipe) == NULL)
	{
	  printf("No File main.cfg\n");
	}
      else
	{
	  printf("Line %d: %s\n", config_error_line(&pdata->main_cfg), config_error_text(&pdata->main_cfg));
	}
      config_destroy(&pdata->main_cfg);

    }
  else
    {

      config_lookup_int(&pdata->main_cfg, "auto_open", &auto_open);	// Fetch width  
      if (auto_open)
	auto_open = 1;

    }

  pdata->open = 1;
  /*
   * This is called in all GTK applications. Arguments are parsed
   * * from the command line and are returned to the application. 
   */
  gtk_init(&argc, &argv);

  /*
   * create a new window 
   */
  pdata->window = gtk_window_new(GTK_WINDOW_TOPLEVEL);
  gtk_window_set_title(GTK_WINDOW(pdata->window), "Select Spb interface");

  pdata->trayIcon = gtk_status_icon_new_from_file("spb.png");
  //set popup menu for tray icon
  pdata->menu = gtk_menu_new();
  pdata->menuItemConnect = gtk_menu_item_new_with_label("Set Interface");
  pdata->menuItemMainUI = gtk_menu_item_new_with_label("Spb UI");
  pdata->menuItemExit = gtk_menu_item_new_with_label("Exit");
  g_signal_connect(G_OBJECT(pdata->menuItemConnect), "activate", G_CALLBACK(trayConnect), pdata);
  g_signal_connect(G_OBJECT(pdata->menuItemMainUI), "activate", G_CALLBACK(trayMainUI), pdata);
  g_signal_connect(G_OBJECT(pdata->menuItemExit), "activate", G_CALLBACK(trayExit), pdata);
  gtk_menu_shell_append(GTK_MENU_SHELL(pdata->menu), pdata->menuItemConnect);
  gtk_menu_shell_append(GTK_MENU_SHELL(pdata->menu), pdata->menuItemMainUI);
  gtk_menu_shell_append(GTK_MENU_SHELL(pdata->menu), pdata->menuItemExit);
  gtk_widget_show_all(pdata->menu);
  //set tooltip
  gtk_status_icon_set_tooltip(pdata->trayIcon, "Speedbus UI");
  //connect handlers for mouse events
  g_signal_connect(GTK_STATUS_ICON(pdata->trayIcon), "activate", GTK_SIGNAL_FUNC(trayIconActivated), pdata);
  g_signal_connect(GTK_STATUS_ICON(pdata->trayIcon), "popup-menu", GTK_SIGNAL_FUNC(trayIconPopup), pdata->menu);
  gtk_status_icon_set_visible(pdata->trayIcon, TRUE);	//set icon initially invisible

  pdata->menuBar = gtk_menu_bar_new();
  pdata->menuItemTopLvl = gtk_menu_item_new_with_label("Menu");
  gtk_menu_shell_append(GTK_MENU_SHELL(pdata->menuBar), pdata->menuItemTopLvl);

  pdata->mainMenu = gtk_menu_new();
  gtk_menu_item_set_submenu(GTK_MENU_ITEM(pdata->menuItemTopLvl), pdata->mainMenu);
  pdata->mainMenuItemExit = gtk_menu_item_new_with_label("Quit");
  g_signal_connect(G_OBJECT(pdata->mainMenuItemExit), "activate", G_CALLBACK(trayExit), NULL);
  gtk_menu_shell_append(GTK_MENU_SHELL(pdata->mainMenu), pdata->mainMenuItemExit);


  //g_signal_connect (G_OBJECT (window), "window-state-event", G_CALLBACK (window_state_event), trayIcon);
  //gtk_container_add (GTK_CONTAINER (pdata->window), pdata->menuBar);


  /*
   * When the window is given the "delete-event" signal (this is given
   * * by the window manager, usually by the "close" option, or on the
   * * titlebar), we ask it to call the delete_event () function
   * * as defined above. The data passed to the callback
   * * function is NULL and is ignored in the callback function. 
   */
  g_signal_connect(pdata->window, "delete-event", G_CALLBACK(delete_event), &pdata->open);

  /*
   * Here we connect the "destroy" event to a signal handler.  
   * * This event occurs when we call gtk_widget_destroy() on the window,
   * * or if we return FALSE in the "delete-event" callback. 
   */
  g_signal_connect(pdata->window, "destroy", G_CALLBACK(destroy), &pdata->open);

  /*
   * Sets the border width of the window. 
   */
  gtk_container_set_border_width(GTK_CONTAINER(pdata->window), 10);

  pdata->label3 = gtk_label_new("Use serial port");

  button1 = gtk_button_new_with_label("Open TTY");


  g_signal_connect(button1, "clicked", G_CALLBACK(open_tty_button), pdata);

  /*
   * This will cause the window to be destroyed by calling
   * * gtk_widget_destroy(window) when "clicked".  Again, the destroy
   * * signal could come from here, or the window manager. 
   */
  //  g_signal_connect_swapped (button, "clicked",
  //                        G_CALLBACK (gtk_widget_destroy),
  //                        window);

  box1 = gtk_vbox_new(FALSE, 10);

  pdata->combo = gtk_combo_new();

  // Declar checkboxes erly
  pdata->auto_connect = gtk_check_button_new_with_label("Save pass(auto connect)");
  pdata->save_login = gtk_check_button_new_with_label("Save user and host");
  //


  pdata->label2 = gtk_label_new("Use server");

  box4 = gtk_hbox_new(FALSE, 10);
  pdata->server_label = gtk_label_new("Addr: ");
  pdata->server_adress = gtk_entry_new();
  gtk_box_pack_start(GTK_BOX(box4), pdata->server_label, FALSE, FALSE, 0);
  gtk_box_pack_start(GTK_BOX(box4), pdata->server_adress, FALSE, FALSE, 0);

  const char *str_tmp;
  int alogin = 0;
  if (config_lookup_string(&pdata->main_cfg, "server_host", &str_tmp))
    {
      gtk_entry_set_text(GTK_ENTRY(pdata->server_adress), str_tmp);
      alogin++;
      if (strlen(str_tmp) > 0)
	gtk_toggle_button_set_active(GTK_TOGGLE_BUTTON(pdata->save_login), TRUE);
    }


  box2 = gtk_hbox_new(FALSE, 10);
  pdata->login_name = gtk_entry_new();
  pdata->label_name = gtk_label_new("User: ");
  gtk_box_pack_start(GTK_BOX(box2), pdata->label_name, FALSE, FALSE, 0);
  gtk_box_pack_start(GTK_BOX(box2), pdata->login_name, FALSE, FALSE, 0);

  if (config_lookup_string(&pdata->main_cfg, "username", &str_tmp))
    {
      gtk_entry_set_text(GTK_ENTRY(pdata->login_name), str_tmp);
      alogin++;
      if (strlen(str_tmp) > 0)
	gtk_toggle_button_set_active(GTK_TOGGLE_BUTTON(pdata->save_login), TRUE);
    }


  box3 = gtk_hbox_new(FALSE, 10);
  pdata->login_pwd = gtk_entry_new();
  gtk_entry_set_visibility(GTK_ENTRY(pdata->login_pwd), FALSE);
  pdata->label_pwd = gtk_label_new("Pass: ");
  gtk_box_pack_start(GTK_BOX(box3), pdata->label_pwd, FALSE, FALSE, 0);
  gtk_box_pack_start(GTK_BOX(box3), pdata->login_pwd, FALSE, FALSE, 0);

  if (config_lookup_string(&pdata->main_cfg, "password", &str_tmp))
    {
      gtk_entry_set_text(GTK_ENTRY(pdata->login_pwd), str_tmp);
    }
  //
  g_signal_connect(pdata->auto_connect, "clicked", G_CALLBACK(set_autoconnect), pdata);
  g_signal_connect(pdata->save_login, "clicked", G_CALLBACK(set_save_login), pdata);
  //

  if (config_lookup_bool(&pdata->main_cfg, "auto_login", &auto_login))
    {
      if (auto_login)
	gtk_toggle_button_set_active(GTK_TOGGLE_BUTTON(pdata->auto_connect), TRUE);

      if (auto_login && alogin == 2)
	{
	  auto_login = 1;
	}
      else
	{
	  auto_login = 0;
	}
    }



  pdata->connect_button = gtk_button_new_with_label("Connect to server");

  g_signal_connect(pdata->connect_button, "clicked", G_CALLBACK(connect_to_server), pdata);


  pdata->label1 = gtk_label_new("");



  /*
   * This packs the button into the window (a gtk container). 
   */
  gtk_container_add(GTK_CONTAINER(pdata->window), box1);

  gtk_box_pack_start(GTK_BOX(box1), pdata->label3, FALSE, FALSE, 0);
  gtk_box_pack_start(GTK_BOX(box1), pdata->menuBar, FALSE, FALSE, 0);
  gtk_box_pack_start(GTK_BOX(box1), pdata->combo, FALSE, FALSE, 0);
  gtk_box_pack_start(GTK_BOX(box1), button1, FALSE, FALSE, 0);
  gtk_box_pack_start(GTK_BOX(box1), pdata->label2, FALSE, FALSE, 0);
  gtk_box_pack_start(GTK_BOX(box1), box4, FALSE, FALSE, 0);
  gtk_box_pack_start(GTK_BOX(box1), box2, FALSE, FALSE, 0);
  gtk_box_pack_start(GTK_BOX(box1), box3, FALSE, FALSE, 0);
  gtk_box_pack_start(GTK_BOX(box1), pdata->save_login, FALSE, FALSE, 0);
  gtk_box_pack_start(GTK_BOX(box1), pdata->auto_connect, FALSE, FALSE, 0);
  gtk_box_pack_start(GTK_BOX(box1), pdata->connect_button, FALSE, FALSE, 0);
  gtk_box_pack_start(GTK_BOX(box1), pdata->label1, FALSE, FALSE, 0);
  gtk_widget_show_all(box1);

  //gtk_widget_show(box1);

  //gtk_widget_show (pdata->combo);

  tty_to_combo(pdata->combo);

  //gtk_widget_show (pdata->label1);

  /*
   * The final step is to display this newly created widget. 
   */
  /*
   * gtk_widget_show (button1);
   * 
   * gtk_widget_show (pdata->label2);
   * 
   * gtk_widget_show (box2);
   * gtk_widget_show (box3);
   * gtk_widget_show (box4);
   * gtk_widget_show (pdata->connect_button);
   * gtk_widget_show (pdata->label3);
   * gtk_widget_show (pdata->login_name);
   * gtk_widget_show (pdata->label_name);
   * gtk_widget_show (pdata->label_pwd);
   * gtk_widget_show (pdata->login_pwd);
   * gtk_widget_show (pdata->server_adress);
   * gtk_widget_show (pdata->server_label);
   */
  /*
   * and the window 
   */
  if (auto_open)
    {
      if (!open_tty_button(NULL, pdata))
	{
	  gtk_widget_show(pdata->window);
	}
      goto main_end;
    }

  if (auto_login)
    {
      if (!connect_to_server(NULL, pdata))
	{
	  gtk_widget_show(pdata->window);
	}
      goto main_end;
    }

  gtk_widget_show_all(pdata->window);

main_end:
  /*
   * All GTK applications must have a gtk_main(). Control ends here
   * * and waits for an event to occur (like a key press or
   * * mouse event). 
   */
  gtk_main();

  return 0;
}
