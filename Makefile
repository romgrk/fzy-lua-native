#
# Makefile
# romgrk, 2020-11-02 21:58
#

CC ?= gcc

CC_EXISTS := $(shell command -v $(CC) 2> /dev/null)
ifndef CC_EXISTS
CC=gcc
endif

OS=$(shell uname | tr A-Z a-z)
ifeq ($(findstring mingw,$(OS)), mingw)
    OS='windows'
else ifeq ($(OS), freebsd)
    OS='bsd'
endif

ARCH=$(shell uname -m)
ifeq ($(ARCH), aarch64)
ARCH='arm64'
else ifeq ($(ARCH), amd64)
ARCH='x86_64'
endif

all: ./static/libfzy-$(OS)-$(ARCH).so

./static/libfzy-$(OS)-$(ARCH).so: ./src/match.c
	$(CC) $(CFLAGS) -Ofast -c -Wall -static -fpic -o ./src/match.o $<
	$(CC) $(CFLAGS) -shared -o $@ ./src/match.o

clean:
	rm -f **/*.o


# vim:ft=make
#
