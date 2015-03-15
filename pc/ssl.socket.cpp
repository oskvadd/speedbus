/*
 * ++
 * FACILITY:
 *
 *      Simplest SSL Server
 *
 * ABSTRACT:
 *
 *   This is an example of a SSL server with minimum functionality.
 *    The socket APIs are used to handle TCP/IP operations. This SSL
 *    server loads its own certificate and key, but it does not verify
 *  the certificate of the SSL client.
 *
 *  Thanks to hp, for greate example at the ssl connection
 *  http://h71000.www7.hp.com/doc/83final/ba554_90007/ch05s04.html
 * And thanks to http://www.lowtek.com/sockets/select.html 
 * For info on how to implement select() :) // Speedster
*/

#include "ssl.socket.h"

#define RSA_SERVER_CERT     "/etc/spbserver/server.crt"
#define RSA_SERVER_KEY          "/etc/spbserver/server.key"

#define RSA_SERVER_CA_CERT "server_ca.crt"
#define RSA_SERVER_CA_PATH   "sys$common:[syshlp.examples.ssl]"

#define RSA_CLIENT_CERT       "client.crt"
#define RSA_CLIENT_KEY  "client.key"

#define RSA_CLIENT_CA_CERT      "client.crt"
#define RSA_CLIENT_CA_PATH      "sys$common:[syshlp.examples.ssl]"


#define ON   1
#define OFF  0

#define RETURN_NULL(x) if ((x)==NULL) {return 0;}
#define RETURN_ERR(err,s) if ((err)==-1) { perror(s); return 0;}
#define RETURN_SSL(err) if ((err)==-1) { ERR_print_errors_fp(stderr); return 0;}


sslserver::sslserver()
{
  verify_client = 0;
  buf = new char[4096];
  client_ip = new char *[MAX_LISTEN];
  for (int i = 0; i < MAX_LISTEN; i++)
    client_ip[i] = new char[16];	// Max IP in chars 
  connectlist = new int[MAX_LISTEN];
  for (int i = 0; i < MAX_LISTEN; i++)
    connectlist[i] = 0;
  ssllist = new SSL *[MAX_LISTEN];
  for (int i = 0; i < MAX_LISTEN; i++)
    ssllist[i] = new SSL;
  timeout.tv_sec = 5;
  timeout.tv_usec = 0;
  verify_client = 0;		/* To verify a client certificate, set 1  */
  s_port = 306;
  client_cert = NULL;
  session_open = new bool[MAX_LISTEN];
}

void
sslserver::loadssl()
{
  /*----------------------------------------------------------------*/
  /*
   * Load encryption & hashing algorithms for the SSL program 
   */
  SSL_library_init();
  /*
   * Load the error strings for SSL & CRYPTO APIs 
   */
  SSL_load_error_strings();
  /*
   * Create a SSL_METHOD structure (choose a SSL/TLS protocol version) 
   */
  meth = (SSL_METHOD *) SSLv3_method();
  /*
   * Create a SSL_CTX structure 
   */
  ctx = SSL_CTX_new(meth);
  if (!ctx)
    {
      ERR_print_errors_fp(stderr);
      exit(1);
    }

  /*
   * Load the server certificate into the SSL_CTX structure 
   */
  if (SSL_CTX_use_certificate_file(ctx, RSA_SERVER_CERT, SSL_FILETYPE_PEM) <= 0)
    {
      ERR_print_errors_fp(stderr);
      exit(1);

    }

  /*
   * Load the private-key corresponding to the server certificate 
   */
  if (SSL_CTX_use_PrivateKey_file(ctx, RSA_SERVER_KEY, SSL_FILETYPE_PEM) <= 0)
    {
      ERR_print_errors_fp(stderr);
      exit(1);
    }

  /*
   * Check if the server certificate and private-key matches 
   */
  if (!SSL_CTX_check_private_key(ctx))
    {
      fprintf(stderr, "Private key does not match the certificate public key\n");
      exit(1);
    }

  if (verify_client == ON)
    {
      /*
       * Load the RSA CA certificate into the SSL_CTX structure 
       */
      if (!SSL_CTX_load_verify_locations(ctx, RSA_SERVER_CA_CERT, NULL))
	{
	  ERR_print_errors_fp(stderr);
	  exit(1);
	}
      /*
       * Set to require peer (client) certificate verification 
       */
      SSL_CTX_set_verify(ctx, SSL_VERIFY_PEER, NULL);
      /*
       * Set the verification depth to 1 
       */
      SSL_CTX_set_verify_depth(ctx, 1);
    }

}

