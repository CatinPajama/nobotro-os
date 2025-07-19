#include "filesystem.h"
#include "disk.h"
#include "video.h"

unsigned short readNextCluster(struct BootSector *bs, int active_cluster)
{
    const int first_fat_sector = bs->ReservedSectors;
    const int sector_size = bs->BytesPerSector;
    unsigned char FAT_table[sector_size * 2];                        // needs two in case we straddle a sector
    unsigned int fat_offset = active_cluster + (active_cluster / 2); // multiply by 1.5
    unsigned int fat_sector = first_fat_sector + (fat_offset / sector_size);
    unsigned int ent_offset = fat_offset % sector_size;

    read28pio((void*)FAT_table,fat_sector,2,0);
    // unsigned char buffer8[sector_size * 2];
    // for (int i = 0; i < sector_size; ++i) {
    //     buffer8[i * 2]     = FAT_table[i] & 0xFF;         // LSB
    //     buffer8[i * 2 + 1] = (FAT_table[i] >> 8) & 0xFF;  // MSB
    // }
    //at this point you need to read two sectors from disk starting at "fat_sector" into "FAT_table".
    unsigned short table_value = *(unsigned short*)&FAT_table[ent_offset];
    table_value = (active_cluster & 1) ? table_value >> 4 : table_value & 0xfff;
    return table_value;
}

void printFilename(char *filename, char* ext)
{
    for (int i = 0; i < 8; i++)
    {
        if(filename[i] == ' ')    continue;
        printchar(filename[i], 0x0a, 0);

    }
    if(ext[0] != ' ')   printchar('.',0x0a,0);
    for (int i = 0; i < 3; i++)
    {
        if(ext[i] == ' ')    continue;
        printchar(ext[i], 0x0a, 0);

    }
    printchar('\n', 0x0a, 0);
}

int handleEntry(struct BootSector *bs, struct File *fileEntry, int depth)
{
    if (fileEntry->fileName[0] == 0x00)
        return 0;
    else if(fileEntry->fileName[0] == '.')
        return 1;
    else if (fileEntry->attribute & 0x08)
        return 1;
    else if (fileEntry->attribute & 0x10)
    {
        for (int j = 0; j < depth; j++)
        {
            printchar(' ', 0x0a, 0);
            printchar(' ', 0x0a, 0);
            printchar(' ', 0x0a, 0);
        }
        printFilename(fileEntry->fileName,fileEntry->ext);
        visit(bs, fileEntry->lowCluster, depth + 1);
    }
    else
    {
        for (int j = 0; j < depth; j++)
        {
            printchar(' ', 0x0a, 0);
            printchar(' ', 0x0a, 0);
            printchar(' ', 0x0a, 0);
        }
        printFilename(fileEntry->fileName, fileEntry->ext);
    }
    return 1;
}

void lsAll(struct BootSector *bs)
{
    int rootAddr = bs->ReservedSectors + bs->SectorsPerFAT * bs->NumberOfFATs;
    int rootSize = ((bs->RootEntries * 32) + (bs->BytesPerSector - 1)) / bs->BytesPerSector;
    unsigned char buffer[rootSize * bs->BytesPerSector];
    read28pio((void*) buffer, rootAddr, rootSize, 0);

    for (int i = 0; i < bs->RootEntries; i++)
    {
        struct File *fileEntry = (struct File *)(buffer + (i * sizeof(struct File)));
        if (!handleEntry(bs, fileEntry, 0))
            break;
        // bs->SectorsPerCluster
    }
}

void visit(struct BootSector *bs, unsigned short cluster, int depth)
{
    unsigned char buffer[bs->BytesPerSector * bs->SectorsPerCluster];
    read28pio((void*) buffer, cluster2sector(bs, cluster), bs->SectorsPerCluster, 0);

    while (cluster < 0xFF8)
    {
        for (int i = 0;; i++)
        {
            struct File *fileEntry = (struct File *)(buffer + i * sizeof(struct File));
            if (!handleEntry(bs, fileEntry, depth))
                break;
        }
        cluster = readNextCluster(bs, cluster);
    }
}

unsigned sector2cluster(struct BootSector *bs, unsigned int sector_number)
{
    const unsigned int root_dir_sectors = ((bs->RootEntries * 32) + (bs->BytesPerSector - 1)) / bs->BytesPerSector;
    const unsigned int first_data_sector = bs->ReservedSectors + (bs->NumberOfFATs * bs->SectorsPerFAT) + root_dir_sectors;
    return ((sector_number - first_data_sector) / bs->SectorsPerCluster) + 2;
}
unsigned int cluster2sector(struct BootSector *bs, unsigned int cluster)
{
    unsigned int root_dir_sectors = ((bs->RootEntries * 32) + (bs->BytesPerSector - 1)) / bs->BytesPerSector;

    unsigned int first_data_sector = bs->ReservedSectors + (bs->NumberOfFATs * bs->SectorsPerFAT) + root_dir_sectors;
    return first_data_sector + (cluster - 2) * bs->SectorsPerCluster;
}
