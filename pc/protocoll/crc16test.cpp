#include <iostream>
#include <stdlib.h>
#include <stdio.h>

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

using namespace std;

int main(){
  int  len = 5;
  char data[50] = {0xFF,0x03,0x01,0x30,0x00};
  crcstr(data,len);
  for(int i=0;i<(len+2);i++){
    std::cerr << std::hex << (static_cast<int>(data[i]) & 0xff) << " ";
  }
  cout << endl;
  if(crcstrc(data,len+2))
    std::cout << "Yippie" << endl;
  else
    std::cout << "Oops"   << endl;
}
