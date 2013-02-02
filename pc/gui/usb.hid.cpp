//#include "main.h"
#include "usb.hid.h"

usb_hid * libusb_devices[MAX_USB_UNITS]; 
int     libusb_devicec = 0;

const char *byte_to_binary(int x )
{
  static char b[9];
  b[0] = '\0';

  int z;
  for (z = 128; z > 0; z >>= 1)
    {
      strcat(b, ((x & z) == z) ? "1" : "0");
    }

  return b;
}
 
static int find_lvr_hidusb(usb_hid * dev)
{
  dev->devh = libusb_open_device_with_vid_pid(NULL, dev->vid, dev->pid);
  return dev->devh ? 0 : -EIO;
}
 
void *handle_usb_hid_event(void * devv)
{
  usb_hid *dev = (usb_hid *)devv;  
  int r,i;
  int transferred;
  unsigned char answer[100];
  while(1){
  r = libusb_interrupt_transfer(dev->devh, ENDPOINT_INT_IN, answer,dev->bwidth,
				&transferred, TIMEOUT);
    if (r < 0) {
    fprintf(stderr, "Interrupt read error %d\n", r);
    //  return r;
  }
    if(r==-99){
      fprintf(stderr, "Device unplugged\n");
      return 0;
    }
    if(r>=0){
      
      for(i = 0; i<dev->eventc; i++){
	if(dev->event[i][2] == 1){ // 4bit low variable
	  int var = (unsigned char)((answer[dev->event[i][3]]) & 0b00001111);
	    if(dev->event[i][5]!=var){
	      dev->event[i][5] = var; 
	      backend_set_variable(dev->backe,dev->event[i][1],dev->event[i][4],var);
	      //printf("4bit low: %d\n", var);
	    }
	}

	if(dev->event[i][2] == 2){ // 4bit high variable
	  int var = (unsigned char)(((answer[dev->event[i][3]]) & 0b11110000)>>4);  
	  if(dev->event[i][5]!=var){
	      dev->event[i][5] = var; 
	      backend_set_variable(dev->backe,dev->event[i][1],dev->event[i][4],var);
	      //printf("4bit high: %d\n",var);
	    }
	}

	if(dev->event[i][2] == 3){ // 8bit variable
	  if(dev->event[i][5]!=answer[dev->event[i][3]]){
	      dev->event[i][5] = answer[dev->event[i][3]]; 
	      backend_set_variable(dev->backe,dev->event[i][1],dev->event[i][4],(unsigned char)answer[dev->event[i][3]]);
	      //printf("8bit: %d\n", (unsigned char)answer[dev->event[i][3]]);
	    }
	  }

	if(dev->event[i][2] == 0){ // Bit toggle event
	  if(answer[dev->event[i][3]] & (1<<dev->event[i][4])){
	    if(dev->event[i][5]<1){
	      dev->event[i][5] = 1;
	      backend_exec(dev->backe,dev->event[i][6],dev->event[i][1],0);
	      //printf("Toggle bit, event: %d %d\n", dev->event[i][6], i);
	    }
	  }else{
	    dev->event[i][5] = 0;
	  }
	}
	
	if(dev->event[i][2] == 4){ // 4bit low toggle event
	  if(((answer[dev->event[i][3]]) & 0b00001111) == dev->event[i][4]){
	    if(dev->event[i][5]<1){  
	      dev->event[i][5] = 1; 
	      backend_exec(dev->backe,dev->event[i][6],dev->event[i][1],0);
	      //printf("Toggle 4bit low\n");
	    }
	}else{
	    dev->event[i][5] = 0;
	  }
	}

	if(dev->event[i][2] == 5){ // 4bit high toggle event
	  if((((answer[dev->event[i][3]]) & 0b11110000)>>4) == dev->event[i][4]){
	    if(dev->event[i][5]<1){  
	      dev->event[i][5] = 1; 
	      backend_exec(dev->backe,dev->event[i][6],dev->event[i][1],0);
	      //printf("Toggle 4bit high\n");
	    }
	}else{
	    dev->event[i][5] = 0;
	  }
	}

	if(dev->event[i][2] == 6){ // 8bit toggle event
	  if((unsigned char)answer[dev->event[i][3]] == dev->event[i][4]){
	    if(dev->event[i][5]<1){  
	      dev->event[i][5] = 1; 
	      backend_exec(dev->backe,dev->event[i][6],dev->event[i][1],0);
	      //printf("Toggle 8bit\n");
	    }
	}else{
	    dev->event[i][5] = 0;
	  }
	}

      }

    }
    //      printf("\r");
    //for(i = 0;i < transferred; i++) {
    //printf("%s, ",byte_to_binary(answer[i] & 0xFF));
    //}
  }
  memset(answer,0x00,100);
} 
int open_usb_hid(main_backend * backe, char * cname)
{
  int udevice_num = libusb_devicec;
  libusb_devices[udevice_num] = (usb_hid*)malloc(sizeof (usb_hid));
  libusb_devices[udevice_num]->eventc = 0;

  const char *str;
  config_init(&libusb_devices[udevice_num]->cfg);

  if(!config_read_file(&libusb_devices[udevice_num]->cfg, cname))
    {
      char tmp2[50];
      sprintf(tmp2,"ls %s",cname);
      FILE * pipe = popen(tmp2, "r");
      if(fgets(tmp2, 50, pipe) == NULL){
	printf("No File %s\n", cname);
      }else{
      printf("Line %d: %s\n",
	      config_error_line(&libusb_devices[udevice_num]->cfg), config_error_text(&libusb_devices[udevice_num]->cfg));
      config_destroy(&libusb_devices[udevice_num]->cfg);
      return 1;
      }}

  if(config_lookup_string(&libusb_devices[udevice_num]->cfg, "vendor_id", &str)){
  sscanf(str, "%x", &libusb_devices[udevice_num]->vid);  
  }else return -1;
  if(config_lookup_string(&libusb_devices[udevice_num]->cfg, "product_id", &str)){
  sscanf(str, "%x", &libusb_devices[udevice_num]->pid);  
  }else return -1;
  if(!config_lookup_int(&libusb_devices[udevice_num]->cfg, "bwidth", &libusb_devices[udevice_num]->bwidth))
  return -1;



  int r = 1;
  r = libusb_init(NULL);
  if (r < 0) {
    fprintf(stderr, "Failed to initialise libusb\n");
    return 0;
  }

  r = find_lvr_hidusb(libusb_devices[udevice_num]);
  if (r < 0) {
    fprintf(stderr, "Could not find/open LVR Generic HID device\n");
    return 0;
  }
  //printf("Successfully find the LVR Generic HID device\n");
 
  libusb_detach_kernel_driver(libusb_devices[udevice_num]->devh, 0);
 
  r = libusb_set_configuration(libusb_devices[udevice_num]->devh, 1);
  if (r < 0) {
    fprintf(stderr, "libusb_set_configuration error %d\n", r);
    return 0;
  }
  //printf("Successfully set usb configuration 1\n");
  r = libusb_claim_interface(libusb_devices[udevice_num]->devh, 0);
  if (r < 0) {
    fprintf(stderr, "libusb_claim_interface error %d\n", r);
    return 0;
  }
  //printf("Successfully claimed interface\n");

  config_setting_t *setting;
  setting = config_lookup(&libusb_devices[udevice_num]->cfg, "usb_hid.events");
  if(setting != NULL)
    {
      int count = config_setting_length(setting);
      int i;
      for(i = 0; i < count; ++i)
	{
	  config_setting_t *book = config_setting_get_elem(setting, i);
	  
	  lint event; lint type; lint affected_byte; lint second_arg; lint devid;
          if(!(config_setting_lookup_int(book, "event", &event)) || !(config_setting_lookup_int(book, "type", &type))
	     || !(config_setting_lookup_int(book, "affected_byte", &affected_byte)) || !(config_setting_lookup_int(book, "second_arg", &second_arg))
	     || !(config_setting_lookup_int(book, "device_id", &devid))){
	      printf("You seems to have missed 'event','device_id','type','affected_byte' or 'second_arg' at event nr %d in config file %s ignoring event\n", i, cname);
	      continue;}
	  if(affected_byte > libusb_devices[udevice_num]->bwidth){
	    printf("At event %d in config file %s, affected byte cant be higher then bwidth, row ignored\n", i, cname);
	    continue;
	  }
	  if(type == 0 && second_arg > 7){ // If there is select bit, in a 8bit value, the range is 0-7
            printf("At event %d in config file %s, select bit cant be higher then 7, 0-7, row ignored\n", i, cname);
            continue;
          }
	  int eventc = libusb_devices[udevice_num]->eventc++ ; // Make it a bit easyer to read
	  //printf("Event %d : %d", (int)eventc, (int)event);  
	  libusb_devices[udevice_num]->event[eventc][6] = event; // event number
	    libusb_devices[udevice_num]->event[eventc][1] = devid; // event AT device id
	    libusb_devices[udevice_num]->event[eventc][2] = type; // event type
	    libusb_devices[udevice_num]->event[eventc][3] = affected_byte; // event affected byte
	    libusb_devices[udevice_num]->event[eventc][4] = second_arg; // event second arg, see the usb_hid struct at the top
	  
	}
      
      // Load the backend, variable operations, that may be put in this file

      backend_load_var_ops(backe, &libusb_devices[udevice_num]->cfg, cname, 0);
      

    }
  
  libusb_devices[udevice_num]->backe = backe;
  
  pthread_create( &libusb_devices[udevice_num]->event_thread, NULL, handle_usb_hid_event, (void*)libusb_devices[udevice_num]);

  //  libusb_release_interface(libusb_devices[udevice_num]->devh, 0);
  //  libusb_reset_device(devh);
  //libusb_close(libusb_devices[udevice_num]->devh);
  //libusb_exit(NULL);
  libusb_devicec++;
  return r >= 0 ? r : -r;
    }
