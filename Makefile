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
endif

ARCH=$(shell uname -m)
ifeq ($(ARCH), aarch64)
ARCH='arm64'
endif

all:
	echo $(ARCH)
	mkdir -p build
	mkdir -p static # because someone used it before from this folder, I guess.
	$(CC) $(CFLAGS) -Ofast -c -Wall -static -fpic -o ./build/match.o ./src/match.c
	$(CC) $(CFLAGS) -shared -L ./src ./build/match.o -o ./static/libfzy-$(OS)-$(ARCH).so 


# vim:ft=make
#