bool
sslserver::sslsocket()
{
  /*
   * ----------------------------------------------- 
   */
  /*
   * Set up a TCP socket 
   */
  listen_sock = socket(PF_INET, SOCK_STREAM, IPPROTO_TCP);
  RETURN_ERR(listen_sock, "socket");
  memset(&sa_serv, 0x00, sizeof(sa_serv));
  sa_serv.sin_family = AF_INET;
  sa_serv.sin_addr.s_addr = INADDR_ANY;
  sa_serv.sin_port = htons(s_port);	/* Server Port number */

  int tr = 1;

  // kill "Address already in use" error message
  if (setsockopt(listen_sock, SOL_SOCKET, SO_REUSEADDR, &tr, sizeof(int)) == -1)
    {
      perror("setsockopt");
      exit(1);
    }

  struct timeval timeout;
  timeout.tv_sec = 10;
  timeout.tv_usec = 0;
  if (setsockopt(listen_sock, SOL_SOCKET, SO_RCVTIMEO, (char *)&timeout, sizeof(timeout)) < 0 ||
      setsockopt(listen_sock, SOL_SOCKET, SO_SNDTIMEO, (char *)&timeout, sizeof(timeout)) < 0){
    perror("setsockopt()");
    exit(EXIT_FAILURE);
  }

  /* Set the option active */
  int keepalive = 1;
  int keepcnt = 3;
  int keepidle = 60;
  int keepintvl = 60;

  if(setsockopt(listen_sock, SOL_SOCKET, SO_KEEPALIVE, &keepalive, sizeof(keepalive)) < 0 ||
     setsockopt(listen_sock, IPPROTO_TCP, TCP_KEEPCNT, &keepcnt, sizeof(int)) < 0 ||
     setsockopt(listen_sock, IPPROTO_TCP, TCP_KEEPIDLE, &keepidle, sizeof(int)) < 0 ||
     setsockopt(listen_sock, IPPROTO_TCP, TCP_KEEPINTVL, &keepintvl, sizeof(int)) < 0){
    perror("setsockopt()");
    exit(EXIT_FAILURE);
  }
  err = bind(listen_sock, (struct sockaddr *)&sa_serv, sizeof(sa_serv));
  RETURN_ERR(err, "bind");
  /*
   * Wait for an incoming TCP connection. 
   */
  err = listen(listen_sock, MAX_LISTEN);

  RETURN_ERR(err, "listen");
  client_len = sizeof(sa_cli);

  highsock = listen_sock;
  FD_ZERO(&socks);
  FD_SET(listen_sock, &socks);
  return 1;
}

int
sslserver::read_data(int listnum)
{
  int errc = 0;
  timeout.tv_sec = 5;
  timeout.tv_usec = 0;
  while (1)
    {
      err = SSL_read(ssllist[listnum], buf + errc, 4096 - (1 + errc));
      errc += err;
      RETURN_SSL(err);

      // Pretty messy fix, but there was a problem with the android interface
      // that the server recived packages in two pices, first byte in one pice
      // and the rest of the bytes in the other pice, therefore we make sure that
      // the packages is lager than 1
      if (!SSL_pending(ssllist[listnum]) && errc > 1)
	break;
    }
  
  if (err < 0)
    {
      return -1;
    }
  buf[errc] = '\0';
  return errc;
}

bool
sslserver::datarun(int listnum, char *data, int *len)
{
  int errc = this->read_data(listnum);
  if (errc < 1)
    {
      if (errc == 0 && session_open[listnum] == 0)	// If this is an inalization package, with none open session, and no data. just return
	return 0;
      // Do this at cewd side instead
      //    printf("Connection from %s died, Cya\n", client_ip[listnum]);
      //    this->sslfree(listnum);
      return 0;
    }
  if (errc > RECV_MAX)
    errc = RECV_MAX;
  memcpy(data, buf, errc + 1);
  *len = errc;
  return 1;

}

