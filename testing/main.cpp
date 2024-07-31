#include <X11/Xlib.h> // Every Xlib program must include this
#include <assert.h>   // I include this to test return values the lazy way
#include <unistd.h>   // So we got the profile for 10 seconds
#include <iostream>


int main(){
	std::cout << KeyPress << std::endl;
	std::cout << KeyRelease << std::endl;
	return 0;
}
