all: compile install

compile:
	gcc -g -o oo-gear-init oo-gear-init.c -lpthread

install:
	cp oo-gear-init /usr/sbin/oo-gear-init
	chown root:root /usr/sbin/oo-gear-init
	chmod 4755 /usr/sbin/oo-gear-init
