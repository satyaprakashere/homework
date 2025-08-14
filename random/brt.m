@import Darwin;
@import Foundation;
@import IOKit;

// clang -fmodules -o brt brt.m && ./brt

// credit to @zhuowei for discovering the following APIs
typedef CFTypeRef IOAVServiceRef;
extern IOAVServiceRef IOAVServiceCreate(CFAllocatorRef allocator);
extern IOReturn IOAVServiceCopyEDID(IOAVServiceRef service, CFDataRef* x2);
// outputBufferSize must be less than (1 << 12) (4096 bytes)
extern IOReturn IOAVServiceReadI2C(IOAVServiceRef service, uint32_t chipAddress, uint32_t offset, void* outputBuffer,
                                   uint32_t outputBufferSize);
// This didn't work for me (returned no error, but EDID not written)
extern IOReturn IOAVServiceWriteI2C(IOAVServiceRef service, uint32_t chipAddress, uint32_t dataAddress, void* inputBuffer,
                                    uint32_t inputBufferSize);

#define BRIGHTNESS 0x10
#define CONTRAST 0x12
#define AUDIO_SPEAKER_VOLUME 0x62
#define AUDIO_MUTE 0x8D
#define DDC_WAIT 10000 // depending on display this must be set to as high as 50000

struct DDCWriteCommand
{
    UInt8 control_id;
    UInt8 new_value;
};


int main(int argc, char** argv) {
    
    IOAVServiceRef avService = IOAVServiceCreate(kCFAllocatorDefault);
    if (!avService) {
        NSLog(@"Can't open IOAVService: do you have an external monitor? Are you on M1?");
        return 1;
    }
    
    
    char i2cBytes[12];
    memset(i2cBytes, 0, sizeof(i2cBytes));
    
    usleep(DDC_WAIT);
    IOReturn error = IOAVServiceReadI2C(avService, 0x37, 0x51, i2cBytes, 12);
    NSString *returnText = @"";
    
    if (error) {
        
        returnText = [NSString stringWithFormat:@"I2C communication failure: %s\n", mach_error_string(err)];
        return error;
        
    }
    
    NSData *readData = [NSData dataWithBytes:(const void *)i2cBytes length:(NSUInteger)11];
    
    NSRange maxValueRange = {7, 1};
    NSRange currentValueRange = {10, 1};
    signed char curValue=-1;
    signed char maxValue=-1;

    [[readData subdataWithRange:maxValueRange] getBytes:&maxValue length:sizeof(1)];
    [[readData subdataWithRange:currentValueRange] getBytes:&curValue length:sizeof(1)];

    char data[16];
    struct DDCWriteCommand command;
    command.control_id = BRIGHTNESS;
    if (argc == 2) {
        NSLog(@"Current Value is %i\n", curValue);
        NSLog(@"Max Value is %i\n", maxValue);

        command.new_value = curValue + atoi(argv[1]);
        if (command.new_value < 0 ) { command.new_value=0; }
        if (command.new_value > maxValue ) { command.new_value=maxValue; }
    }
    else {
        command.new_value = 50;
    }
    

    data[0] = 0x84;
    data[1] = 0x03;
    data[2] = command.control_id;
    data[3] = (command.new_value) >> 8;
    data[4] = command.new_value & 255;
    data[5] = 0x6E ^ 0x51 ^ data[0] ^ data[1] ^ data[2] ^ data[3] ^ data[4];
    IOReturn err = IOAVServiceWriteI2C(avService, 0x37, 0x51, data, 6);
    return err;
}
