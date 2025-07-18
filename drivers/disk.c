#include "port.h"

static inline void io_delay(void) {
    __asm__ volatile ("jmp 1f\n1:");
}



void wait() {
    io_delay();
    while(1){
        unsigned char status = inb(0x1f7);

        if(!(status & 0x80) && (status & 0x08)) break;
        if(status & 0x01) break;
        if(status & 0x20) break;
    }
}


void read28pio(unsigned short *buffer, unsigned int LBA, unsigned char sectorCount, unsigned char slavebit) {

    // wait();
    while (inb(0x1F7) & 0x80);

    outb(0x1F6, 0xE0 | (slavebit << 4) | ((LBA >> 24) & 0x0F));
    outb(0x1F1, 0x00);
    outb(0x1F2, (unsigned char) sectorCount);
    outb(0x1F3, (unsigned char) LBA);
    outb(0x1F4, (unsigned char)(LBA >> 8));
    outb(0x1F5, (unsigned char)(LBA >> 16));
    outb(0x1F7, 0x20);


    for(int i = 0; i < sectorCount; i++) {
        wait();
        insw(0x1f0,buffer,256);
    }
}

void cache_flush() {
    outb(0x1F7, 0xE7);
    while(inb(0x1F7) & 0x80);
    (void)inb(0x1F7);
}


void write28pio(unsigned short *buffer, unsigned int LBA, unsigned char sectorCount, unsigned char slavebit) {
    // wait();
    while (inb(0x1F7) & 0x80);
    outb(0x1F6, 0xE0 | (slavebit << 4) | ((LBA >> 24) & 0x0F));
    outb(0x1F1, 0x00);
    outb(0x1F2, (unsigned char) sectorCount);
    outb(0x1F3, (unsigned char) LBA);
    outb(0x1F4, (unsigned char)(LBA >> 8));
    outb(0x1F5, (unsigned char)(LBA >> 16));
    outb(0x1F7, 0x30);

    for(int i = 0; i < sectorCount; i++) {
        wait();
        for(int j = 0; j < 256; j++){
            outw(0x1f0,buffer[i*256 + j]);
        }
    }
    cache_flush();
    for (volatile int k = 0; k < 1000; ++k); 

}
/*
    Send 0xE0 for the "master" or 0xF0 for the "slave", ORed with the highest 4 bits of the LBA to port 0x1F6:
    Send a NULL byte to port 0x1F1, if you like (it is ignored and wastes lots of CPU time): 
    Send the sectorcount to port 0x1F2:
    Send the low 8 bits of the LBA to port 0x1F3:
    Send the next 8 bits of the LBA to port 0x1F4: 
    Send the next 8 bits of the LBA to port 0x1F5: 
    Send the "READ SECTORS" command (0x20) to port 0x1F7:
    Wait for an IRQ or poll.
    Transfer 256 16-bit values, a uint16_t at a time, into your buffer from I/O port 0x1F0. (In assembler, REP INSW works well for this.)
    Then loop back to waiting for the next IRQ (or poll again -- see next note) for each successive sector.
*/


