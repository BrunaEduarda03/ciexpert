# unix/linux
# main:
# 	g++ -Wall -std=c++0x -lcryptopp -o prog main.cpp 
# 	./prog

# macos
CRYPTOPP := $(shell brew --prefix cryptopp)

main:
	g++ -Wall -std=c++11 -I$(CRYPTOPP)/include -L$(CRYPTOPP)/lib -o prog main.cpp -lcryptopp
	./prog

clean:
	rm -rf prog
