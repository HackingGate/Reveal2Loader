//
//  RHDownloadReveal.m
//  RHDownloadReveal
//
//  Created by Richard Heard on 21/03/2014.
//  Copyright (c) 2014 Richard Heard. All rights reserved.
//

#include <unistd.h>
#include <sys/stat.h>

#include "common.h"
#include <partial/partial.h>
char endianness = IS_LITTLE_ENDIAN;

#ifdef __OBJC__
#import <Foundation/Foundation.h>
#endif

//download libReveal using partialzip
NSString *appDownloadURL = @"https://dl.devmate.com/com.ittybittyapps.Reveal2/Reveal.zip";
NSString *libFolderPath = @"/Library/RHRevealLoader";
NSString *libExecutableFileName = @"RevealServer";

struct partialFile {
    unsigned char *pos;
    size_t fileSize;
    size_t downloadedBytes;
    float lastPercentageLogged;
};


size_t data_callback(ZipInfo* info, CDFile* file, unsigned char *buffer, size_t size, void *userInfo) {
    struct partialFile *pfile = (struct partialFile *)userInfo;
	memcpy(pfile->pos, buffer, size);
	pfile->pos += size;
    pfile->downloadedBytes += size;
    
    float newPercentage = (int)(((float)pfile->downloadedBytes/(float)pfile->fileSize) * 100.f);
    if (newPercentage > pfile->lastPercentageLogged){
        if ((int)newPercentage % 5 == 0 || pfile->lastPercentageLogged == 0.0f){
            printf("Downloading.. %g%%\n", newPercentage);
            pfile->lastPercentageLogged = newPercentage;
        }
    }
    
    return size;
}

int download_extract(NSString *downloadURL, NSString *zipLookupPath, NSString *folder) {
    printf("Downloading '%s /%s'\n", [downloadURL UTF8String], [zipLookupPath UTF8String]);
    
    ZipInfo* info = PartialZipInit([downloadURL UTF8String]);
    if(!info) {
        printf("Cannot find %s\n", [downloadURL UTF8String]);
        return 0;
    }
    
    CDFile *file = PartialZipFindFile(info, [zipLookupPath UTF8String]);
    if(!file) {
        printf("Cannot find %s in %s\n", [zipLookupPath UTF8String], [downloadURL UTF8String]);
        return 0;
    }
    
    int dataLen = file->size;

    unsigned char *data = malloc(dataLen+1);
    struct partialFile pfile = (struct partialFile){data, dataLen, 0};
    
    PartialZipGetFile(info, file, data_callback, &pfile);
    *(pfile.pos) = '\0';
    
    PartialZipRelease(info);
    
    NSData *zipData = [NSData dataWithBytes:data length:dataLen];
    
    if (![[NSFileManager defaultManager] createDirectoryAtPath:folder withIntermediateDirectories:YES attributes:nil error:nil]){
        printf("Failed to create folder %s\n", [folder UTF8String]);
        return 0;
    }
    
    NSString *filename = zipLookupPath.lastPathComponent;
    NSString *targetFilePath = [folder stringByAppendingPathComponent:filename];

    if (![zipData writeToFile:targetFilePath atomically:YES]) {
        printf("Failed to write file to path %s\n", [targetFilePath UTF8String]);
        return 0;
    }
    
    free(data);
    printf("Successfully downloaded %s to path %s\n", [downloadURL UTF8String], [targetFilePath UTF8String]);
    
    return 0;
}

int main(int argc, const char *argv[], const char *envp[]){
    NSString *libraryPath = [libFolderPath stringByAppendingPathComponent:libExecutableFileName];
    
    if (argc > 1 && strcmp(argv[1], "upgrade") != 0) {
        printf("CYDIA upgrade, nuking existing %s\n", [libraryPath UTF8String]);
        [[NSFileManager defaultManager] removeItemAtPath:libraryPath error:nil];
    }
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:libraryPath]) {
        
        // 1) extract zip
        if (download_extract(appDownloadURL, @"Reveal.app/Contents/SharedSupport/RevealServer.zip", libFolderPath)) {
            printf("zip downloaded");
        }
        
        // 2) extract framework
        NSString *intermediateZipFileURL = [[NSURL fileURLWithPath:[libFolderPath stringByAppendingPathComponent:@"RevealServer.zip"]] absoluteString];
        if (download_extract(intermediateZipFileURL, [@"RevealServer/iOS/RevealServer.framework" stringByAppendingPathComponent:libExecutableFileName], libFolderPath)) {
            printf("%s extracted", [libExecutableFileName UTF8String]);
        }
        
        // 3) cleanup
        [[NSFileManager defaultManager] removeItemAtPath:[libFolderPath stringByAppendingPathComponent:@"RevealServer.zip"] error:nil];
    
    } else {
        printf("RevealServer already exists at path %s\n", [libraryPath UTF8String]);
    }
    
	return 0;
}