int
sslserver::send_data(int listnum, const char *data, int len)
{
  if(listnum < 0)
    return 0;
  
  if(!connectlist[listnum])
    return 0;
  return SSL_write(ssllist[listnum], data, len);
}

void
sslserver::sslfree(int listnum)
{
  /*--------------- SSL closure ---------------*/
  /*
   * Shutdown this side (server) of the connection. 
   */
  //err = SSL_shutdown(ssllist[listnum]);
  //RETURN_SSL(err);
  /*
   * Free the SSL structure 
   */
  SSL_free(ssllist[listnum]);
  /*
   * Free the SSL_CTX structure 
   */
  //SSL_CTX_free(ctx);
  FD_CLR(connectlist[listnum], &socks);
  close(connectlist[listnum]);
  connectlist[listnum] = 0;
  session_open[listnum] = 0;
}

int
sslserver::addclient()
{

  int listnum;			/* Current item in connectlist for for loops */
  int connection;		/* Socket file descriptor for incoming connections */

  /*
   * We have a new connection coming in!  We'll
   * try to find a spot for it in connectlist. 
   */
  struct sockaddr_in saddr;
  socklen_t len = sizeof(saddr);

  connection = accept(listen_sock, (struct sockaddr *)&saddr, &len);
  if (connection < 0)
    {
      perror("accept");
      // exit(EXIT_FAILURE);
    }
  // setnonblocking(connection);
  if (connection < 0)
    return 0;

  for (listnum = 0; listnum < MAX_LISTEN; listnum++)
    {
      if (connectlist[listnum] == 0)
	{
	  //printf("\nConnection accepted:   FD=%d; Slot=%d\n",
	  //       connection,listnum);
	  connectlist[listnum] = connection;
	  connection = -1;
	  if (connectlist[listnum] > highsock)
	    highsock = connectlist[listnum];

	  FD_SET(connectlist[listnum], &socks);

	  /*
	   * ----------------------------------------------- 
	   */
	  /*
	   * TCP connection is ready. 
	   */
	  /*
	   * A SSL structure is created 
	   */
	  ssllist[listnum] = SSL_new(ctx);

	  RETURN_NULL(ssllist[listnum]);

	  /*
	   * Assign the socket into the SSL structure (SSL and socket without BIO) 
	   */
	  SSL_set_fd(ssllist[listnum], connectlist[listnum]);

	  /*
	   * Perform SSL Handshake on the SSL server 
	   */
	  err = SSL_accept(ssllist[listnum]);

	  RETURN_SSL(err);

	  /*
	   * Informational output (optional) 
	   */
	  //printf("SSL connection using %s\n", SSL_get_cipher (ssllist[listnum]));

	  if (verify_client == ON)
	    {

	      /*
	       * Get the client's certificate (optional) 
	       */
	      client_cert = SSL_get_peer_certificate(ssllist[listnum]);
	      if (client_cert != NULL)
		{

		  printf("Client certificate:\n");
		  str = X509_NAME_oneline(X509_get_subject_name(client_cert), 0, 0);
		  RETURN_NULL(str);
		  printf("\t subject: %s\n", str);
		  free(str);
		  str = X509_NAME_oneline(X509_get_issuer_name(client_cert), 0, 0);
		  RETURN_NULL(str);
		  printf("\t issuer: %s\n", str);
		  free(str);
		  X509_free(client_cert);
		}

	      else

		printf("The SSL client does not have certificate.\n");
	    }

	  inet_ntop(AF_INET, &saddr.sin_addr, client_ip[listnum], 16);


	  if (err < 0)
	    {
	      this->sslfree(listnum);
	      return 0;
	    }
	  //  this->datarun(listnum);
	  return listnum;
	}

    }
  if (connection != -1)
    {
      /*
       * No room left in the queue! 
       */
      printf("\nNo room left for new client.\n");
      close(connection);
    }

}

void
sslserver::runselect()
{


  if (FD_ISSET(listen_sock, &socks))
    this->addclient();

  char data[RECV_MAX];
  int len;
  for (int listnum = 0; listnum < MAX_LISTEN; listnum++)
    {
      if (FD_ISSET(connectlist[listnum], &socks))
	this->datarun(listnum, data, &len);
    }

}

