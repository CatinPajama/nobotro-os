CFLAGS = -g -ffreestanding -fno-stack-protector -fno-pie -m32 -Iinclude -Wno-int-conversion -Wno-implicit-function-declaration

all:
	nasm -f bin ./boot/bootloader.asm -o bootloader.bin
	gcc $(CFLAGS) -c ./util/port.c -o port.o
	gcc $(CFLAGS) -c ./kernel/kernel.c -o kernel.o
	gcc $(CFLAGS) -c ./lib/stdio.c -o stdio.o
	gcc $(CFLAGS) -c ./lib/stdlib.c -o stdlib.o
	gcc $(CFLAGS) -c ./lib/string.c -o string.o
	gcc $(CFLAGS) -c ./drivers/video.c -o video.o
	gcc $(CFLAGS) -c ./drivers/disk.c -o disk.o
	gcc $(CFLAGS) -c ./drivers/keyboard.c -o keyboard.o
	nasm -f elf32 ./kernel/kernel_head.asm -o kernel_head.o
	ld -m elf_i386 -T link.ld -o kernel.elf kernel_head.o kernel.o stdlib.o stdio.o string.o video.o keyboard.o port.o disk.o
	ld -m elf_i386 -T link.ld -o kernel.bin kernel_head.o kernel.o stdlib.o stdio.o string.o video.o keyboard.o port.o disk.o --oformat binary
	cat bootloader.bin kernel.bin > ./nobotro_os.img
	truncate -s 10240 nobotro_os.img
	rm *.bin *.o

debug: ../nobotro_os.img
	qemu-system-x86_64 ../nobotro_os.img -s -S


flash:
	dd if=/dev/zero bs=512 count=200 of=/dev/sdb
	dd if=../nobotro_os.img of=/dev/sdb

emu:
	qemu-system-x86_64 ./nobotro_os.img
