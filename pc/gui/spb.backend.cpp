#include <libconfig.h>
#include <cstring>
#include <stdio.h>
#include <stdlib.h>
#include <dirent.h>



#include "spb.backend.h"
#include "usb.hid.h"
#ifndef __SPEEDBLIB_H_INCLUDED__
#define __SPEEDBLIB_H_INCLUDED__
#include "../protocoll/speedblib.cpp"
#endif


// Device Scan list. Declare this global, so that the backend can reach the devices
short device_num;
int device_id[MAX_DEVIDS];
char device_addr[MAX_DEVIDS][8];
//


void
device_add(main_backend * backe, char addr1, char addr2, int devid)
{
  //rspeed_gui_rep *rdata = (rspeed_gui_rep *)data;  
  char name[7];
  sprintf(name, "%d.%d", (unsigned char)addr1, (unsigned char)addr2);

  for (int i = 0; i < device_num; i++)
    {
      if (device_id[i] == devid)
	{
	  strcpy(device_addr[i], name);
	  goto device_add_end;
	}
    }
  device_id[device_num] = devid;
  strcpy(device_addr[device_num], name);
  device_num++;
device_add_end:

  for (int i = 0; i < backe->devids; i++)
    {
      if (backe->device_id[i] == devid)
	{			// Device id is found in the MAIN device list                                                                                                       
	  backe->daddr1[i] = (unsigned char)addr1;
	  backe->daddr2[i] = (unsigned char)addr2;
	}
    }
  return;
}

void
device_rm(void *data, int devid)
{
  int dev_hop = 0;
  for (int i = 0; i < device_num; i++)
    {
      if (device_id[i] == devid)
	dev_hop++;
      if(dev_hop > 0){
	strncpy(device_addr[i], device_addr[i+dev_hop], 8);
      	device_id[i] = device_id[i+dev_hop];
      }
    }
  device_num -= dev_hop;
}

main_backend *
init_backend()
{
  main_backend *backe;
  backe = (main_backend *) malloc(sizeof(main_backend));
  backe->devids = 0;
  backe->var_opsc = 0;
  DIR *dp;
  struct dirent *dirp;
  if ((dp = opendir(BACKEND_DIR "usb/")) == NULL)
    {
      printf("No dir usb/\n");
      return backe;
    }

  char arg[100];
  memset(arg, 0x00, 100);
  while ((dirp = readdir(dp)) != NULL)
    {
      int len = strlen(dirp->d_name);
      int pos = (int)(strstr(dirp->d_name, ".hid") - dirp->d_name);
      if (pos > 0 && pos + 4 == len)
	{
	  sprintf(arg, BACKEND_DIR "usb/%s", dirp->d_name);
	  if (debug)
	    printf("Loaded: %s\n", arg);
	  open_usb_hid(backe, arg);
	}
    }
  closedir(dp);

  // Zero Params and Events
  for(int i=0; i<MAX_DEVIDS; i++){
    for(int ie=0; ie<MAX_EVENT; ie++){
      backe->event_exist[i][ie] = false;
    }
    for(int ip=0; ip<MAX_PARAMETER; ip++){
      backe->parameter_exist[i][ip] = false;
    }
  }
  return backe;
}

bool
backend_set_variable(main_backend * backe, int devid, int var_num, char var_val)
{
  for (int i = 0; i < backe->devids; i++)
    {
      if (backe->device_id[i] == devid)
	{			// Device id is found in the backend device list
	  backe->event_variable[i][var_num - 257] = var_val;
	  return 1;
	}
    }
  return 0;
}

char
backend_get_variable(main_backend * backe, int array_num, int var_num)
{
  if (var_num > 255 && var_num < (255 + MAX_VARIABLE))
    return backend_exec_ops(backe, array_num, var_num, backe->event_variable[array_num][var_num - 257], 0);
  else
    return 0;
}

