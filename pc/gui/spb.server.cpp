

#include <execinfo.h>
#include <signal.h>
#include "ssl.socket.h"
#include <libconfig.h>
#include <SerialStream.h>
#include <iostream>
#ifndef __SPEEDBLIB_H_INCLUDED__
#define __SPEEDBLIB_H_INCLUDED__
#include "../protocoll/speedblib.cpp"
#endif
#include <openssl/md5.h>

#define BACKEND_DIR "/etc/spbserver/"
#include "spb.backend.cpp"
#include "http_post.cpp"

#define MAX_USERS 100
#define MAX_LOG_SIZE 200 // Maximum numbers of chars to send to log, at once.
#define MAX_NOTIFY_STACK 10
#define MAX_NOTIFY_SIZE 200 // Maximum size of the notify message
#define SERVER_LOG_FILE "/var/log/spbserver.log"
#define SERVER_CONFIG_FILE "server.cfg"
#define SERVER_CONFIG_DIR "/etc/spbserver/"
#define SERVER_CONFIG_URI "/etc/spbserver/server.cfg"
#define SERVER_NOTIFY_FILE "server.notify"
#define SERVER_DEVCACHE_FILE "server.devcache"

int socket_user_id[MAX_LISTEN];
char users[MAX_USERS][2][MAX_LOGIN_TEXT];
bool is_admin[MAX_USERS];
int userc=0;

typedef struct _print_seri {
  sslserver *server;
  config_t *server_cfg;
  char ctty[200];
  /// Device Scan list. Declare this global, so that the backend can reach the devices
  short device_num;
  int device_id[30];
  char device_addr[30][8];
  //
  /// Device notification messages
  int notify_nr;
  char notify[MAX_NOTIFY_STACK][MAX_NOTIFY_SIZE+50];
  //
  main_backend *backe;
} print_seri;


// Pre allocated functions 
bool add_user(config_t *server_cfg, char *user, char *pass, bool is_admin_s);
bool del_user(config_t *server_cfg, char *user);
bool mod_user(config_t *server_cfg, char *user, char *user_n, char *pass_n, bool is_admin_s);
bool set_tty(print_seri *serial_p, const char *tty);
bool spb_write_log(const char *w_log);
bool spb_write_notify(print_seri *serial_p, const char *w_log, int prio);
//



bool file_exists(const char * filename)
{
  if (FILE * file = fopen(filename, "r"))
    {
      fclose(file);
      return true;
    }
  return false;
}

static void get_vars_load(void *data, char *p_data, int counter){
  // Because the log event handling, you need to filter out broadcast if you do not want them

  print_seri *serial_p = (print_seri*)data;
  for(int i=0; i <serial_p->backe->devids;i++){

    if(serial_p->backe->daddr1[i] == p_data[2] && serial_p->backe->daddr2[i] == p_data[3]){ // Device id is found in the MAIN device list

      for(int ii=0; ii < MAX_EVENT; ii++){
	
	if((serial_p->backe->event_exist[ii]) && strcmp(serial_p->backe->event_exec[i][ii],"getvars") == 0){
	  int count = (unsigned char)serial_p->backe->event_data[i][ii][0];
	  for(int iii=0; iii <count; iii++){
	    if((unsigned char)serial_p->backe->event_data[i][ii][1+iii] == (unsigned char)p_data[6+iii]){
	      if((iii+1) == count){
		count = (unsigned char)serial_p->backe->event_data1[i][ii][0];
		for(int iiii=0; iiii <count; iiii++){
		  backend_set_variable(serial_p->backe, serial_p->backe->device_id[i], serial_p->backe->event_data1[i][ii][iiii+1], (unsigned char)p_data[serial_p->backe->event_data2[i][ii][iiii+1]+6]);
		}
	      }
	    }else{
	      break;
	    }
	  }
	}
	if((serial_p->backe->event_exist[ii]) && strcmp(serial_p->backe->event_exec[i][ii],"log") == 0){
	  int count = (unsigned char)serial_p->backe->event_data[i][ii][0];
	  for(int iii=0; iii <count; iii++){
	    if((unsigned char)serial_p->backe->event_data[i][ii][1+iii] == (unsigned char)p_data[6+iii]){
	      if((iii+1) == count){
		char e_arg[MAX_LOG_SIZE];
		memcpy(e_arg, serial_p->backe->event_data1[i][ii]+1, MAX_LOG_SIZE);
		char print[MAX_LOG_SIZE];
		sprintf(print,e_arg,backend_get_variable(serial_p->backe, i, serial_p->backe->event_data2[i][ii][1]),
			backend_get_variable(serial_p->backe, i, serial_p->backe->event_data2[i][ii][2]),
			backend_get_variable(serial_p->backe, i, serial_p->backe->event_data2[i][ii][3]));
		spb_write_log(print);
		spb_write_notify(serial_p, print, 3);
	      }
	    }
	    
	  }
	}
      }
    }
  }
}

void device_file_update(print_seri *serial_p){
  FILE *file; 
  file = fopen(SERVER_CONFIG_DIR SERVER_DEVCACHE_FILE,"w+");
  for(int i=0; i<serial_p->device_num; i++){
    fprintf(file,"%d %s\n", serial_p->device_id[i], serial_p->device_addr[i]);
  }
  fclose(file);
}

void device_file_init(print_seri *serial_p){
  FILE *file = fopen (SERVER_CONFIG_DIR SERVER_DEVCACHE_FILE, "r" );
  if (file != NULL)
    {
      char line [128]; /* or other suitable maximum line size */
      while (fgets(line, sizeof line, file) != NULL) /* read a line */
	{
	  char addr[128]; int addr1, addr2, devid;
	  if(sscanf(line, "%d %s\n", &devid, addr) == 2){
	    sscanf(addr, "%d.%d", &addr1, &addr2);
	    device_add((void*)NULL, addr1, addr2, devid);
	    serial_p->device_id[serial_p->device_num] = devid;
	    strcpy(serial_p->device_addr[serial_p->device_num],addr);
	    serial_p->device_num++;
	  }
	}
      fclose (file);
    }
}

