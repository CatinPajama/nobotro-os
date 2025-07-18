struct __attribute__((packed)) File {
    unsigned char bytes[11];
    unsigned char attribute;
    unsigned char reserved_;
    unsigned char creation100thOfSecond;
    unsigned short creation;
    unsigned short creationDate;
    unsigned short lastAccessed;
    unsigned short lastModification;
    unsigned short lastModificationDate;
    unsigned short cluster;
    int size; 
};

struct __attribute__((packed)) BootSector{
    unsigned char  OEM[8];
    unsigned short BytesPerSector;
    unsigned char  SectorsPerCluster;
    unsigned short ReservedSectors;
    unsigned char  NumberOfFATs;
    unsigned short RootEntries;
    unsigned short TotalSectors;
    unsigned char  Media;
    unsigned short SectorsPerFAT;
    unsigned short SectorsPerTrack;
    unsigned short HeadsPerCylinder;
    unsigned int   HiddenSectors;
    unsigned int   TotalSectorsBig;
    
    unsigned char  DriveNumber;
    unsigned char  Unused;
    unsigned char  ExtBootSignature;
    unsigned int   SerialNumber;
    unsigned char  VolumeLabel[11];
    unsigned char  FileSystem[8];
} ;
