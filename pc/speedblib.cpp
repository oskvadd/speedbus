#include "speedblib.h"
#include <SerialStream.h>
#include <iostream>

using namespace LibSerial;

SerialStream serial_port;
bool         verbose = 1;
bool         debug   = 0;
char         tx_data[100];
char         addr1;
char         addr2;
char         resp_addr1;
char         resp_addr2;
bool         got_resp = 1;

void wtime()
{
  time_t rawtime;
  struct tm * timeinfo;
  char buffer[80];
  time(&rawtime);
  timeinfo = localtime(&rawtime);
  strftime(buffer, 80, "* [%H:%M:%S] - ", timeinfo);
  std::cout << buffer;
}


short crcsum(char * data, int len){
  short crc=0; int x=0;
  for(int i=0;i < len;i++){
    x = ((crc>>8) ^ data[i]) & 0xff;
    x ^= x>>4;
    crc = (crc << 8) ^ (x << 12) ^ (x <<5) ^ x;
  } return crc;
}

void crcstr(char * data, int len){
  short crc = crcsum(data, len);
  data[len] = (char)(crc & 0xff);
  data[len+1] = (char)((crc >> 8) & 0xff);
}

bool crcstrc(char * data, int len)
{
  /*                                                                                                                                                                                
   * Returns true if the last two bytes in a message is the crc of the                                                                                                              
   * preceding bytes.                                                                                                                                                               
   */
  short crc;
  crc = crcsum(data, len - 2);
  return (char)(crc & 0xff) == data[len - 2] &&
    (char)((crc >> 8) & 0xff) == data[len - 1];
}

int unescape(char * data, int * len)
{
  int p = 0;
  for(int i=0; i < (*len-p); i++){
    data[i] = data[i+p];
    if(data[i] == 0x7d){
      switch(data[i+p+1]){
      case 0x5e:
	data[i] = 0x7e;
	p++;
	break;      
      case 0x5d:
	data[i] = 0x7d;
	p++;
	break;
      }
    }
    //    std::cerr << std::hex << i << ": - " << static_cast<int>(data[i] & 0xFF) << " " << std::endl;
  }
  //std::cerr << std::endl << std::hex << len << std::endl;
  //if(crcstrc(data,len)){std::cerr << "Yippie" << std::endl;}
  *len = *len - p;
}

int escape(char * data, int * len){
  int p = 0;

  char tmp_data[*len+2];
  memcpy(tmp_data,data,*len+2);

  for(int i=0; i < (*len+p+2); i++){ // Why +2? well, the code is pretty messy, but the crc-16 is not counted in len
    //    std::cerr << std::hex << i << ": - " << static_cast<int>(data[i] & 0xFF) << " " << std::endl;
    switch(tmp_data[i]){
    case 0x7e:
      data[i+p] = 0x7d;
      data[i+p+1] = 0x5e;
      p++;
      break;
    case 0x7d:
      data[i+p] = 0x7d;
      data[i+p+1] = 0x5d;
      p++;      
      break;
    default:
      data[i+p] = tmp_data[i];
    }
    if(debug){std::cerr << std::hex << i << ": - " << static_cast<int>(data[i] & 0xFF) << " " << std::endl;}
  }
  *len = *len + p;
}