void device_add(print_seri *serial_p,char addr1, char addr2,int devid){
  // Device add for the backend
  device_add((void*)NULL, addr1, addr2, devid);
  //
  char name[7];
  sprintf(name,"%d.%d",(unsigned char)addr1,(unsigned char)addr2);
  if(debug)
    std::cerr << "\n" << serial_p->device_num << ":" << name << "\n";

    for(int i=0; i<serial_p->device_num; i++){
      if(serial_p->device_id[i] == devid){
	strcpy(serial_p->device_addr[i],name);
	goto device_add_end;
      }
    }
  serial_p->device_id[serial_p->device_num] = devid;
  strcpy(serial_p->device_addr[serial_p->device_num],name);
  serial_p->device_num++;
 device_add_end:
  device_file_update(serial_p);
  return;
}

void *print_ser_backend(void *ptr){
  print_seri *serial_p = (print_seri*)ptr;
  int counter = 0;
  bool e = 0;
  bool justcap = 0;
  char data[100];

  while(1){
    // Keep reading data from serial port and print it to the screen.
    //
    if(got_resp)
      usleep(500000);
    else
      usleep(5000);

    if(!file_exists(serial_p->ctty)){
      // Inform clients that serial interface is down
      for(int i=0; i<MAX_LISTEN; i++){
	if(serial_p->server->session_open[i]){
	  serial_p->server->send_data(i, "info Serial Interface Down!\n", 
			   strlen("info Serial Interface Down!\n"));
	}
      }
      //
      wtime();
      printf("Serial port is closed!\n");
      while(1){
	sleep(3);
	set_tty(serial_p, NULL);
       	if(serial_port.IsOpen()){
	  // Inform clients that serial interface is up again
	  wtime();
	  printf("Serial port %s is open!\n", serial_p->ctty);
	  for(int i=0; i<MAX_LISTEN; i++){
	    if(serial_p->server->session_open[i]){
	      serial_p->server->send_data(i, "info Serial Interface Up Again!\n", 
					  strlen("info Serial Interface Up Again!\n"));
	    }
	  }
	  //
	  break;
	}
      }
    }
    while(serial_port.rdbuf()->in_avail() > 0)
      {
	char next_byte;
	serial_port.get(next_byte);
	if(next_byte == 0x7e && e == 1){
	  //bool loopback = memcmp(data, tx_data, counter);
	  unescape(data,&counter); // Unescape the incomming package, check rfc1662 for escape rules
	  if(crcstrc(data,counter) && counter > 5){ // Min packet length 5                                                                                                         
	    if((unsigned char)data[0] == addr1 && (unsigned char)data[1] == addr2 && ((unsigned char)data[5] == 1 && (unsigned char)data[6] != 0 )){ // |IMPORTANT to check that
	      usleep(10000);                                                                                                                         // | there not is a response
	      send_response(data[2],data[3]); // Send response at server side, so IF one unit is fucking with us, the whole bus will not be ocupied with like 10 repeats | package.
	    }
	    // Got a great package! Sending it away!
	    // prepare package
	    
	    if(counter<95){
	      if(((unsigned char)data[0] == addr1 && (unsigned char)data[1] == addr2) || ((unsigned char)data[0] == 0xFF && (unsigned char)data[1] == 0xFF)){
		// Store devices that sends device aknowledge
		if((unsigned char)data[0] == addr1 && (unsigned char)data[1] == addr2 && (unsigned char)data[6] == 1){
		  if(counter < 11){ // If counter is less than 11, there is a usual 0x01, "ping" package,return
		    break;
		  }
		  int devid=0;
		  for(int i=0; i<counter-10; i++){ // Run this backwards to get the bytes right
		    devid <<= 8;
		    devid += data[i+7];    
		  }
		  device_add(serial_p,data[2],data[3],devid);
		}
		//
		// Run actions from the config files
		//
		get_vars_load(serial_p,data,counter);
		//

		// Send it away to the clients
		char prepare[RECV_MAX];
		sprintf(prepare, "send ");
		if(data[0] != data[1] != 0xFF) // Change the adress so there either 0:0 for unicast, to client, och FF:FF to broadcast to client
		  data[0] = data[1] = 0;
		memcpy(prepare+5, data, counter);

		for(int i=0; i<MAX_LISTEN; i++){
		  if(serial_p->server->session_open[i]){
		    serial_p->server->send_data(i, prepare, counter+5);    
		  }
		}
		//

	      }
	    }else{
	      wtime();
	      printf("ERROR PACKAGE TO BIGG\n");}
	    if((unsigned char)data[6] == 0){
	      got_resp = 1;
	    }
	    //                                                                                                                                                         
	    justcap = 1;
	    e=0;
	  }else{
	    if(verbose){wtime(); std::cerr << "ERROR: recived damaged package\n";}
	      counter = 0;
	    memset(data,0x00,100);
	  }}
	if(e && next_byte != 0x7e){
	  data[counter] = next_byte;
	  counter++;
	}
	if(next_byte == 0x7e && e == 0 && justcap == 0){
	  counter = 0;
	  e=1;
	}
	if(counter > 99){
	  counter = 0;
	  if(debug){
	    std::cerr << "Killed package longer than 99bytes" << std::endl;
	  }
	}
	if(debug)
	  std::cerr << std::hex << static_cast<int>(next_byte & 0xFF) << " ";
	usleep(40);
	justcap = 0;
      }
  }}

