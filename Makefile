-include Makefile.d/*.mk

.PHONY: all update docker-update backup

all: update docker-update backup