int
backend_exec_ops(main_backend * backe, int array_num, int var_num, int var_val, bool from_gui)
{

  for (int i = 0; i < backe->var_opsc; i++)
    {
      if (backe->device_id[array_num] == backe->var_ops[i][2])
	{			// ceck so the device id is the same
	  if (var_num == backe->var_ops[i][1])
	    {			// check so the variable num is the same
	      int svar_num = backe->var_ops[i][4];
	      if(svar_num <= 255 || svar_num > (255 + MAX_VARIABLE))
		svar_num = 0;

	      switch (backe->var_ops[i][3])
		{
		case 0:	// Shift down with second arg
		  var_val >>= backe->var_ops[i][4];
		  break;
		case 1:	// Invert
		  var_val = ~var_val;
		  break;
		case 2:
		  // Subtract with second arg
		  var_val -= backe->var_ops[i][4];
		  break;
		case 3:
		  // Add with second arg
		  var_val += backe->var_ops[i][4];
		  break;
		case 4:
		  // Shift up
		  var_val <<= backe->var_ops[i][4];
		  break;
		case 5:
		  // And
		  var_val &= backe->var_ops[i][4];
		  break;
		case 6:
		  // Or
		  var_val |= backe->var_ops[i][4];
		  break;
#ifdef IS_GUI
		case 7:
		  // Add with second arg
		  var_val += get_variable_gui(backe->rdata, backe->var_ops[i][4], from_gui);
		  break;
		case 8:
		  // Sub with second arg
		  var_val -= get_variable_gui(backe->rdata, backe->var_ops[i][4], from_gui);
		  break;
#endif
		case 9:	// Shift down with second arg
		  var_val >>= (unsigned char)backe->event_variable[array_num][svar_num - 257];
		  break;
		case 10:
		  // Subtract with second arg
		  var_val -= (unsigned char)backe->event_variable[array_num][svar_num - 257];
		  break;
		case 11:
		  // Add with second arg
		  var_val += (unsigned char)backe->event_variable[array_num][svar_num - 257];
		  break;
		case 12:
		  // Shift up
		  var_val <<= (unsigned char)backe->event_variable[array_num][svar_num - 257];
		  break;
		case 13:
		  // And
		  var_val &= (unsigned char)backe->event_variable[array_num][svar_num - 257];
		  break;
		case 14:
		  // Or
		  var_val |= (unsigned char)backe->event_variable[array_num][svar_num - 257];
		  break;
		case 15:
		  // Multiply
		  var_val *= backe->var_ops[i][4];
		  break;
		case 16:
		  // Divide
		  var_val /= backe->var_ops[i][4];
		  break;
		case 17:
		  // Multiply
		  var_val *= (unsigned char)backe->event_variable[array_num][svar_num - 257];
		  break;
		case 18:
		  // Divide
		  var_val /= (unsigned char)backe->event_variable[array_num][svar_num - 257];
		  break;
		case 19:
		  // 16bit below zero, for AM2302 devices. (If the most significant bit is 1, then the value is below zero)
		  if(var_val & 0b1000000000000000)
		    var_val = (var_val & 0xFF) * -1;
		  break;
		case 20:
		  // Divide, get reminder second arg = variable
		  var_val %= (unsigned char)backe->event_variable[array_num][svar_num - 257];
		  break;
		case 21:
		  // Divide with second arg, get reminder
		  var_val %= backe->var_ops[i][4];
		  break;
		case 22:
		  // Make sure var_val is above 0, if varval = -12 then convert to 12
		  if(var_val < 0)
		    var_val *= -1;
		  break;
		case 23:
		  // Make sure var_val is below 0, if varval = 12 then convert to -12
		  if(var_val > 0)
		    var_val *= -1;
		  break;



		}
	    }
	}
    }
  return var_val;
}

bool
backend_exec(main_backend * backe, int event, int devid, short vspace)
{
  for (int i = 0; i < device_num; i++)
    {
      if (device_id[i] == devid)
	{			// Device id is found in the MAIN device list
	  for (int i = 0; i < backe->devids; i++)
	    {
	      if (backe->device_id[i] == devid)
		{		// Device id is found in the backend device list
		  backend_run_event(backe, i, event, vspace);
		  return 1;
		}
	    }
	  backend_load_backend(backe);
	  for (int i = 0; i < backe->devids; i++)
	    {			// Check again if the device really was added
	      if (backe->device_id[i] == devid)
		{		// Device id is found in the backend device list                                                                                         
		  backend_run_event(backe, i, event, vspace);
		  return 1;
		}
	    }
	}
    }
  return 0;
}

