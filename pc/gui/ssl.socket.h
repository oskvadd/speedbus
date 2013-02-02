#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include <netdb.h>
#include <unistd.h>
#include <signal.h>
 
#ifdef __VMS
#include <types.h>
#include <socket.h>
#include <in.h>
#include <inet.h>
 
#else
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#endif
 
#include <openssl/crypto.h>
#include <openssl/ssl.h>
#include <openssl/err.h>

#include <fcntl.h>

#define MAX_LISTEN 10
#define RECV_MAX 1000 // Watch out for bugs, due i change this from 100 to 1000
#define MAX_LOGIN_TEXT 50


class sslserver {
  int     err;
  struct sockaddr_in sa_serv;
  struct sockaddr_in sa_cli;
  size_t client_len;
  char    *str;
  char    *buf;
  SSL_CTX         *ctx;
  SSL            *ssl;
  SSL_METHOD      *meth;
  X509            *client_cert;
  // select() parameters
  SSL **ssllist;
  //
public:
  bool * session_open;
  int *connectlist;
  int     listen_sock;
  int     sock;
  char **client_ip;

  fd_set socks; 
  struct timeval timeout;

  int     highsock;
  int     verify_client; /* To verify a client certificate, set ON */
  short int      s_port;
  sslserver();
  void loadssl();
  bool sslsocket();
  bool datarun(int listnum, char *data, int *len);
  int send_data(int listnum, const char *data, int len);
  int addclient();
  void runselect();
  void sslfree(int listnum);
  void run();
  void init_select();
  int  read_data(int listnum);

};

class sslclient {
  int         err;
  int         verify_client; /* To verify a client certificate, set ON */
  int         sock;
struct sockaddr_in server_addr;
  char        *str;
  char        buf[4096];
  char        *hello;


  SSL_CTX     *ctx;
  SSL         *ssl;
  SSL_METHOD  *meth;
  X509        *server_cert;
  EVP_PKEY    *pkey;
  const EVP_MD        * digest;
  unsigned char         md[EVP_MAX_MD_SIZE];
  unsigned int          n;

public:
  sslclient();
  bool sslsocket(const char *s_ipaddr, short int s_port);
  bool loadssl();
  bool send_data(const char *msg, int len);
  bool sslfree();
  int find_known_hosts(char *host_entry);
  bool add_known_hosts(char *host_entry);
  void get_ssl_finger(char *finger);
  int recv_data(char *data);
};
