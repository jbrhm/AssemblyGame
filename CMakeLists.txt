cmake_minimum_required(VERSION 3.27)

# Enable NASM
set(CMAKE_ASM_NASM_OBJECT_FORMAT "elf64") # This needs to go before the enable_language(ASM_NASM) call
enable_language(ASM_NASM)
set(CMAKE_ASM_NASM_LINK_EXECUTABLE "ld <LINK_FLAGS> <OBJECTS> -o <TARGET> <LINK_LIBRARIES>") # Broken in 3.27

set(CMAKE_ASM_NASM_FLAGS "-g -Fdwarf")

file(GLOB_RECURSE srcs CONFIGURE_DEPENDS src/*.nasm)

project(
	AssemblyGame
	DESCRIPTION "Pong made in assembly"
	VERSION 0.0.1
	LANGUAGES ASM_NASM
)

add_executable(AssemblyGame ${srcs})

target_link_libraries(AssemblyGame PRIVATE X11)
target_link_options(AssemblyGame PRIVATE --dynamic-linker /lib64/ld-linux-x86-64.so.2) # Required to find the executable