void
sslserver::init_select()
{
  int listnum;			/* Current item in connectlist for for loops */

  /*
   * First put together fd_set for select(), which will
   * consist of the sock veriable in case a new connection
   * is coming in, plus all the sockets we have already
   * accepted. 
   */


  /*
   * FD_ZERO() clears out the fd_set called socks, so that
   * it doesn't contain any file descriptors. 
   */

  FD_ZERO(&socks);

  /*
   * FD_SET() adds the file descriptor "sock" to the fd_set,
   * so that select() will return if a connection comes in
   * on that socket (which means you have to do accept(), etc. 
   */

  FD_SET(listen_sock, &socks);

  /*
   * Loops through all the possible connections and adds
   * those sockets to the fd_set 
   */

  for (listnum = 0; listnum < MAX_LISTEN; listnum++)
    {
      if (connectlist[listnum] != 0)
	{
	  FD_SET(connectlist[listnum], &socks);
	  if (connectlist[listnum] > highsock)
	    highsock = connectlist[listnum];
	}
    }
}

void
sslserver::run()
{
  int sock;
  while (1)
    {
      this->init_select();

      sock = select(highsock + 1, &socks, NULL, NULL, NULL);
      if (sock > 0)
	this->runselect();
      if (sock < 0)
	printf("select error: %d", sock);
    }
}


sslclient::sslclient()
{
  verify_client = OFF;
  hello = new char[80];
}


bool
sslclient::sslsocket(const char *s_ipaddr, short int s_port)
{
/* ------------------------------------------------------------- */
/* Set up a TCP socket */

  sock = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);

  RETURN_ERR(sock, "socket");

  memset(&server_addr, '\0', sizeof(server_addr));
  server_addr.sin_family = AF_INET;
  server_addr.sin_port = htons(s_port);	/* Server Port number */
  server_addr.sin_addr.s_addr = inet_addr(s_ipaddr);	/* Server IP */

/* Establish a TCP/IP connection to the SSL client */

  struct timeval timeout;
  timeout.tv_sec = 5;
  timeout.tv_usec = 0;
  setsockopt(sock, SOL_SOCKET, SO_RCVTIMEO, (char *)&timeout, sizeof(timeout));
  setsockopt(sock, SOL_SOCKET, SO_SNDTIMEO, (char *)&timeout, sizeof(timeout));
  err = connect(sock, (struct sockaddr *)&server_addr, sizeof(server_addr));
  if (err < 0)
    return 0;
  //RETURN_ERR(err, "connect");
  return 1;
}

bool
sslclient::loadssl()
{
/* Load encryption & hashing algorithms for the SSL program */
  SSL_library_init();

/* Load the error strings for SSL & CRYPTO APIs */
  SSL_load_error_strings();

/* Create an SSL_METHOD structure (choose an SSL/TLS protocol version) */
  meth = (SSL_METHOD *) SSLv3_method();

/* Create an SSL_CTX structure */
  ctx = SSL_CTX_new(meth);

  RETURN_NULL(ctx);
/*----------------------------------------------------------*/
  if (verify_client == ON)
    {

      /*
       * Load the client certificate into the SSL_CTX structure 
       */
      if (SSL_CTX_use_certificate_file(ctx, RSA_CLIENT_CERT, SSL_FILETYPE_PEM) <= 0)
	{
	  ERR_print_errors_fp(stderr);
	  exit(1);
	}

      /*
       * Load the private-key corresponding to the client certificate 
       */
      if (SSL_CTX_use_PrivateKey_file(ctx, RSA_CLIENT_KEY, SSL_FILETYPE_PEM) <= 0)
	{
	  ERR_print_errors_fp(stderr);
	  exit(1);
	}

      /*
       * Check if the client certificate and private-key matches 
       */
      if (!SSL_CTX_check_private_key(ctx))
	{
	  fprintf(stderr, "Private key does not match the certificate public key\n");
	  exit(1);
	}
    }

/* Load the RSA CA certificate into the SSL_CTX structure */
/* This will allow this client to verify the server's     */
/* certificate.                                           */


//if (!SSL_CTX_load_verify_locations(ctx, RSA_CLIENT_CA_CERT, NULL)) {
//  printf("%d\n", SSL_CTX_load_verify_locations(ctx, RSA_CLIENT_CA_CERT, NULL));
//  ERR_print_errors_fp(stderr);
//  exit(1);
//_ }

/* Set flag in context to require peer (server) certificate */
/* verification */

//SSL_CTX_set_verify(ctx,SSL_VERIFY_PEER,NULL);
//SSL_CTX_set_verify_depth(ctx,1);
/* ----------------------------------------------- */
/* An SSL structure is created */

  ssl = SSL_new(ctx);
  RETURN_NULL(ssl);

/* Assign the socket into the SSL structure (SSL and socket without BIO) */
  SSL_set_fd(ssl, sock);

/* Perform SSL Handshake on the SSL client */
  err = SSL_connect(ssl);
  RETURN_SSL(err);


/* Get the server's certificate (optional) */
  server_cert = SSL_get_peer_certificate(ssl);


/* Informational output (optional) */
#ifdef IS_GUI
  printf("SSL connection using %s\n", SSL_get_cipher(ssl));
#endif  

  if (server_cert != NULL)
    {
      return 1;
    }
  else
    printf("The SSL server does not have certificate.\n");
  return 0;
}

