cmake_minimum_required(VERSION 3.27)

# Enable NASM
enable_language(ASM_NASM)
set(CMAKE_ASM_NASM_OBJECT_FORMAT elf64)
set(CMAKE_ASM_NASM_LINK_EXECUTABLE "ld <LINK_FLAGS> <OBJECTS> -o <TARGET> <LINK_LIBRARIES>") # Broken in 3.27

file(GLOB_RECURSE srcs CONFIGURE_DEPENDS src/*.nasm)

project(
	AssemblyGame
	DESCRIPTION "Pong made in assembly"
	VERSION 0.0.1
	LANGUAGES ASM_NASM
)

add_executable(AssemblyGame ${srcs})
