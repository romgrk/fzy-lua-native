#
# Makefile
# romgrk, 2020-11-02 21:58
#

CC=cc
OS=`uname | tr A-Z a-z`
ARCH=`uname -m`

all:
	$(CC) -c -Wall -static -fpic -o ./src/match.o ./src/match.c
	$(CC) -shared -o ./static/libfzy-$(OS)-$(ARCH).so ./src/match.o


# vim:ft=make
#
