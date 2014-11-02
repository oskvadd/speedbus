// This program need libserial

#include <SerialStream.h>
#include <iostream>
#include <unistd.h>
#include <cstdlib>
#include <cstring>
#include <pthread.h>
#include "speedblib.cpp"

#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <errno.h>
#include <string.h>
#include <sys/types.h>
#include <time.h> 

int main(int argc, char *argv[])
{
  open();
  int listenfd = 0, connfd = 0, newsockfd=0;
  struct sockaddr_in serv_addr,cli_addr; 
  socklen_t clilen;
  int n;
  char sendBuff[1025];
  char userBuff[1025];
  char passBuff[1025];
  time_t ticks; 

  listenfd = socket(AF_INET, SOCK_STREAM, 0);
  memset(&serv_addr, '0', sizeof(serv_addr));
  memset(sendBuff, '0', sizeof(sendBuff)); 

  serv_addr.sin_family = AF_INET;
  serv_addr.sin_addr.s_addr = htonl(INADDR_ANY);
  serv_addr.sin_port = htons(55); 

  bind(listenfd, (struct sockaddr*)&serv_addr, sizeof(serv_addr)); 

  listen(listenfd, 10); 

  while(1)
    {
      connfd = accept(listenfd, (struct sockaddr*)NULL, NULL); 
      

      sprintf(sendBuff, "220 Speedbus UI socket remote\r\n");
      write(connfd, sendBuff, strlen(sendBuff)); 

      bzero(userBuff,256);
      n = read(connfd,userBuff,255);
      for(int i=0;i<255;i++){std::cout << userBuff[i];}

      sprintf(sendBuff, "331 Password...\r\n");
      write(connfd, sendBuff, strlen(sendBuff)); 

      bzero(passBuff,256);
      n = read(connfd,passBuff,255);
      for(int i=0;i<255;i++){std::cout << passBuff[i];}
      
      
      sprintf(sendBuff, "221 Bye...\r\n");
      write(connfd, sendBuff, strlen(sendBuff)); 
      
      
      if(userBuff[5] == 'a'){
	std::cout << "Full belysning\n";
    int len = 10;
    char getdevso[10] = {0x00,0x00,0xFF,0xFF,0x03,0x01,0x0A,0x00,0x00,0x00};
    char getdevs[10];
    memcpy(&getdevs,&getdevso,10);
    int addr1 = 228;
    int addr2 = 101;
    getdevs[0] = (char)addr1;
    getdevs[1] = (char)addr2;
    
    // Type
    getdevs[7] |= (char)2;
    getdevs[7] <<= 1;

    // Group
    getdevs[7] |= 0b1; // Group action, just a default 1
    getdevs[7] <<= 2;
    
    // Method "METHOD(Dim:0,Off:1,On:2)="
    getdevs[7] |= (char)0;
    getdevs[7] <<= 1;

    // Numb
    getdevs[8] = (char)2;
    getdevs[8] <<= 4;
    
    // Level
    getdevs[8] |= (char)15;
    send(getdevs, len);
    sleep(1);


    memcpy(&getdevs,&getdevso,10);

    getdevs[0] = (char)addr1;
    getdevs[1] = (char)addr2;
    
    // Type
    getdevs[7] |= (char)2;
    getdevs[7] <<= 1;

    // Group
    getdevs[7] |= 0b1; // Group action, just a default 1
    getdevs[7] <<= 2;
    
    // Method "METHOD(Dim:0,Off:1,On:2)="
    getdevs[7] |= (char)0;
    getdevs[7] <<= 1;

    // Numb
    getdevs[8] = (char)1;
    getdevs[8] <<= 4;
    
    // Level
    getdevs[8] |= (char)15;
    send(getdevs, len);

      }
      if(userBuff[5] == 'b'){
	std::cout << "mys belysning\n";
    int len = 10;
    char getdevso[10] = {0x00,0x00,0xFF,0xFF,0x03,0x01,0x0A,0x00,0x00,0x00};
    char getdevs[10];
    memcpy(&getdevs,&getdevso,10);
    int addr1 = 228;
    int addr2 = 101;
    getdevs[0] = (char)addr1;
    getdevs[1] = (char)addr2;
    
    // Type
    getdevs[7] |= (char)2;
    getdevs[7] <<= 1;

    // Group
    getdevs[7] |= 0b1; // Group action, just a default 1
    getdevs[7] <<= 2;
    
    // Method "METHOD(Dim:0,Off:1,On:2)="
    getdevs[7] |= (char)0;
    getdevs[7] <<= 1;

    // Numb
    getdevs[8] = (char)2;
    getdevs[8] <<= 4;
    
    // Level
    getdevs[8] |= (char)6;
    send(getdevs, len);
    sleep(1);


    memcpy(&getdevs,&getdevso,10);

    getdevs[0] = (char)addr1;
    getdevs[1] = (char)addr2;
    
    // Type
    getdevs[7] |= (char)2;
    getdevs[7] <<= 1;

    // Group
    getdevs[7] |= 0b1; // Group action, just a default 1
    getdevs[7] <<= 2;
    
    // Method "METHOD(Dim:0,Off:1,On:2)="
    getdevs[7] |= (char)1;
    getdevs[7] <<= 1;

    // Numb
    getdevs[8] = (char)1;
    getdevs[8] <<= 4;
    
    // Level
    getdevs[8] |= (char)15;
    send(getdevs, len);

      }
      if(userBuff[5] == 'c'){
	std::cout << "allt av belysning\n";
    int len = 10;
    char getdevso[10] = {0x00,0x00,0xFF,0xFF,0x03,0x01,0x0A,0x00,0x00,0x00};
    char getdevs[10];
    memcpy(&getdevs,&getdevso,10);
    int addr1 = 228;
    int addr2 = 101;
    getdevs[0] = (char)addr1;
    getdevs[1] = (char)addr2;
    
    // Type
    getdevs[7] |= (char)2;
    getdevs[7] <<= 1;

    // Group
    getdevs[7] |= 0b1; // Group action, just a default 1
    getdevs[7] <<= 2;
    
    // Method "METHOD(Dim:0,Off:1,On:2)="
    getdevs[7] |= (char)1;
    getdevs[7] <<= 1;

    // Numb
    getdevs[8] = (char)2;
    getdevs[8] <<= 4;
    
    // Level
    getdevs[8] |= (char)6;
    send(getdevs, len);
    sleep(1);


    memcpy(&getdevs,&getdevso,10);

    getdevs[0] = (char)addr1;
    getdevs[1] = (char)addr2;
    
    // Type
    getdevs[7] |= (char)2;
    getdevs[7] <<= 1;

    // Group
    getdevs[7] |= 0b1; // Group action, just a default 1
    getdevs[7] <<= 2;
    
    // Method "METHOD(Dim:0,Off:1,On:2)="
    getdevs[7] |= (char)1;
    getdevs[7] <<= 1;

    // Numb
    getdevs[8] = (char)1;
    getdevs[8] <<= 4;
    
    // Level
    getdevs[8] |= (char)15;
    send(getdevs, len);

      }
      close(connfd);
      sleep(1);
    }
}
