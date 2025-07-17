// read data from pin
unsigned char inb(unsigned short port)
{

    unsigned char result;
    __asm__("in %%dx,%%al" : "=a"(result) : "d"(port));
    return result;
}

// write data to pin
void outb(unsigned short port, unsigned char data)
{

    __asm__("out %%al,%%dx" : : "a"(data), "d"(port));
}

void insw(unsigned short port, void *addr, unsigned int count)
{
    __asm__ volatile(
        "rep insw"
        : "+D"(addr), "+c"(count)
        : "d"(port)
        : "memory");
}