void md5sum(char *input){ // Important to preallocate the variable with >32 chars
    unsigned char result[16];
    MD5((unsigned char*)input, strlen(input), result);
    input[0] = '\0';
    for(int i=0; i <16; i++) {
      sprintf(input, "%s%02x",input,result[i]);
    }
}

bool spb_inalize_notify(print_seri *serial_p){
  char tmp_notify[MAX_NOTIFY_STACK][MAX_NOTIFY_SIZE+50];
  short read_counter = 0;
  FILE *file; 
  file = fopen(SERVER_CONFIG_DIR SERVER_NOTIFY_FILE,"r");
  if(file){
  char line [MAX_NOTIFY_SIZE+50]; /* or other suitable maximum line size */
  while (fgets(line, sizeof(line), file) != NULL) /* read a line */
    {
      read_counter++;
    }
  serial_p->notify_nr = read_counter;  
  int start;
  if(read_counter > 10)
    start = read_counter - 10;
  else
    start = 0;
  fclose (file);
  file = fopen(SERVER_CONFIG_DIR SERVER_NOTIFY_FILE,"r");
  int linec = 0;
  int line_c = 0;
  while (fgets(line, sizeof(line), file) != NULL) /* read a line */
    {
      if(linec >= start && line_c < 10){
	char *line_end = strchr(line, '\n');
	*line_end = '\0';
	strncpy(tmp_notify[line_c], line, MAX_NOTIFY_SIZE+50);
      line_c++;
      }
      linec++;
    }
  fclose (file);
  line_c--;
  int write_c = 0;
  while (write_c <= read_counter && write_c < 10 && line_c > -1){
    strncpy(serial_p->notify[line_c], tmp_notify[write_c], MAX_NOTIFY_SIZE+50);
    write_c++; line_c--;
  }
  }else{
    serial_p->notify_nr = 0;
  }
}


bool spb_write_notify(print_seri *serial_p, const char *w_log, int prio){
  serial_p->notify_nr += 1;
  for(int i = MAX_NOTIFY_STACK-2; i >= 0; i--){
    strncpy(serial_p->notify[i+1], serial_p->notify[i], MAX_NOTIFY_SIZE+50);
  }
  sprintf(serial_p->notify[0], "%d %d %d %s", (int)time(0), serial_p->notify_nr, prio, w_log);
  FILE *file; 
  file = fopen(SERVER_CONFIG_DIR SERVER_NOTIFY_FILE ,"a+");
  fprintf(file,"%d %d %d %s\n", (int)time(0), serial_p->notify_nr, prio, w_log);
  fclose(file);
  
  char tmp_send[MAX_NOTIFY_SIZE+50];
  sprintf(tmp_send, "notifya %d %d %d %s\n", (int)time(0), serial_p->notify_nr, prio, w_log); 
  for(int i=0; i<MAX_LISTEN; i++){
    if(serial_p->server->session_open[i]){
      serial_p->server->send_data(i, tmp_send, strlen(tmp_send));    
    }
  }

}

bool spb_write_log(const char *w_log){
  
  time_t rawtime;
  struct tm * timeinfo;
  char strtime[20];
  time (&rawtime);
  timeinfo = localtime (&rawtime);
  strftime (strtime,20,"%b %d %X",timeinfo);

  FILE *file; 
  file = fopen( SERVER_LOG_FILE,"a+");

  fprintf(file,"%s %s\n", strtime, w_log);
  fclose(file);

}

