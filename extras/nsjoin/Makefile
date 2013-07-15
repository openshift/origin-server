all: compile install

compile:
	gcc -g -o nsjoin nsjoin.c -lselinux -lvirt -lvirt-lxc -lcap-ng -lutil

install:
	cp nsjoin /usr/bin/nsjoin
	chown root:root /usr/bin/nsjoin
	chmod 4755 /usr/bin/nsjoin
