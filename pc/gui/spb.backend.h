#ifndef __BACKE_H_INCLUDED__
#define __BACKE_H_INCLUDED__

#define MAX_EVENT    50
#define MAX_ROWS     20
#define MAX_WIDGETS  50
#define MAX_BUFFER   200 // Make this 200 to allow the server to save the printf pattern in there ;)x
#define MAX_VARIABLE 50
#define MAX_DEVIDS   50
#define MAX_OPS      50


typedef struct _main_backend {
  int       devids; // The number off loaded devices
  int       device_id[MAX_DEVIDS];
  char      daddr1[MAX_DEVIDS];
  char      daddr2[MAX_DEVIDS];
  char      event_exec[MAX_DEVIDS][MAX_EVENT][MAX_BUFFER];
  int       event_data[MAX_DEVIDS][MAX_EVENT][MAX_BUFFER];
  int       event_data1[MAX_DEVIDS][MAX_EVENT][MAX_BUFFER];
  int       event_data2[MAX_DEVIDS][MAX_EVENT][MAX_BUFFER];
  bool      event_exist[MAX_DEVIDS][MAX_EVENT];
  char      event_variable[MAX_DEVIDS][MAX_VARIABLE];
  int       var_ops[MAX_OPS][4];
  int       var_opsc;
  /*
    [1]: Variable
    [2]: Device id
    [3]: Type
    [4]: Second arg
  */

  void *rdata; // Share variable, set to the gui:s rdata struct
   
} main_backend;


int backend_exec_ops(main_backend *backe, int array_num, int var_num, int var_val, bool from_gui);
bool backend_load_var_ops(main_backend *backe, config_t *cfg, char *cname, int opt_devid);
bool backend_set_variable(main_backend *backe, int devid, int var_num, char var_val);
char backend_get_variable(main_backend *backe, int array_num, int var_num);
bool backend_exec(main_backend * backe, int event, int devid, short vspace);
bool backend_run_event(main_backend *backe,int array_num,int event, short vspace);
bool backend_load_events(main_backend *backe);
void backend_check_update_addr(main_backend *backe, int devid);
main_backend* init_backend();

void device_add(void *data,char addr1, char addr2,int devid);

#endif
