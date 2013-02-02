#include <errno.h>
#include <signal.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <libusb-1.0/libusb.h>
#include <libconfig.h>  
#include <pthread.h>
#include "spb.backend.h"
#define MAX_USB_UNITS    10
#define MAX_EVENTS       50
#define EVENT_TYPES      10
#define INTERFACE        0
#define ENDPOINT_INT_IN  0x81 /* endpoint 0x81 address for IN */
#define ENDPOINT_INT_OUT 0x01 /* endpoint 1 address for OUT */
#define TIMEOUT          5000 /* timeout in ms */


typedef struct _usb_hid {
struct libusb_device_handle * devh;
unsigned int vid;
unsigned int pid;
lint bwidth;  
pthread_t event_thread;
config_t cfg;
  /*
    Hmm, just some basic info about the event system at usb_hid
    First off: 
    There are a few seperated types of events, threre are:
    binary toggle
    4bit decimal->variable
    8bit decimal->variable
    4bit decimal->toggle
    8bit decimal->toggle
    
    Further off, it whould be nice with event conbinations, like event1+event2=event3...
    to allow specific keykombinations...
    Well, Comming back later for som more notices, for sure :)
   */
  int event[MAX_EVENTS][6];
  int eventc;
  /*
    [6]: Event number
    [1]: Device ID
    [2]: Event type(Separate 4bit operations, so high and low are diffrent types)
    [3]: Affected byte(Shall not be higher then bwidth)
    [4]: Affected bit OR the variable to put the 8bit/4bit number in
    [5]: Event Triggerd
    
    Pleace read the code for further notices.
  */
  
  main_backend * backe;

} usb_hid;

int open_usb_hid(main_backend * backe, char * cname);
void *handle_usb_hid_event(void * devv);
static int find_lvr_hidusb(usb_hid * dev);
