all: test usb_hid
test: test.rev*.c
	gcc -DLINUX test.rev*.c -o test /usr/lib/i386-linux-gnu/libusb-1.0.a -lrt
usb_hid: usb.hid.c
	gcc -DLINUX usb.hid.c -o usb_hid `pkg-config --cflags --libs libconfig libusb-1.0` -lrt