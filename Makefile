#
# Makefile
# romgrk, 2020-11-02 21:58
#

shared:
	gcc -c -Wall -fpic -o ./fzy/match.o ./fzy/match.c
	gcc -shared -o libfzy.so ./fzy/match.o


# vim:ft=make
#