bool spb_exec(print_seri *serial_p, int listnum, char *data, int len){
  /*------- DATA EXCHANGE - Receive message and send reply. -------*/
  /* Receive data from the SSL client */
  int err = 0;
  if(!serial_p->server->session_open[listnum]){

    //  printf ("Received %d chars:\n%s\n", len, data);

  char user[MAX_LOGIN_TEXT*2], pass[MAX_LOGIN_TEXT*2];
  sscanf(data, "%s\n%s", user, pass);
  md5sum(pass);
  sprintf(data, "%s:%s", user, pass);
  // sleep(1); Wait for further acess limitations, cant just sleep the whole fucking server -.-
  for(int i=0; i < userc; i++){
    char tmp[MAX_LOGIN_TEXT*2+1];
    sprintf(tmp,"%s:%s",users[i][1],users[i][2]);
    
    //printf("%s:%s\n", user, pass);
    if(strncmp(data,tmp,len) == 0){
      socket_user_id[listnum] = i;
      if(is_admin[i]){
	err = serial_p->server->send_data(listnum, "root\n", 
			       strlen("root\n"));
    }else{                          
      err = serial_p->server->send_data(listnum, "user\n", 
			     strlen("user\n"));
    }
      usleep(10000); // This is a delay, to make sure that the gui is ready
      if(serial_p->device_num>0){
      for(int i=0; i<serial_p->device_num; i++){
	char tmp[200];
	char titlex[50];
	const char *title;
	config_t cfg;
	config_init(&cfg);
	config_setting_t *cfg_e;
	sprintf(tmp, BACKEND_DIR "devs/%d.spb", serial_p->device_id[i]);
	if(config_read_file(&cfg, tmp))
	  {
	    //printf(BACKEND_DIR "devs/%d.spb\n", serial_p->device_id[i]);
	    config_lookup_string(&cfg, "name", &title);
	    strncpy(titlex,title,50);
	    sprintf(tmp, "devlistadd %s %d %s\n", serial_p->device_addr[i], serial_p->device_id[i], titlex);
	    //printf("devlistadd %s %d %s\n", serial_p->device_addr[i], serial_p->device_id[i], titlex);
	    serial_p->server->send_data(listnum, tmp, strlen(tmp));
	   
	    char tmpeve[200];
	    cfg_e = config_lookup(&cfg, "spb.events");
	    if(cfg_e != NULL)
	      {
		int count = config_setting_length(cfg_e);	  
		for(int i2 = 0; i2 < count; ++i2)
		  {
		    int evenr;
		    const char *descr;
		    const char *type;

		    config_setting_t *cfg_ee = config_setting_get_elem(cfg_e, i2);
		    if(!(config_setting_lookup_string(cfg_ee, "type", &type)) || !(config_setting_lookup_int(cfg_ee, "event", &evenr)))
		      continue;
		    if(strcmp(type, "send") != 0)
		      continue;
		    if(config_setting_lookup_string(cfg_ee, "descr", &descr)){
		      char tmpstr[150];
		      if(strlen(descr) >= 150)
			strncpy(tmpstr, descr, 150);
		      else
			strcpy(tmpstr, descr);

		      sprintf(tmpeve, "eveadd %d %d %s\n", serial_p->device_id[i], evenr, tmpstr);
		      //printf("eveadd %d %d %s\n", serial_p->device_id[i], evenr, tmpstr);
		      //printf("eveadd %d %d %s\n", serial_p->device_id[i], evenr, descr);
		      serial_p->server->send_data(listnum, tmpeve, strlen(tmpeve));
		    }else{
		      sprintf(tmpeve, "eveadd %d %d\n", serial_p->device_id[i], evenr);
		      //printf("eveadd %d %d\n", serial_p->device_id[i], evenr);
		      serial_p->server->send_data(listnum, tmpeve, strlen(tmpeve));
		    }
		  }
	      }
	  }
      }

      }
      sprintf(tmp, "notifc %d\n", serial_p->notify_nr);
      serial_p->server->send_data(listnum, tmp, strlen(tmp));
      serial_p->server->send_data(listnum, "udevlist \n", strlen("udevlist \n"));

      serial_p->server->session_open[listnum] = 1;
      wtime();
      printf("User: (%s) logged in from IP: (%s)\n", user, serial_p->server->client_ip[listnum]);

      return 1;}
  }
  err = serial_p->server->send_data(listnum, "Login Failed\n", 
		  strlen("Login Failed\n"));
  serial_p->server->sslfree(listnum);
    return 0;
  /* Keep komunication */
  //this->sslfree(listnum);
  }else{
    // Ordinary binary send, just output the data that is sent to it.
    if(strncmp(data, "send", 4) == 0){
      if(!serial_port.IsOpen()){
	serial_p->server->send_data(listnum, "info Cant send, serial port is down\n", 
				    strlen("info Cant send, serial port is down\n"));
      }
      //      printf("Received send with %d chars: \n", len-5);  
      char send_data[RECV_MAX];
      memcpy(send_data, data+5, len-5);
      //for(int i=0; i<len-5; i++){
      //printf("%02X ",(0xFF&send_data[i]));
      //}
      //printf("\n");
      send_data[2] = addr1; // Hardcode in the dev addr, so the send respons wont get hong up, due to the send response is done at server side.
      send_data[3] = addr2;

      send(send_data,len-5);
      serial_p->server->send_data(listnum, "good\n", 
				  strlen("good\n"));
    }
    // Event executions, output things on the bus based on the conf files, like "execute event 123"
    if(strncmp(data, "evexec", 6) == 0){
      if(!serial_port.IsOpen()){
	serial_p->server->send_data(listnum, "info Cant send, serial port is down\n", 
				    strlen("info Cant send, serial port is down\n"));
      }
      //      printf("Received send with %d chars: \n", len-5);  
      int devid, event;
      sscanf(data, "evexec %d %d ", &devid, &event);
      char *varr = strchr(data, '[');
      if(varr){
	varr++;
	int varnr, varval;
	while(strchr(varr, ',') || strchr(varr, ']')){	 
	  if(sscanf(varr, "%d=%d,", &varnr, &varval) == 2 || sscanf(varr, "%d=%d]", &varnr, &varval) == 2){
	    if(varnr > 255 && varnr <= (257 + MAX_VARIABLE) && varval < 256 && varval >= 0)
	      //printf("Setting variable: %d=%d\n", varnr, varval);
	     backend_set_variable(serial_p->backe, devid, varnr, (char)varval);
	  }
	  varr = strchr(varr, ',');
	  if(!varr){
	    break;
	  }
	  varr++;
	}
      }

      if(!backend_exec(serial_p->backe, event, devid, 0)){
	serial_p->server->send_data(listnum, "info Error when runing event, devid in devlist?\n", 
				    strlen("info Error when runing event, devid in devlist?\n"));
      }else{
	serial_p->server->send_data(listnum, "good\n", 
				    strlen("good\n"));
      }
    
    }

    if(strncmp(data, "ping ", 5) == 0){
      char reply[250], tmp_ping[200];
      if(len > 205)
	strncpy(tmp_ping, data+5, 199);
      else
	strncpy(tmp_ping, data+5, len-4);

      sprintf(reply, "ping %s", tmp_ping);
      serial_p->server->send_data(listnum, reply, 
				  strlen(reply));
    }

    if(strncmp(data, "notifyc", 7) == 0){
      char reply[50];
      sprintf(reply, "notifyc %d\n", serial_p->notify_nr);
      serial_p->server->send_data(listnum, reply, 
				  strlen(reply));
    }
    if(strncmp(data, "get-notify", 10) == 0){
      char reply[MAX_NOTIFY_SIZE+51];
      int dst;
      if(serial_p->notify_nr < MAX_NOTIFY_STACK)
	dst = serial_p->notify_nr;
      else
	dst = MAX_NOTIFY_STACK;
      for(int i=0; i < dst; i++){
	sprintf(reply, "notifya %s\n", serial_p->notify[i]);
	serial_p->server->send_data(listnum, reply, 
				    strlen(reply));
      }
	serial_p->server->send_data(listnum, "good\n", 
				    strlen("good\n"));
    }

    // To make the cewd abit more easy read, i just make an is admin if statment here, so, the 
    // cewd below in this function is ONLY executed, IF the user is admin, else, return.
    if(!is_admin[socket_user_id[listnum]])
      return 0;
    if(strncmp(data, "adduser", 7) == 0){
      char user[RECV_MAX], pass[RECV_MAX]; // RECV_MAX is to big in 99.9% of all times, but a small price for preveting BOF
      int is_admin;
      sscanf(data,"adduser %s %s %d\n", user, pass, &is_admin);
      if(add_user(serial_p->server_cfg, user, pass, is_admin)){
	serial_p->server->send_data(listnum, "sinfo User added!\n", 
			 strlen("sinfo User added!\n"));
	goto send_userlist;
      }else{
	serial_p->server->send_data(listnum, "sinfo Failed to add user\n", 
			 strlen("sinfo Failed to add user\n"));
      }
    }
    if(strncmp(data, "moduser", 7) == 0){
      char moduser[RECV_MAX], user[RECV_MAX], pass[RECV_MAX]; // RECV_MAX is to big in 99.9% of all times, but a small price for preveting BOF
      int is_admin;
      sscanf(data,"moduser %s \t %d \t %s \t %s\n", moduser, &is_admin, user, pass);
      if(strlen(pass) < 2){
	if(pass[0] == 3){
	  pass[0] = '\0'; 
	}
      }
      if(mod_user(serial_p->server_cfg, moduser, user, pass, is_admin)){
	serial_p->server->send_data(listnum, "sinfo User modded!\n", 
			 strlen("sinfo User modded!\n"));
	goto send_userlist;
      }else{
	serial_p->server->send_data(listnum, "sinfo Failed to mod user\n", 
			 strlen("sinfo Failed to mod user\n"));
      }
      
    }
    if(strncmp(data, "deluser", 7) == 0){
      char user[RECV_MAX], pass[RECV_MAX]; // RECV_MAX is to big in 99.9% of all times, but a small price for preveting BOF
      int is_admin;
      sscanf(data,"deluser %s\n", user);
      if(del_user(serial_p->server_cfg, user)){
	serial_p->server->send_data(listnum, "sinfo User deleted!\n", 
			 strlen("sinfo User deleted!\n"));
	goto send_userlist;
      }else{
	serial_p->server->send_data(listnum, "sinfo Failed to deleted user\n", 
			 strlen("sinfo Failed to deleted user\n"));
      }
    }
    if(strncmp(data, "userlist", 8) == 0){
    send_userlist:
      for(int i = 0; i < MAX_USERS; i++){
	if(users[i][1][0] != '\0'){
	  char send[(MAX_LOGIN_TEXT*2)+1+9];
	  sprintf(send, "userlist %s %d\n", users[i][1], is_admin[i]);
	  printf(send, "userlist %s %d\n", users[i][1], is_admin[i]);
	  serial_p->server->send_data(listnum,send,strlen(send));  
	}
      }
    }
    if(strncmp(data, "get-tty", 7) == 0){
      char ctty[100]; const char *tty;
      if(config_lookup_string(serial_p->server_cfg, "tty", &tty)){
	if(strlen(tty) < 95){
	  sprintf(ctty, "ctty %s\n", tty);
	  serial_p->server->send_data(listnum,ctty,strlen(ctty));
	}
      }
      char path[100]; FILE * pipe;
      sprintf(path,"find /dev/ -name %s", tty);
      pipe = popen(path, "r"); // Get USB tty:S for list, chose one to use at speedbus
      char ttyt[100];
      while(fgets(ttyt,sizeof(ttyt),pipe) > 0){
	char *nlptr;
	nlptr = strchr(ttyt, '\n');
	*nlptr = '\0';
	char send[(MAX_LOGIN_TEXT*2)+1+9];
	sprintf(send, "ttylist %s\n", ttyt);
	printf(send, "ttylist %s\n", ttyt);
	serial_p->server->send_data(listnum,send,strlen(send));  
      }
    }
    if(strncmp(data, "ttylist ", 8) == 0){
      char pattern[RECV_MAX];
      sscanf(data,"ttylist %s\n", pattern);
      if(strchr(pattern ,'|') || strchr(pattern,'&') || strchr(pattern,'`') || strchr(pattern,'$'))
	return 0;
      char path[100]; FILE * pipe;
      sprintf(path,"find /dev/ -name %s", pattern);
      pipe = popen(path, "r"); // Get USB tty:S for list, chose one to use at speedbus
      char ttyt[100];
      while(fgets(ttyt,sizeof(ttyt),pipe) > 0){
	char *nlptr;
	nlptr = strchr(ttyt, '\n');
	*nlptr = '\0';
	char send[(MAX_LOGIN_TEXT*2)+1+9];
	sprintf(send, "ttylist %s\n", ttyt);
	printf(send, "ttylist %s\n", ttyt);
	serial_p->server->send_data(listnum,send,strlen(send));  
      }
    }  
    if(strncmp(data, "ttyopen ", 8) == 0){
      char ntty[RECV_MAX]; // RECV_MAX is to big in 99.9% of all times, but a small price for preveting BOF
      sscanf(data,"ttyopen %s\n", ntty);
      if(set_tty(serial_p, ntty)){
	serial_p->server->send_data(listnum, "sinfo tty sucessfully opened\n",
				    strlen("sinfo tty sucessfully opened\n"));
      }else{
	serial_p->server->send_data(listnum, "sinfo Failed to open tty, check server log\n",
				    strlen("sinfo Failed to open tty, check server log\n"));

      }
      
    }

    if(strncmp(data, "deveid ", 7) == 0){
      
      
      int devid;
      sscanf(data,"deveid %d\n", &devid);
      if(devid > 0){
	FILE * dfile;
	char openf[50];
	sprintf(openf, SERVER_CONFIG_DIR "devs/%d.spb", devid);
	dfile = fopen (openf , "rb" );
	if (dfile==NULL) {
	serial_p->server->send_data(listnum, "deveinfo File does not exist\0",
				    strlen("deveinfo File does not exist\0"));	
	return 0;
	}
	char tbuffer[RECV_MAX];
	char sbuffer[RECV_MAX];
	int i = 0;
	serial_p->server->send_data(listnum, "devec \n",
				    strlen("devec \n"));
	usleep(10000);
	i = fread(tbuffer,1,990,dfile);
	while(i > 0){
	  tbuffer[i] = 0;
	  sprintf(sbuffer, "devei %s", tbuffer);
	  serial_p->server->send_data(listnum, sbuffer,
				      strlen(sbuffer));	
	  usleep(50000);
	  i = fread(tbuffer,1,990,dfile);
	
	}	
	fclose (dfile);
      }else{
	serial_p->server->send_data(listnum, "deveinfo devid is empty\0",
				    strlen("deveinfo devid is empty\0"));	
	return 0;
      }
      
      //printf ("Received %d chars:\n%s\n", len, data);
      err = serial_p->server->send_data(listnum, "Got msg!\n", 
					strlen("Got msg!\n"));
      
      return 0; 
    }
       
    if(strncmp(data, "devec ", 6) == 0){
      int devid;
      sscanf(data, "devec %d\n", &devid);
      FILE * clear_file;
      char cfile[200];
      sprintf(cfile,SERVER_CONFIG_DIR "devs/%d.spb", devid);
      clear_file = fopen( cfile , "w");
      fwrite ("" , 0 , 0 , clear_file);
      fclose (clear_file);
    }
  
    if(strncmp(data, "devei ", 6) == 0){
      int devid;
      sscanf(data, "devei %d ", &devid);
      FILE * a_file;
      char afile[200];
      char nr[20];
      sprintf(afile,SERVER_CONFIG_DIR "devs/%d.spb", devid);
      a_file = fopen ( afile , "a+");
      sprintf(nr, "%d", devid);
      int devid_len = strlen(nr);
      fwrite (data+7+devid_len, (len-8)-devid_len, 1, a_file);
      fclose (a_file);
    }

    if(strncmp(data, "devecr ", 7) == 0){
      serial_p->backe->devids = 0; // Make the server reload the config files on the next exec
    }
   
  }  

}

