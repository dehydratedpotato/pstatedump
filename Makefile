
CC = swiftc

pstatedump: main.swift
	$(CC) -o $@ $^
clean:
	rm -rf ./pstatedump *.o
