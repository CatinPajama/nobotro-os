CFLAGS = -g -ffreestanding -fno-stack-protector -fno-pie -m32 -Iinclude -Wno-int-conversion -Wno-implicit-function-declaration
BUILD_DIR=build
IMAGE=nobotro_os.img

C_SRC := $(wildcard */*.c)
C_OBJ := $(addprefix $(BUILD_DIR)/, $(notdir $(C_SRC:.c=.o)))

BOOTLOADER_ASM := boot/bootloader.asm
KERNELHEAD_ASM := kernel/kernel_head.asm


$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

$(BUILD_DIR)/%.o: */%.c $(BUILD_DIR)
	gcc $(CFLAGS) -c $< -o $@

$(BUILD_DIR)/kernel_head.o: $(KERNELHEAD_ASM) $(BUILD_DIR)
	nasm -f elf32 $< -o $@

$(BUILD_DIR)/bootloader.bin: $(BOOTLOADER_ASM) $(BUILD_DIR)
	nasm -f bin $< -o $@

$(BUILD_DIR)/kernel.bin: $(C_OBJ) $(BUILD_DIR)/kernel_head.o
	ld -m elf_i386 -T link.ld -o $@ $(BUILD_DIR)/kernel_head.o $(C_OBJ) --oformat binary 

image: $(BUILD_DIR)/bootloader.bin $(BUILD_DIR)/kernel.bin
	dd if=/dev/zero of=$(IMAGE) bs=512 count=2880
	mkfs.fat -F 12 -n "NOBOTRO" $(IMAGE)
	dd if=$(BUILD_DIR)/bootloader.bin of=$(IMAGE) conv=notrunc
	mcopy -i $(IMAGE) $(BUILD_DIR)/kernel.bin "::kernel.bin"

clean:
	rm -rf $(BUILD_DIR)

all: image clean

debug: $(IMAGE)
	qemu-system-x86_64 $(IMAGE) -s -S


flash:
	dd if=/dev/zero bs=512 count=200 of=/dev/sdb
	dd if=$(IMAGE) of=/dev/sdb

emu:
	qemu-system-x86_64 $(IMAGE)