void runselect(print_seri *serial_p){
  if(FD_ISSET(serial_p->server->listen_sock,&serial_p->server->socks)){
      int listnum = serial_p->server->addclient();
  }

    for (int listnum = 0; listnum < MAX_LISTEN; listnum++) {
      //if (server.connectlist[listnum+1] == 0){
      //break;
      //}
      char data[RECV_MAX];
      int len;
      if (FD_ISSET(serial_p->server->connectlist[listnum],&serial_p->server->socks)){
	if(serial_p->server->datarun(listnum, data, &len)){
	  spb_exec(serial_p, listnum, data, len);
	}else{
	  if(serial_p->server->session_open[listnum]){
	    wtime();
	    printf("Connection from IP: (%s) by User: (%s) died\n", serial_p->server->client_ip[listnum], users[socket_user_id[listnum]][1]);
	    serial_p->server->sslfree(listnum);
	  }
	}
      }
    }

  }

void run(print_seri *serial_p){

  int sock;
  while(1){
    serial_p->server->init_select();
    
    sock = select(serial_p->server->highsock+1,&serial_p->server->socks,NULL,NULL,NULL);
    if(sock > 0)
      runselect(serial_p);
    if(sock < 0)
      printf("select error: %d", sock);
  }
}

bool add_user(config_t *server_cfg, char *user, char *pass, bool is_admin_s){
  config_setting_t *root, *setting, *users_c, *user_c;
  int index;
  for(index = 0; index < MAX_USERS; index++){
    if(users[index][1][0] == '\0'){
      break;
    }
  } 
 
  if(index >= MAX_USERS){
    return 0;
  }

  if(strlen(user) < 1)
    return 0;

  for(int i = 0; i < MAX_USERS; i++){ // Check so we do not make any doublets
    if(strcmp(users[i][1],user) == 0)
      return 0;
  } 

  const char *tty;
  config_lookup_string(server_cfg, "tty", &tty);
  printf("%s\n",tty);
  users_c = config_lookup(server_cfg, "users"); // Pretty messy, but if you already got a "users" in the config, the config_root_setting will make SIGSEG
  if(!users_c){
  root = config_root_setting(server_cfg);
  users_c = config_setting_add(root, "users", CONFIG_TYPE_LIST);
  }  

  user_c = config_setting_add(users_c, "user", CONFIG_TYPE_GROUP);
  setting = config_setting_add(user_c, "user", CONFIG_TYPE_STRING);
  config_setting_set_string(setting, user);
  setting = config_setting_add(user_c, "pass", CONFIG_TYPE_STRING);
  md5sum(pass);
  config_setting_set_string(setting, pass);
  setting = config_setting_add(user_c, "is_admin", CONFIG_TYPE_BOOL);
  config_setting_set_bool(setting, is_admin_s);

  if(!config_write_file(server_cfg, SERVER_CONFIG_URI)){
    printf("Unable to write server.cfg :/ do i have the right access? Bye!\n");
  }

  strncpy(users[index][1],user,MAX_LOGIN_TEXT);
  strncpy(users[index][2],pass,MAX_LOGIN_TEXT);
  is_admin[index] = 1;
  userc++;

  return 1;
}

