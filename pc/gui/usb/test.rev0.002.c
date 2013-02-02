#include <errno.h>
#include <signal.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <libusb-1.0/libusb.h>
  
const static int INTERFACE=0;
const static int ENDPOINT_INT_IN=0x81; /* endpoint 0x81 address for IN */
const static int ENDPOINT_INT_OUT=0x01; /* endpoint 1 address for OUT */
const static int TIMEOUT=5000; /* timeout in ms */

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
 
void bad(const char *why) {
  fprintf(stderr,"Fatal error> %s\n",why);
  exit(17);
}
 
static struct libusb_device_handle *devh = NULL;
 
static int find_lvr_hidusb(unsigned int vid, unsigned int pid)
{
  devh = libusb_open_device_with_vid_pid(NULL, vid, pid);
  return devh ? 0 : -EIO;
}
 
static int test_interrupt_transfer(int bwidth)
{
  int r,i;
  int transferred;
  char answer[100];
  //for (i=0;i<PACKET_INT_LEN; i++) question[i]=i;
 
  //r = libusb_interrupt_transfer(devh, ENDPOINT_INT_OUT, question, PACKET_INT_LEN,
  //				&transferred,TIMEOUT);
  if (r < 0) {
    fprintf(stderr, "Interrupt write error %d\n", r);
    return r;
  }
  while(1){
  r = libusb_interrupt_transfer(devh, ENDPOINT_INT_IN, answer,bwidth,
				&transferred, TIMEOUT);
    if (r < 0) {
    fprintf(stderr, "Interrupt read error %d\n", r);
    //  return r;
  }
    if(r==-99){
      fprintf(stderr, "Device unplugged\n");
      return r;
    }
  if (transferred < bwidth) {
    fprintf(stderr, "Interrupt transfer short read (%d)\n", r);
    //return -1;
  }
  //int lx = answer[5];
  //int ly = answer[3];
  //int rx = answer[1];
  //int ry = answer[2];

  //  printf("\rleft x: %d, y: %d . right x: %d, y: %d                  ",(unsigned char)lx, (unsigned char)ly, (unsigned char)rx, (unsigned char)(ry));
    for(i = 0;i < transferred; i++) {
      //  if(i%8 == 0)
      //printf("\n");
    printf("%s, ",byte_to_binary(answer[i] & 0xFF));
  }
  memset(answer,0x00,100);
  printf("\n");
}
  //return 0;
}
 
int main(int argc, char* argv[])
{

  int r = 1;
 
  r = libusb_init(NULL);
  if (r < 0) {
    fprintf(stderr, "Failed to initialise libusb\n");
    exit(1);
  }
  unsigned int vid = 0;
  unsigned int pid = 0;
  if(argc >= 3){
  sscanf(argv[1], "%x", &vid);
  sscanf(argv[2], "%x", &pid);}
  else{
    system("lsusb");
    printf("%s [vendor_id as hex] [product_id as hex] <recive width. Def 8>\n", argv[0]);
    return 0;
  }
  unsigned int bwidth = 8; // Default width 8
  if(argc > 3)
    sscanf(argv[3], "%d", &bwidth);

  r = find_lvr_hidusb(vid,pid);
  if (r < 0) {
    fprintf(stderr, "Could not find/open LVR Generic HID device\n");
    goto out;
  }
  printf("Successfully find the LVR Generic HID device\n");
 
 #ifdef LINUX
  libusb_detach_kernel_driver(devh, 0);
 #endif
 
  r = libusb_set_configuration(devh, 1);
  if (r < 0) {
    fprintf(stderr, "libusb_set_configuration error %d\n", r);
    goto out;
  }
  printf("Successfully set usb configuration 1\n");
  r = libusb_claim_interface(devh, 0);
  if (r < 0) {
    fprintf(stderr, "libusb_claim_interface error %d\n", r);
    goto out;
  }
  printf("Successfully claimed interface\n");
 
  test_interrupt_transfer(bwidth);
  libusb_release_interface(devh, 0);
 out:
  //  libusb_reset_device(devh);
  libusb_close(devh);
  libusb_exit(NULL);
  return r >= 0 ? r : -r;
}