bool
backend_run_event(main_backend * backe, int array_num, int event, short vspace)
{
  if (!backe->event_exist[array_num])
    return 0;

  if (strcmp(backe->event_exec[array_num][event], "print") == 0)
    {
      printf("%s\n", (char *)backe->event_data[array_num][event]);
    }

  if (strcmp(backe->event_exec[array_num][event], "send") == 0)
    {
      int len = 7 + backe->event_data[array_num][event][0];
      char getdevs[MAX_BUFFER + 7] = { backe->daddr1[array_num], backe->daddr2[array_num],
	addr1, addr2, 0x03, 0x01
      };

      for (int ii = 0; ii < len - 7; ii++)
	{			// Len-7 = rdata->spb_widget_event_data[rdata->spb_widget_event[i]][0] 
	  if (backe->event_data[array_num][event][ii + 1] > 256)
	    {
	      if (backe->event_data[array_num][event][ii + 1] < 257 + MAX_VARIABLE)
		{
		  if (vspace == 0)
		    {		// vspace=0 is that the variables should be loaded from backend devices
		      getdevs[ii + 6] = backend_get_variable(backe, array_num, backe->event_data[array_num][event][ii + 1]);
		    }
		  if (vspace == 1)
		    {		// vspace=1 is that the variables should be loaded from gui space
#ifdef IS_GUI
		      getdevs[ii + 6] = get_variable_gui((void *)backe->rdata, backe->event_data[array_num][event][ii + 1], 1);
#endif
		    }
		}
	    }
	  else
	    {
	      getdevs[ii + 6] = backe->event_data[array_num][event][ii + 1];
	    }
	}
      getdevs[len - 1] = 0x00;
#ifdef IS_GUI
      m_send(backe->rdata, getdevs, len);
#else
      send(getdevs, len);
#endif
    }

  if (strcmp(backe->event_exec[array_num][event], "getvars") == 0)
    {
      int len = 7 + backe->event_data[array_num][event][0];
      char getdevs[MAX_BUFFER + 7] = { backe->daddr1[array_num], backe->daddr2[array_num],
	addr1, addr2, 0x03, 0x01
      };
      for (int ii = 0; ii < len - 7; ii++)
	{			// Len-7 = rdata->spb_widget_event_data[rdata->spb_widget_event[i]][0] 
	  if (backe->event_data[array_num][event][ii + 1] > 256)
	    {
	      if (backe->event_data[array_num][event][ii + 1] < 257 + MAX_VARIABLE)
		{
		  if (vspace == 0)
		    {		// vspace=0 is that the variables should be loaded from backend devices
		      getdevs[ii + 6] = backend_get_variable(backe, array_num, backe->event_data[array_num][event][ii + 1]);
		    }
		  if (vspace == 1)
		    {		// vspace=1 is that the variables should be loaded from gui space
#ifdef IS_GUI
		      getdevs[ii + 6] = get_variable_gui((void *)backe->rdata, backe->event_data[array_num][event][ii + 1], 1);
#endif
		    }
		}
	    }
	  else
	    {
	      getdevs[ii + 6] = backe->event_data[array_num][event][ii + 1];
	    }
	}
      getdevs[len - 1] = 0x00;
#ifdef IS_GUI
      m_send(backe->rdata, getdevs, len);
#else
      send(getdevs, len);
#endif

    }

}

