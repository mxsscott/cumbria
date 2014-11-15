OUTPUT=../output
BOOTDIR=..
BOOTIMG=${BOOTDIR}/boot.img

.PHONY: mbr all clean run debug
all: ${BOOTIMG}

clean:
		rm ${BOOTIMG}
		rm -r ${OUTPUT}

run: all
	qemu-system-i386 ${BOOTIMG}

debug: all
	qemu-system-i386 -S -s ${BOOTIMG}

${BOOTIMG}: ${OUTPUT}/mbr.bin
	dd if=${OUTPUT}/mbr.bin of=$@ bs=512 count=1
	dd conv=notrunc if=/dev/zero of=$@ bs=512 count=32767 oseek=1

${OUTPUT}:
	mkdir -p ${OUTPUT}

${OUTPUT}/%.bin: %.asm ${OUTPUT}
	nasm -f bin $< -o $@
