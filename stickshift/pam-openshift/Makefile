# Installation directories.
PREFIX ?= $(DESTDIR)/usr
INCLUDEDIR ?= $(PREFIX)/include
SHLIBDIR ?= /lib

VERSION = $(shell cat ../VERSION)
LIBVERSION = 1

TARGET=pam_openshift.so
LIBPC=pam_openshift.pc
LIBSO=$(TARGET).$(LIBVERSION)
OBJS= $(patsubst %.c,%.o,$(wildcard *.c))
LOBJS= $(patsubst %.c,%.lo,$(wildcard *.c))
CFLAGS ?= -Werror -Wall -W -Wundef -Wshadow -Wmissing-noreturn -Wmissing-format-attribute
override CFLAGS += -I. -I../include -D_GNU_SOURCE

all: $(LIBSO)

$(LIBSO): $(LOBJS)
	$(CC) $(CFLAGS) $(LDFLAGS) -shared -o $@ $^ -Wl,-soname,$(LIBSO),-z,defs -lselinux -lpam -lattr
	ln -sf $@ $(TARGET)

%.o:  %.c 
	$(CC) $(CFLAGS) -fPIC -c -o $@ $<

%.lo:  %.c
	$(CC) $(CFLAGS) -fPIC -DSHARED -c -o $@ $<

install: all
	test -d $(DESTDIR)$(SHLIBDIR)/security || install -m 755 -d $(DESTDIR)$(SHLIBDIR)/security
	install -m 755 $(LIBSO) $(DESTDIR)$(SHLIBDIR)/security

relabel:
	/sbin/restorecon $(SHLIBDIR)/$(LIBSO)

clean: 
	-rm -f $(OBJS) $(LOBJS) $(LIBSO) $(TARGET) \#* *~
