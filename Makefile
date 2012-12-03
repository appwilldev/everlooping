.PHONY: all clean

all: libngxc.so

libngxc.so: ngxc.c
	$(CC) -Wall -shared -fPIC $< -o $@

clean:
	-rm libngxc.so
