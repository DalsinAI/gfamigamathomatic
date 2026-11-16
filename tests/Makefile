# PC tests: make test (host-matho.sh fetches Mathomatic at mathomatic.lock's commit)
CC ?= cc
test:
	sh test-part.sh
	mkdir -p ../build-host
	$(CC) -Wall -Wextra -I../amiga -o ../build-host/matho_test matho_test.c ../amiga/amiga_matho.c -lm && ../build-host/matho_test
	sh host-matho.sh
.PHONY: test
