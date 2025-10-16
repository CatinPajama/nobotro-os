struct __attribute__((packed)) File
{
    unsigned char fileName[8];
    unsigned char ext[3];
    unsigned char attribute;
    unsigned char reserved_;
    unsigned char creation100thOfSecond;
    unsigned short creation;
    unsigned short creationDate;
    unsigned short lastAccessed;
    unsigned short upperCluster;
    unsigned short lastModification;
    unsigned short lastModificationDate;
    unsigned short lowCluster;
    int size;
};

struct __attribute__((packed)) BootSector
{
    unsigned char OEM[8];
    unsigned short BytesPerSector;
    unsigned char SectorsPerCluster;
    unsigned short ReservedSectors;
    unsigned char NumberOfFATs;
    unsigned short RootEntries;
    unsigned short TotalSectors;
    unsigned char Media;
    unsigned short SectorsPerFAT;
    unsigned short SectorsPerTrack;
    unsigned short HeadsPerCylinder;
    unsigned int HiddenSectors;
    unsigned int TotalSectorsBig;

    unsigned char DriveNumber;
    unsigned char Unused;
    unsigned char ExtBootSignature;
    unsigned int SerialNumber;
    unsigned char VolumeLabel[11];
    unsigned char FileSystem[8];
};
unsigned short readNextCluster(struct BootSector *bs, int active_cluster);
unsigned sector2cluster(struct BootSector *bs, unsigned int sector_number);
unsigned int cluster2sector(struct BootSector *bs, unsigned int cluster);
void lsAll(struct BootSector *bs);
void visit(struct BootSector *bs, unsigned short cluster, int);
void readFile(struct BootSector *bs, char *path);
int findFile(struct BootSector *bs, unsigned short cluster, char *path);