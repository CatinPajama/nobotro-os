// read data from pin
unsigned char inb(unsigned short port);
void outb(unsigned short port, unsigned char data);
void insw(unsigned short port, void *addr, unsigned int count);