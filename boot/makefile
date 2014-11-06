OUTPUT=../output
BOOTDIR=..
BOOTIMG=${BOOTDIR}/boot.img

all: mbr ${BOOTIMG}

run: all
	qemu-system-i386 ${BOOTIMG}

.PHONY: mbr
mbr: ${OUTPUT}/mbr.bin

${OUTPUT}:
	mkdir -p ${OUTPUT}

${BOOTIMG}: ${OUTPUT}/mbr.bin
	dd if=$^ of=$@ bs=512 count=1
	dd conv=notrunc if=/dev/zero of=$@ bs=512 count=32767 oseek=1

${OUTPUT}/%.bin: %.asm ${OUTPUT}
	nasm -f bin $< -o $@
