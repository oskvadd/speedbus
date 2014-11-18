all: build build/usb.hid.o build/ssl.socket.o build/spbgui build/spbserver

build: 
	mkdir build
build/spbserver: ssl.socket.cpp spb.server.cpp spb.backend.cpp http_post.cpp build build/usb.hid.o speedblib.cpp build/ssl.socket.o
	gcc -rdynamic -ggdb -I "/usr/local/ssl/include/" -o build/spbserver spb.server.cpp build/ssl.socket.o build/usb.hid.o -lserial `pkg-config --cflags --libs libconfig libusb-1.0 libssl  libcrypto` -lpthread -lmysqlclient -lstdc++
build/ssl.socket.o: ssl.socket.cpp
	g++ -ggdb -I "/usr/local/ssl/include/" -c -o build/ssl.socket.o ssl.socket.cpp
build/usb.hid.o: usb.hid.cpp
	gcc -ggdb -c -o build/usb.hid.o usb.hid.cpp 
build/spbgui: main.cpp http_post.cpp build/usb.hid.o build/ssl.socket.o spb.backend.cpp speedblib.cpp
	gcc -rdynamic -ggdb main.cpp -o build/spbgui build/ssl.socket.o build/usb.hid.o `pkg-config --cflags --libs gtk+-2.0 libconfig libserial libusb-1.0` -lssl -lcrypto -lm -lstdc++

spbserver: build/spbserver

aptlib: 
	sudo apt-get install libconfig8-dev libusb-1.0-0-dev libserial-dev libssl-dev libmysqlclient-dev libgtk2.0-dev screen

sinstall: build/spbserver	
	cp build/spbserver /usr/bin/
	if test ! -d /etc/spbserver/; then \
	mkdir /etc/spbserver/; \
	fi
	if test ! -d /etc/spbserver/usb/; then \
	mkdir /etc/spbserver/usb/; \
	fi
	if test ! -d /etc/spbserver/devs/; then \
	mkdir /etc/spbserver/devs/; \
	fi
	cp -f usb/*.hid /etc/spbserver/usb/
	cp -f devs/*.spb /etc/spbserver/devs/
	if test -r server/server.crt; then \
	cp -f server/server.cfg /etc/spbserver/; \
	cp server/server.crt /etc/spbserver/; \
	cp server/server.key /etc/spbserver/; \
	cp server/server.csr /etc/spbserver/; \
	else \
	./script/ssl.server-make.cert.pl; \
	cp -f server/server.cfg /etc/spbserver/; \
	cp server.crt /etc/spbserver/; \
	cp server.key /etc/spbserver/; \
	cp server.csr /etc/spbserver/; \
	fi
	if which screen >/dev/null; then \
	cp script/spbd /etc/init.d/; \
	chmod 755 /etc/init.d/spbd; \
	else \
	echo "ERROR: screen is not installed"; \
	exit 0; \
	fi 


install: sinstall build/spbgui
	cp build/spbgui /usr/bin/
	if test ! -d ~/.speedbus/; then \
	mkdir ~/.speedbus/; \
	fi
	if test ! -d ~/.speedbus/usb/; then \
	mkdir ~/.speedbus/usb/; \
	fi
	if test ! -d ~/.speedbus/devs/; then \
	mkdir ~/.speedbus/devs/; \
	fi
	cp -f usb/*.hid ~/.speedbus/usb/
	cp -f devs/*.spb ~/.speedbus/devs/
	cp -f spb.png ~/.speedbus/