bool del_user(config_t *server_cfg, char *user){
  config_setting_t *setting;
  int status = 0;
  setting = config_lookup(server_cfg, "users");
  if(setting != NULL)
    {
      int count = config_setting_length(setting);
      for(int i = 0; i < count; ++i)
	{
	  config_setting_t *element = config_setting_get_elem(setting, i);
	  /* Only output the record if all of the expected fields are present. */
	  const char *user_c;
	  if(config_setting_lookup_string(element, "user", &user_c)){
	    if(strcmp(user,user_c) == 0){
	    config_setting_remove_elem(setting, i);
	    status++;
	    break;
	    }
	  }
	}	  
    }else{
    printf("No users found in server.cfg while deleting\n");
  }
  for(int i = 0; i < MAX_USERS; i++){
    if(strcmp(user, users[i][1]) == 0){
      users[i][1][0] = '\0';
      users[i][2][0] = '\0';
      is_admin[i] = 0;
      userc--;
      status++;
    }
  }
  if(status < 2)
  return 0;  
  
  if(!config_write_file(server_cfg, SERVER_CONFIG_URI)){
    printf("Unable to write server.cfg :/ do i have the right access? Bye!\n");
    return 0;
  }
  
return 1;
}

bool mod_user(config_t *server_cfg, char *user, char *user_n, char *pass_n, bool is_admin_s){
  int index;
  for(index = 0; index < MAX_USERS; index++){
    if(strcmp(users[index][1],user) == 0){
      break;
    }
  } 

  char passwd[MAX_LOGIN_TEXT], user_s[MAX_LOGIN_TEXT];
  config_setting_t *setting;
  setting = config_lookup(server_cfg, "users");
  if(setting != NULL)
    {
      int count = config_setting_length(setting);
      
      for(int i = 0; i < count; ++i)
	{
	  config_setting_t *element = config_setting_get_elem(setting, i);
	  config_setting_t *member;

	  /* Only output the record if all of the expected fields are present. */
	  const char *user_c;
	  if(config_setting_lookup_string(element, "user", &user_c)){
	    if(strcmp(user,user_c) == 0){
	      if(strlen(user_n) > 0){
		strncpy(user_s, user_n, MAX_LOGIN_TEXT);
		strncpy(users[index][1], user_s, MAX_LOGIN_TEXT);
		member = config_setting_get_member(element, "user");
		config_setting_set_string(member,user_s);
	      }
	      if(strlen(pass_n) > 0){
		strncpy(passwd, pass_n, MAX_LOGIN_TEXT);
		md5sum(passwd);
		strncpy(users[index][2], passwd, MAX_LOGIN_TEXT);
		member = config_setting_get_member(element, "pass");
		config_setting_set_string(member,passwd);
	      }
	      member = config_setting_get_member(element, "is_admin");
	      is_admin[index] = is_admin_s;
	      config_setting_set_bool(member,is_admin_s);
	      goto del_user_end;
	    }
	  }	  
	}
    }
  
 del_user_end:
  if(!config_write_file(server_cfg, SERVER_CONFIG_URI)){
    printf("Unable to write server.cfg :/ do i have the right access? Bye!\n");
    return 0;
  }
  return 1;
  
}