bool
backend_load_var_ops(main_backend * backe, config_t * cfg, char *cname, int opt_devid)
{
  config_setting_t *setting;
  setting = config_lookup(cfg, "operations");
  if (setting != NULL)
    {
      int count = config_setting_length(setting);
      int i;
      for (i = 0; i < count; ++i)
	{
	  config_setting_t *book = config_setting_get_elem(setting, i);

	  int variable;
	  int type;
	  int second_arg;
	  int devid;
	  if (!
	    (config_setting_lookup_int
	      (book, "variable", &variable))
	    || !(config_setting_lookup_int(book, "type", &type)) || !(config_setting_lookup_int(book, "second_arg", &second_arg)))
	    {
	      printf("You seems to have missed 'variable','device_id','type' or 'second_arg' at operation nr %d, in file %s\n", i, cname);
	      continue;
	    }
	  int var_opsc = backe->var_opsc++;
	  backe->var_ops[var_opsc][1] = variable;
	  if (config_setting_lookup_int(book, "device_id", &devid))
	    {
	      backe->var_ops[var_opsc][2] = devid;
	    }
	  else
	    {
	      backe->var_ops[var_opsc][2] = opt_devid;
	    }
	  backe->var_ops[var_opsc][3] = type;
	  backe->var_ops[var_opsc][4] = second_arg;
	}

    }

}