void *print_ser(void *ptr){

  int counter = 0;
  bool e = 0;
  bool justcap = 0;
  char data[100];
  while(1){
    // Keep reading data from serial port and print it to the screen.
    //
    usleep(200000);
    while(serial_port.rdbuf()->in_avail() > 0) 
      {
	char next_byte;
	serial_port.get(next_byte);
	if(next_byte == 0x7e && e == 1){
	  bool loopback = memcmp(data, tx_data, counter);
	  unescape(data,&counter); // Unescape the incomming package, check rfc1662 for escape rules
	  if(crcstrc(data,counter) && counter > 5){ // Min packet length 5
	    if(loopback != 0 || debug){
	      if(verbose && (unsigned char)data[6] != 0){std::cerr << std::endl;}
	      switch((unsigned char)data[6]){
	      case 0:
		if(debug){
		  std::cerr << "Recived broadcast aknowlegde (0x00) to '" << std::dec  << (data[0] & 0xff) << "." <<
		    (data[1] & 0xff) << "' from '" << std::dec  << (data[2] & 0xff) << "." << (data[3] & 0xff) << "'";}
		if(resp_addr1 == data[2] && resp_addr2 == data[3]){
		  got_resp = 1;
		}
		break;
	      case 1:
		if(data[0] == addr1 && data[1] == addr2){
		  if(verbose)
		    std::cerr << "Recived device list aknowlegde (0x01) from '" << std::dec  << (data[2] & 0xff) << "." <<
		      (data[3] & 0xff) << "'";
		  if(data[5] == 0x01) // Dont send response when using a nonresponse protocoll
		    send_response(data[2],data[3]);
		}
		break;
	      case 170:
		if(verbose){
		  wtime();
		  std::cerr << "Recived ALARM (0xAA) from '" << std::dec  << (data[2] & 0xff) << "." <<
		    (data[3] & 0xff) << "' Sig: (" << std::hex << (static_cast<int>(data[7]) & 0xff) << ") Dec: (" << std::hex << (static_cast<int>(data[8]) & 0xff) << ")";}
		break;
	      default:
		if(verbose){
		  std::cerr << "SUCESS: Recived package from: '" << std::dec << (static_cast<int>(data[2]) & 0xff) << "." <<
		    (static_cast<int>(data[3]) & 0xff) << "' With data: '";
		  for(int i=0; i < counter-9; i++){
		    std::cerr << std::hex << (static_cast<int>(data[i+6]) & 0xff);if(i<counter-10){std::cerr << " ";}}
		  std::cerr << "'";}}}
	  
	    justcap = 1;
	    e=0;
	  }else{
	    if(verbose){std::cerr << "ERROR: recived damaged package"; 
	      counter = 0;
	    }
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


void    send(char * data, int len){
  // The command in this case, 0x01 is used for broadcast, and recive:ing the device adresses
  char odata[sizeof(data)];
  memcpy(odata, data, sizeof(data));
  crcstr(data,len);
  escape(data,&len); // Important that you run this AFTER the CRC calc
  //      memcpy(tx_data,data,len+2);
  if(debug){
    for(int i=0; i < len+2; i++){
      std::cerr << std::hex << (static_cast<int>(data[i]) & 0xff);if(i<len+1){std::cerr << " ";}}
  }
  resp_addr1 = (unsigned char)data[0];
  resp_addr2 = (unsigned char)data[1];
  for(int ic=0; ic<10; ic++){
    char flag = 0x7e;
    char wakeup = 0xfe;
    for(int i=0; i < (len+5); i++){
      // len + 4 = 2 rounds for the flag bit:s and 2 for the checksum one for wakeup
      if(i == 0){
	serial_port.write(&wakeup,1); // Always inilize with sending wakeup byte when using PC interface 
      }
      else if(i == 1){
	serial_port.write(&flag,1);
      }
      else if(i == (len+4)){
	serial_port.write(&flag,1);}
      else{
	serial_port.write(data+(i-2),1);}
      usleep(2500);
    }

    // Use odata because the data array may be escaped, and if the adress is twise as long, the data bytes whont be at the same place
    if((unsigned char)odata[5] == 0x01) // If the package are going to recive a response, set got_resp to zero, else, leave it as it was.
      got_resp = 0;

    if((unsigned char)data[0] == 0xff && (unsigned char)data[1] == 0xff) // Dont wait for response on broadcast
      break;
    if((unsigned char)odata[6] == 0) // Dont wait for response on response
      break;
    if((unsigned char)odata[5] != 0x01) // Dont wait for response when using the nonresponse protocoll
      break;
    for(int ii=0; ii<50;ii++){
      usleep(8000);
      if(got_resp) // End if a response whas recived                                                                                                                             
	break;
    }
    if(got_resp) // End if a response whas recived
      break;
  }      
}

void    send_response(char addr_1, char addr_2){
  int len = 8;
  char getdevs[20] = {0x00,0x00,addr1,addr2,0x03,0x00,0x00,0x00};
  getdevs[0] = addr_1;
  getdevs[1] = addr_2;
  send(getdevs, len);
}

bool speed_open_tty(char * tty){
  if(serial_port.IsOpen()){
    serial_port.Close();
  }
  serial_port.Open( tty ) ;
  if ( ! serial_port.IsOpen() ) 
    {
      //std::cerr << "Error: Could not open serial port: " << tty 
      //	<< std::endl ;
      return 0;
      //exit(1);
    }
  else
    {
      //std::cout << "Succefully opend tty: " << tty << std::endl;
      //exit(1);
    }
  //
  // Set the baud rate of the serial port.
  //
  serial_port.SetBaudRate( SerialStreamBuf::BAUD_19200 ) ;
  if ( ! serial_port.good() ) 
    {
      std::cerr << "Error: Could not set the baud rate." << std::endl ;
      //return 0;
      //exit(1);
    }
  //
  // Set the number of data bits.
  //
  serial_port.SetCharSize( SerialStreamBuf::CHAR_SIZE_8 ) ;
  if ( ! serial_port.good() ) 
    {
      std::cerr << "Error: Could not set the character size." << std::endl ;
      //return 0;
      //exit(1);
    }
  //
  // Disable parity.
  //
  serial_port.SetParity( SerialStreamBuf::PARITY_NONE ) ;
  if ( ! serial_port.good() ) 
    {
      std::cerr << "Error: Could not disable the parity." << std::endl ;
      //return 0;
      //exit(1);
    }
  //
  // Set the number of stop bits.
  //
  serial_port.SetNumOfStopBits( 0 ) ;
  if ( ! serial_port.good() ) 
    {
      std::cerr << "Error: Could not set the number of stop bits."
		<< std::endl ;
      //return 0;
      //exit(1);
    }
  //
  // Turn off hardware flow control.
  //
  serial_port.SetFlowControl( SerialStreamBuf::FLOW_CONTROL_NONE ) ;
  if ( ! serial_port.good() ) 
    {
      std::cerr << "Error: Could not use hardware flow control." << std::endl ;
      //return 0;
      // exit(1) ;
    }

  return 1;

  //
  // Do not skip whitespace characters while reading from the
  // serial port.
  //
  // serial_port.unsetf( std::ios_base::skipws ) ;
  //
  // Wait for some data to be available at the serial port.
  //

}