bool set_tty(print_seri *serial_p, const char *tty){
  if(tty != NULL && strlen(tty) > 0){
    config_setting_t *setting;
    setting = config_lookup(serial_p->server_cfg, "tty");
    if(!setting){
      setting = config_root_setting (serial_p->server_cfg);      
      setting = config_setting_add(setting,"tty",CONFIG_TYPE_STRING); 
      if(!setting)
	return 0;
    }
      config_setting_set_string(setting, tty);
      if(!config_write_file(serial_p->server_cfg, SERVER_CONFIG_URI)){
	//printf("Unable to write server.cfg :/ do i have the right access? Bye!\n");
	return 0;
      }
  }
  FILE * pipe;
  if(config_lookup_string(serial_p->server_cfg, "tty", &tty)){
    char path[100];
    sprintf(path,"find /dev/ -name %s", tty);
    pipe = popen(path, "r"); // Get USB tty:S for list, chose one to use at speedbus
    char ttyt[100];
    char *nlptr;
    while(1){
      if(fgets(ttyt,sizeof(ttyt),pipe) > 0){
	nlptr = strchr(ttyt, '\n');
	*nlptr = '\0';
	strncpy(serial_p->ctty, ttyt, 200);
      

	if(!speed_open_tty(serial_p->ctty)){
	  //printf("Error, unable to open serial port: %s\n", ttyt);
	  //return 0;
	  //exit;
	}else{
	  break;
	}
      }else{
	//printf("Error, unable to find serial port, Bye!\n");
	return 0;
	//exit;
      } 	
      serial_port.Close();
    }
    pclose(pipe);
    return 1;
  }else{
    //printf("Please chose a tty in server.cfg\n");
    return 0;
  }
}

void make_new_admin(config_t *server_cfg, char user_arg[2][MAX_LOGIN_TEXT]){
  printf("No users found, please add a admin user!\n");
  char user[50], pass1[50], pass2[50];
  char *nlptr;
  printf("Username: ");
  fgets(user, sizeof(user), stdin);
  nlptr = strchr(user, '\n');
  if (nlptr)*nlptr = '\0';
  while(1){
  printf("Password: ");
  system("stty -echo > /dev/tty");
  fgets(pass1, sizeof(pass1), stdin);
  system("stty echo > /dev/tty");
  printf("\nConfirm Password: ");
  system("stty -echo > /dev/tty");
  fgets(pass2, sizeof(pass2), stdin);
  system("stty echo > /dev/tty");
  printf("\n");
  if(strcmp(pass1,pass2) == 0)
    break;
  }
  nlptr = strchr(pass1, '\n');
  if (nlptr)*nlptr = '\0';
  add_user(server_cfg, user, pass1, 1);

  printf("User added, starting server!\n");
}

