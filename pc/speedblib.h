
short crcsum(char * data, int len);
void crcstr(char * data, int len);
bool crcstrc(char * data, int len);
int unescape(char * data, int * len);
int escape(char * data, int * len);
void *print_ser(void *ptr);
void    send(char * data, int len);
void    send_response(char addr_1, char addr_2);