bool
backend_load_backend(main_backend * backe)
{
  config_t cfg;
  config_setting_t *setting;
  config_init(&cfg);


  char tmp[50];
  memset(tmp, 0x00, 50);
  for (int i = backe->devids; i < device_num; i++)
    {
      int devid = device_id[i];
      sprintf(tmp, BACKEND_DIR "devs/%d.spb", devid);
      //printf("devs/%d.spb",devid);

      /*
       * Read the file. If there is an error, report it and exit. 
       */
      if (!config_read_file(&cfg, tmp))
	{
	  memset(tmp, 0x00, 50);
	  sprintf(tmp, "ls " BACKEND_DIR "devs/|grep %d.spb", devid);
	  FILE *pipe = popen(tmp, "r");
	  if (fgets(tmp, 50, pipe) == NULL)
	    {
	      printf("No File devs/%d.spb", devid);
	      continue;
	    }
	  else
	    {
	      printf("Line %d: %s\n", config_error_line(&cfg), config_error_text(&cfg));
	      config_destroy(&cfg);
	      continue;
	    }
	}
      //if(debug)
      printf("Sucess loaded %d.spb\n", devid);

      int devids = backe->devids++;
      backe->device_id[devids] = devid;
      int daddr1;
      int daddr2;
      sscanf(device_addr[i], "%d.%d", &daddr1, &daddr2);
      backe->daddr1[devids] = daddr1;
      backe->daddr2[devids] = daddr2;


      // Load ops
      backend_load_var_ops(backe, &cfg, tmp, devid);
      //


      // Load events
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
	      if (event > MAX_EVENT || strlen(type) > MAX_BUFFER)
		continue;

	      backe->event_exist[devid][event] = true;
	      strcpy(backe->event_exec[devids][event], type);

	      if (strcmp(type, "print") == 0)
		{
		  const char *data;
		  if (config_setting_lookup_string(book, "data", &data))
		    {
		      if (strlen(data) < MAX_BUFFER)
			memcpy(backe->event_data[devids][event], data, strlen(data) + 1);
		    }
		  else
		    memset(backe->event_data[devids][event], 0x00, MAX_BUFFER);
		}
	      if (strcmp(type, "send") == 0)
		{
		  memset(backe->event_data[devids][event], 0x00, MAX_BUFFER);
		  config_setting_t *data_t;
		  data_t = config_setting_get_member(book, "data");
		  if (data_t != NULL)
		    {
		      int count = config_setting_length(data_t);
		      backe->event_data[devids][event][0] = count;
		      for (int i = 0; i < count; ++i)
			{
			  int data = config_setting_get_int_elem(data_t, i);
			  backe->event_data[devids][event][i + 1] = data;
			}
		    }
		}
	      if (strcmp(type, "getvars") == 0)
		{
		  memset(backe->event_data[devids][event], 0x00, MAX_BUFFER);
		  config_setting_t *data_t, *var_num_t, *at_byte_t;
		  var_num_t = config_setting_get_member(book, "var_num");
		  at_byte_t = config_setting_get_member(book, "at_byte");
		  data_t = config_setting_get_member(book, "data");
		  if (data_t != NULL && var_num_t != NULL && at_byte_t != NULL)
		    {
		      int count = config_setting_length(data_t);
		      backe->event_data[devids][event][0] = count;
		      for (int i = 0; i < count; ++i)
			{
			  int data = config_setting_get_int_elem(data_t, i);
			  backe->event_data[devids][event][i + 1] = data;
			}
		      count = config_setting_length(var_num_t);
		      backe->event_data1[devids][event][0] = count;
		      count = config_setting_length(at_byte_t);
		      backe->event_data2[devids][event][0] = count;
		      for (int i = 0; i < count; ++i)
			{
			  int var_num = config_setting_get_int_elem(var_num_t, i);
			  int at_byte = config_setting_get_int_elem(at_byte_t, i);
			  backe->event_data1[devids][event][i + 1] = var_num;
			  backe->event_data2[devids][event][i + 1] = at_byte;
			}
		    }
		}

	      if (strcmp(type, "log") == 0)
		{
		  memset(backe->event_data[devids][event], 0x00, MAX_BUFFER);
		  config_setting_t *data_t, *var_num_t;
		  var_num_t = config_setting_get_member(book, "var_num");
		  data_t = config_setting_get_member(book, "data");
		  const char *ptnpattern;
		  if (data_t != NULL && var_num_t != NULL && config_setting_lookup_string(book, "log_str", &ptnpattern))
		    {
		      int count = config_setting_length(data_t);
		      backe->event_data[devids][event][0] = count;
		      for (int i = 0; i < count; ++i)
			{
			  int data = config_setting_get_int_elem(data_t, i);
			  backe->event_data[devids][event][i + 1] = data;
			}
		      count = config_setting_length(var_num_t);
		      backe->event_data1[devids][event][0] = count;
		      strncpy((char *)(backe->event_data1[devids][event] + 1), ptnpattern, MAX_BUFFER);
		      for (int i = 0; i < count; ++i)
			{
			  int var_num = config_setting_get_int_elem(var_num_t, i);
			  backe->event_data2[devids][event][i + 1] = var_num;
			}
		    }
		}


	    }
	}


      // Parameters

      setting = config_lookup(&cfg, "spb.parameters");
      if (setting != NULL)
	{
	  int count = config_setting_length(setting);
	  for (int i = 0; i < count; ++i)
	    {
	      config_setting_t *book = config_setting_get_elem(setting, i);
	      int param;
	      int type;
	      int readonly;
	      const char *descr;
	      const char *unit;

	      if (!(config_setting_lookup_int(book, "param", &param)) || !(config_setting_lookup_int(book, "type", &type))
		  || !(config_setting_lookup_string(book, "descr", &descr)) || !(config_setting_lookup_bool(book, "readonly", &readonly)))
		continue;
	      if (param > MAX_PARAMETER || strlen(descr) > MAX_BUFFER )
		continue;
	      
	      
	      backe->parameter_exist[devids][param] = true;
	      backe->parameter_type[devids][param] = type;
	      strcpy(backe->parameter_descr[devids][param], descr);
	      backe->parameter_readonly[devids][param] = readonly;
	      
	      if(!config_setting_lookup_string(book, "unit", &unit)){
		if(!strlen(unit) > MAX_BUFFER){
		  strcpy(backe->parameter_unit[devids][param], unit);
		}else
		  strcpy(backe->parameter_unit[devids][param], ""); 
	      }else
		strcpy(backe->parameter_unit[devids][param], "");
	      
	      
	      
	    }
	}

    }
}

bool
backend_exec_get_param(main_backend * backe, int param, int devid)
{
  for (int i = 0; i < backe->devids; i++)
    {
      if (backe->device_id[i] == devid)
	{			// Device id is found in the MAIN device list
	  if(param < MAX_PARAMETER && backe->parameter_exist[i][param] == true){
	    int len = 9;
	    char getdevs[MAX_BUFFER] = { backe->daddr1[i], backe->daddr2[i], addr1, addr2, 0x03, 0x00, 0x04, param, 0x00 };
	    printf("Senddnign\n");
#ifdef IS_GUI
	    m_send(backe->rdata, getdevs, len);
#else
	    send(getdevs, len);
#endif
	  }
	}
    }
}