void sig_handler(int sig)
{
  const int maxbtsize = 50;
  int btsize;
  void* bt[maxbtsize];
  char** strs = 0;
  int i = 0;
  btsize = backtrace(bt, maxbtsize);
  strs = backtrace_symbols(bt, btsize);
  char send_stack[4096];
  sprintf(send_stack, "dbg=");
  for (i = 0; i < btsize; i += 1) {
    sprintf(send_stack, "%s%d.) %s\n", send_stack, i, strs[i]);
  }
  sprintf(send_stack, "%s&platform=server", send_stack);
  std::string message;
  request("speedbus.org", "/debug.php", send_stack, message);
  free(strs);
  signal(sig, &sig_handler);
}

int main(int argc, char *argv[])
{
  //
  signal(SIGSEGV, &sig_handler);
  //

  for(int i=0; i < MAX_USERS; i++){
    users[i][1][0] = '\0';
  }


  int port;
  if(1){
    config_t server_cfg;
    config_init(&server_cfg);
    char tmp[50];
    if(!config_read_file(&server_cfg, SERVER_CONFIG_URI))
      {
	memset(tmp,0x00,50);
	sprintf(tmp,"ls " SERVER_CONFIG_DIR "|grep \"" SERVER_CONFIG_FILE "\"");
	FILE * pipe = popen(tmp, "r");
	if(fgets(tmp, 50, pipe) == NULL){
	  printf("No File server.cfg\n");
	  make_new_admin(&server_cfg,users[0]);
	  userc++;
	}else{
	  printf("Line %d: %s\n",
		 config_error_line(&server_cfg), config_error_text(&server_cfg));
	  config_destroy(&server_cfg);
	}
      }else{
      config_lookup_int(&server_cfg, "port", &port); // Fetch width                                                                                                      

      config_setting_t *setting, *tmp;
      setting = config_lookup(&server_cfg, "users");
      if(setting != NULL){
	const char *user, *pass;
	int is_admin_a;
	int count = config_setting_length(setting);
	for(int i = 0; i < count; ++i){
	  tmp = config_setting_get_elem(setting, i);
	  if((config_setting_lookup_string(tmp, "user", &user)) && 
	     (config_setting_lookup_string(tmp, "pass", &pass)) &&
	     (config_setting_lookup_bool(tmp, "is_admin", &is_admin_a))){
	    //printf("Found one user! %s:%s with is_admin %d\n",user,pass, is_admin_a);
		strncpy(users[userc][1],user,MAX_LOGIN_TEXT);
		strncpy(users[userc][2],pass,MAX_LOGIN_TEXT);
		is_admin[userc] = is_admin_a;
		userc++;
	      }
	}
      }else{
	make_new_admin(&server_cfg,users[0]);
	userc++;
      }

      
    }
    
    print_seri serial_p;
    serial_p.server_cfg = &server_cfg;

    
    if(argc > 2){
      if(strcmp(argv[1],"deluser") == 0){
	del_user(&server_cfg,argv[2]);
      }
      if(strcmp(argv[1],"adduser") == 0){
	add_user(&server_cfg,argv[2],argv[3],1);
      }
      if(strcmp(argv[1],"moduser") == 0){
	mod_user(&server_cfg,argv[2],argv[3],argv[4],atoi(argv[5]));
      }	
      if(strcmp(argv[1],"set_tty") == 0){
	set_tty(&serial_p,argv[2]);
      }	
      
    }


    set_tty(&serial_p,  NULL);
    wtime();
    if(serial_port.IsOpen()){
      printf("Serial Port: %s Open\n", serial_p.ctty);
    }else{
      printf("Could not find/open serial port\n");
    }

    sslserver server;
    server.loadssl();
    if(!server.sslsocket())
    return 0;
    //server.addclient();
    wtime();
    printf("Starting SpeedBus TTY interface Thread\n");
    serial_p.backe = init_backend();
    serial_p.server = &server;

    pthread_t printr;
    pthread_create(&printr, NULL, &print_ser_backend, (void *)&serial_p);
    addr1 = addr2 = 20;

    spb_write_log("Server started.");
    device_file_init(&serial_p);
    if(serial_p.device_num > 0){
      wtime();
      printf("Loaded %d cached units\n", serial_p.device_num);
      backend_load_events(serial_p.backe);
    }

    if(serial_port.IsOpen()){
      if(serial_p.device_num < 1){
      wtime();
      fprintf(stdout, "Scanning for devices");
      int len = 8;
      char getdevs[20] = {0xFF,0xFF,addr1,addr2,0x03,0x01,0x01,0x00};
      for(int i=0; i < 8; i++){
	if(i == 0 || i == 4)
	  send(getdevs, len);
	fprintf(stdout, ".");
	fflush(stdout);
	sleep(1);
      }
      printf("\n");
      wtime();
      printf("Scaning done, found %d units\n", serial_p.device_num);
      }
    }

    wtime();
    printf("Starting SPB server with %d users\n", userc);
    spb_inalize_notify(&serial_p);    
    wtime();
    printf("Notify loaded\n");


    spb_write_notify(&serial_p, "Server Started!", 3);    
    //device_add(&serial_p,0,0,16432);

    run(&serial_p);
  }
  else{
    sslclient client;
    if(argc > 1)
      client.sslsocket(argv[1],atoi(argv[2]));
    else
    client.sslsocket("127.0.0.1",306);

    char hello[80];
    printf ("Message to be sent to the SSL server: ");
    fgets (hello, 80, stdin);
    client.loadssl();
    /*----------------------------------------------------------*/

    client.send_data(hello, strlen(hello));
    client.sslfree();
  }
}
