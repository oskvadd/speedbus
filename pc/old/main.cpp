// This program need libserial

#include <SerialStream.h>
#include <iostream>
#include <unistd.h>
#include <cstdlib>
#include <cstring>
#include <pthread.h>
#include "speedblib.cpp"


int
main( int    argc,
      char** argv  )
{
  addr1 = 20;
  addr2 = 20;
  speed_open_tty("/dev/ttyUSB0");
  
  pthread_t printr;
  pthread_create(&printr, NULL, &print_ser, (void *)serial_port);

  char hej = 0xa;

  while(1){

    if(hej == 'b'){  // Set PORTC to user input.
    int len = 9;
    char getdevs[10] = {0xFF,0xFF,0xFF,0xFF,0x03,0x01,0x02,0x00,0x00,0x00};
    std::cerr << "UNIT=";
    int addr1;
    int addr2;
    scanf("%d.%d",&addr1, &addr2);
    getdevs[0] = (char)addr1;
    getdevs[1] = (char)addr2;
    std::cerr << "PORTC=";
    int num;
    scanf("%d",&num);
    getdevs[8] = (char)num;
    send(getdevs, len);
  }
    if(hej == 'c'){
    int len = 8;
    char getdevs[10] = {0x00,0x00,addr1,addr2,0x03,0x00,0x01,0x00};
    std::cerr << "UNIT=";
    int addr1;
    int addr2;
    scanf("%d.%d",&addr1, &addr2);
    getdevs[0] = (char)addr1;
    getdevs[1] = (char)addr2;
    send(getdevs, len);
  }
    if(hej == 'u'){
    int len = 8;
    char getdevs[10] = {0x00,0x00,0xFF,0xFF,0x03,0x00,0x03,0x00};
    std::cerr << "UNIT=";
    int addr1;
    int addr2;
    scanf("%d.%d",&addr1, &addr2);
    getdevs[0] = (char)addr1;
    getdevs[1] = (char)addr2;
    send(getdevs, len);
  }
    if(hej == 'r'){
    int len = 10;
    char getdevs[10] = {0x00,0x00,0xFF,0xFF,0x03,0x01,0x0A,0x00,0x00,0x00};
    std::cerr << "UNIT=";
    int addr1;
    int addr2;
    scanf("%d.%d",&addr1, &addr2);
    getdevs[0] = (char)addr1;
    getdevs[1] = (char)addr2;
    int num;
    
    std::cerr << "TYPE=";
    scanf("%d",&num);
    getdevs[7] |= (char)num;
    getdevs[7] <<= 1;

    getdevs[7] |= 0b1; // Group action, just a default 1
    getdevs[7] <<= 2;
    
    std::cerr << "METHOD(Dim:0,Off:1,On:2)=";
    scanf("%d",&num);
    getdevs[7] |= (char)num;
    getdevs[7] <<= 1;

    std::cerr << "Lerning=";
    num = 0;
    scanf("%d",&num);
    if(num==1)
    getdevs[7] |= 0b1;


    std::cerr << "NUMB=";
    scanf("%d",&num);
    getdevs[8] = (char)num;
    getdevs[8] <<= 4;
    std::cerr << "LEVEL=";
    scanf("%d",&num);
    getdevs[8] |= (char)num;
    send(getdevs, len);
  }
  if(hej == 'e'){
    int len = 9;
    char getdevs[10] = {0x00,0x00,0xFF,0xFF,0x03,0x01,0x0B,0x00,0x00};
    std::cerr << "UNIT=";
    int addr1;
    int addr2;
    scanf("%d.%d",&addr1, &addr2);
    getdevs[0] = (char)addr1;
    getdevs[1] = (char)addr2;
    std::cerr << "SERVO=";
    int num;
    scanf("%d",&num);
    getdevs[7] = (char)num;
    send(getdevs, len);
  }
  if(hej == 'l'){
    int len = 9;
    char getdevs[10] = {0x00,0x00,0xFF,0xFF,0x03,0x01,0x0A,0x00,0x00};
    std::cerr << "UNIT=";
    int addr1;
    int addr2;
    scanf("%d.%d",&addr1, &addr2);
    getdevs[0] = (char)addr1;
    getdevs[1] = (char)addr2;
    std::cerr << "RELAY=";
    int num;
    scanf("%d",&num);
    getdevs[7] = (char)num;
    send(getdevs, len);
  }
  if(hej == 't'){
    int len = 9;
    char getdevs[10] = {0x00,0x00,0xFF,0xFF,0x03,0x01,0x0C,0x00,0x00};
    std::cerr << "UNIT=";
    int addr1;
    int addr2;
    scanf("%d.%d",&addr1, &addr2);
    getdevs[0] = (char)addr1;
    getdevs[1] = (char)addr2;
    //    std::cerr << "RELAY=";
    //int num;
    //scanf("%d",&num);
    //getdevs[7] = (char)num;
    send(getdevs, len);
  }
  if(hej == 's'){  // BroadCast for devices
    int len = 8;
    char getdevs[10] = {0xFF,0xFF,addr1,addr2,0x03,0x01,0x01,0x00};
    send(getdevs, len);
  }
  if(hej == 'x'){
    int len = 200;
    char getdevs[200] = {0xFF};
    send(getdevs, len);}
  if(hej == 'h'){
    std::cout << "Chose the operation you want to do:\n";
    std::cout << "* : Broadcast every microchip:    b\n";
    std::cout << "* : Experimental(0x00):           c\n";
    std::cout << "* : Experimental(0x01):           s\n";
    std::cout << "* : Remote      (0x0A):           r\n";
    std::cout << "* : Relay       (0x0A):           l\n";
    std::cout << "* : Experimental(0x0B):           e\n";
    std::cout << "* : Just send 200 random chars:   x\n";
    std::cout << "* : Debug:                        d\n";
    std::cout << "* : Verbose:                      v\n";
    std::cout << "* : Help                          h\n";
    std::cout << "* : Quit                          q\n";
  }
  if(hej == 'q'){
    std::cout << "ByeBye!\n";
    exit(1);
  }
  if(hej == 'v'){
    if(verbose){std::cout << "Stopping verbose\n";verbose=0;}
    else if(!verbose){std::cout << "Starting verbose\n";verbose=1;}
  }
  if(hej == 'd'){
    if(debug){std::cout << "Stopping debug\n";debug=0;}
    else if(!debug){std::cout << "Starting debug\n";debug=1;}
  }
  if(hej == 0x0a){std::cout << "command> ";}
  scanf("%c",&hej);
  }

  std::cerr << std::endl ;
  return EXIT_SUCCESS ;
}

