#!/usr/bin/perl -w

if(!(-e "/usr/bin/openssl")){
    print("* OpenSSL does not seem to be installed\n");
}
if((-e "server.key") || (-e "server.csr") || (-e "server.crt")){
    print("* The existing cert will be removed, do you want to proceed? [y/N]: ");
    while(1){
    $stdin = <>;
    $stdin = substr($stdin,0,1);
    if($stdin =~ m/y/i){
	last;
    }
    if($stdin =~ m/n/i || length($stdin) < 2){
	exit;
    }
    print("* Y or N please: ");
    }
    system("rm -rf server.key server.csr server.crt");
}
print("* Step 1: make private key (server.key)\n");
system("openssl genrsa -out server.key 1024");
print("* Step 2: Generate a CSR (Certificate Signing Request).\n");
system("openssl req -new -key server.key -out server.csr");
print("* Step 3: Generate a Self-Signed Certificate\n");
system("openssl x509 -req -days 3650 -in server.csr -signkey server.key -out server.crt");
