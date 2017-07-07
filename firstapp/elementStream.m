//
//  newstream.m
//  firstapp
//
//  Created by yanli on 2017/7/7.
//  Copyright © 2017年 YY Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "elementStream.h"

@interface ElementStream () {
    uint8_t *buffer;
    NSInteger bufferSize;
    NSInteger bufferCap;
}

@property NSString *fileName;
@property NSInputStream *streamReader;

@end


@implementation ElementStream

- (BOOL)open:(NSString *)fileName
{
    bufferSize = 0;
    bufferCap = 4*1024;
    buffer = malloc(bufferCap);
    self.fileName = fileName;
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDir = [paths objectAtIndex: 0];
    NSString *filePath = [documentsDir stringByAppendingPathComponent:fileName];
    
    self.streamReader = [NSInputStream inputStreamWithFileAtPath:filePath];
    [self.streamReader open];
    
    return YES;
}

- (packet*)nextPacket
{
    if(bufferSize < bufferCap && self.streamReader.hasBytesAvailable) {
        NSInteger readBytes = [self.streamReader read:buffer + bufferSize maxLength:bufferCap - bufferSize];
        buffer += readBytes;
    }
    
    if(memcmp(buffer, startCode, 4) != 0) {
        return nil;
    }
    
    if(bufferSize >= 5) {
        uint8_t *bufferBegin = buffer + 4;
        uint8_t *bufferEnd = buffer + bufferSize;
        while(bufferBegin != bufferEnd) {
            if(*bufferBegin == 0x01) {
                if(memcmp(bufferBegin - 3, startCode, 4) == 0) {
                    NSInteger packetSize = bufferBegin - buffer - 3;
                    packet *vp = [[packet alloc] initWithSize:packetSize];
                    memcpy(vp.data, buffer, packetSize);
                    
                    memmove(buffer, buffer + packetSize, bufferSize - packetSize);
                    bufferSize -= packetSize;
                    
                    return vp;
                }
            }
            ++bufferBegin;
        }
    }
    return nil;
}


- (void)close
{
    if (buffer) {
        free(buffer);
    }
    
    buffer = 0;
    bufferCap = 0;
    bufferSize = 0;
    
    [self.streamReader close];
}

@end