void
sslclient::get_ssl_finger(char *finger)
{

  /*
   * No use right now, but saving, just in case
   * printf ("Server certificate:\n");
   * 
   * str = X509_NAME_oneline(X509_get_subject_name(server_cert),0,0);
   * RETURN_NULL(str);
   * printf ("\t subject: %s\n", str);
   * free (str);
   * 
   * str = X509_NAME_oneline(X509_get_issuer_name(server_cert),0,0);
   * RETURN_NULL(str);
   * printf ("\t issuer: %s\n", str);
   * free(str);
   * 
   */

  // calculate & print fingerprint
  digest = EVP_get_digestbyname("md5");
  X509_digest(server_cert, digest, md, &n);
  X509_free(server_cert);
  finger[0] = '\0';
  for (int pos = 0; pos < 15; pos++)
    sprintf(finger, "%s%02x:", finger, md[pos]);
  sprintf(finger, "%s%02x", finger, md[15]);
  // Fingerprint Gets stored in md 16 bytes 0-15
  return;
}

int
sslclient::find_known_hosts(char *host_entry)
{
  FILE *file = fopen(".speedbus/known_hosts", "r");
  if (file != NULL)
    {
      char line[128];		/* or other suitable maximum line size */
      int s_end = (int)(strchr(host_entry, '|') - host_entry + 1);
      bool mime_flag = 0;
      bool cert_found = 0;

      while (fgets(line, sizeof(line), file) != NULL)
	{			/* read a line */
	  if (strncmp(line, host_entry, strlen(host_entry)) == 0)
	    {
	      fclose(file);
	      return 1;
	    }
	  if (strncmp(line, host_entry, s_end) == 0)
	    mime_flag = 1;
	  if (strncmp(line + s_end, host_entry + s_end, strlen(host_entry) - s_end) == 0)
	    cert_found = 1;
	}
      fclose(file);
      if (mime_flag)
	return -1;
      if (cert_found)
	return 2;
      return 0;
    }
  else
    {
      return 0;
    }
}

bool
sslclient::add_known_hosts(char *host_entry)
{
  FILE *fp;
  fp = fopen(".speedbus/known_hosts", "a");
  if (!fp)
    return 0;
  fprintf(fp, "%s\n", host_entry);
  fclose(fp);
  return 1;
}

int
sslclient::recv_data(char *data)
{
  int err;
  char data_t[RECV_MAX];
  if (err = SSL_read(ssl, data, RECV_MAX))
    {
      data[err] = '\0';
      return err;
    }
  else
    return 0;
}

bool
sslclient::send_data(const char *msg, int len)
{
  /*-------- DATA EXCHANGE - send message and receive reply. -------*/
  /*
   * Send data to the SSL server 
   */
  err = SSL_write(ssl, msg, len);
  RETURN_SSL(err);
  return 1;
}

bool
sslclient::sslfree()
{
/*--------------- SSL closure ---------------*/
/* Shutdown the client side of the SSL connection */
  err = SSL_shutdown(ssl);
  RETURN_SSL(err);

/* Terminate communication on a socket */
  err = close(sock);
  RETURN_ERR(err, "close");

/* Free the SSL structure */
  SSL_free(ssl);
/* Free the SSL_CTX structure */
  SSL_CTX_free(ctx);
}
