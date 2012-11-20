CC=gcc
CFLAGS=-g -Wall -fPIC
LDFLAGS=-llua -shared

.PHONY: all clean

all: cext.so

cext.so: cext.o
	$(CC) $(LDFLAGS) -o $@ $<

clean:
	-rm cext.o cext.so
