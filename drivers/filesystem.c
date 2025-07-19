#include "filesystem.h"
#include "disk.h"
void readFstat(struct BootSector* bs) {
    int size = bs->SectorsPerFAT * bs->NumberOfFATs;
    unsigned char buffer[size];

    read28pio(buffer,1,size,0);

    
}

unsigned short readNextCluster(struct BootSector* bs, int active_cluster) {
    const int first_fat_sector = bs->ReservedSectors;
    const int sector_size = bs->BytesPerSector;
    unsigned char FAT_table[sector_size*2]; // needs two in case we straddle a sector
    unsigned int fat_offset = active_cluster + (active_cluster / 2);// multiply by 1.5
    unsigned int fat_sector = first_fat_sector + (fat_offset / sector_size);
    unsigned int ent_offset = fat_offset % sector_size;

    read28pio(FAT_table,fat_sector,2,0);
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

unsigned sector2cluster(struct BootSector* bs, unsigned int sector_number){
    const unsigned int root_dir_sectors = ((bs->RootEntries * 32) + (bs->BytesPerSector - 1)) / bs->BytesPerSector;
    const unsigned int first_data_sector =  bs->ReservedSectors + (bs->NumberOfFATs * bs->SectorsPerFAT) + root_dir_sectors;
    return ((sector_number - first_data_sector) / bs->SectorsPerCluster) + 2;
}
unsigned int cluster2sector(struct BootSector* bs, unsigned int cluster) {
    unsigned int root_dir_sectors = ((bs->RootEntries * 32) + (bs->BytesPerSector - 1)) / bs->BytesPerSector;
    
    unsigned int first_data_sector = bs->ReservedSectors + (bs->NumberOfFATs * bs->SectorsPerFAT) + root_dir_sectors;
    return first_data_sector + (cluster - 2) * bs->SectorsPerCluster;
}