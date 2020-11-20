//
//  main.m
//  QemuLauncher
//
//  Created by Alexander Tarasikov on 06/01/2019.
//  Copyright © 2019 test. All rights reserved.
//

#import <UIKit/UIKit.h>
#include <unistd.h>

#define DOCS_FILE_PREFIX "$DOCS"

void runQemu(void)
{
    NSString * path = [[[NSBundle mainBundle] pathForResource:  @"efi-virtio" ofType: @"rom"] stringByDeletingLastPathComponent];
    NSLog(@"path to rsrc: %@\n", path);
    chdir([path UTF8String]);
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docDirBasePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    NSLog(@"Path to document dir: %@\n", docDirBasePath);
    NSArray *directoryContent = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:docDirBasePath error:NULL];
    for (int Count = 0; Count < (int)[directoryContent count]; Count++)
    {
        NSLog(@"iTunes shared file %d: %@", (Count + 1), [directoryContent objectAtIndex:Count]);
    }
    
    char *qargs1[] = {
        "yolo",
        "-M", "virt,kernel_irqchip=on,gic-version=2",
        "-cpu", "cortex-a57",
        "-bios", "QEMU_EFI.fd",
        "-m", "512M",
        "-kernel", "linux",
        "-append", "earlycon=pl011,0x9000000 console=ttyAMA0 console=fb0 acpi=off lpj=200000 rootwait root=/dev/sda2",
        "-serial", "mon:stdio",
        "-display", "iphone",
        "-device", "VGA",
        "-smp", "1",
    };
    
    char *qargs[] = {
        "yolo",
        "-M", "versatilepb",
        "-cpu", "arm1176",
        "-m", "256M",
        "-append", "console=ttyAMA0 console=fb0 root=/dev/sda2 rootwait",
        "-kernel", "kernel-qemu",
        "-dtb", "versatile-pb.dtb",
        "-serial", "mon:stdio",
        "-display", "iphone",
        //"-drive", "file=" DOCS_FILE_PREFIX "/rpi_mmc.img,format=raw",
    };
    
    char *qargs_x86[] = {
        "yolo",
        "-m", "256M",
        "-drive", "file=" DOCS_FILE_PREFIX "/kolibri.iso,media=cdrom",
        "-serial", "mon:stdio",
        "-display", "iphone",
        "-vga", "std",
    };
    
    int qargc = sizeof(qargs) / sizeof(qargs[0]);
    for (int arg = 0; arg < qargc; arg++) {
        char *fname = qargs[arg];
        if (strstr(fname, DOCS_FILE_PREFIX)) {
            NSString *fname_suffix_ns = [NSString stringWithUTF8String:fname];
            NSString *patched_path = [fname_suffix_ns stringByReplacingOccurrencesOfString:@DOCS_FILE_PREFIX withString:docDirBasePath];
            qargs[arg] = [patched_path cStringUsingEncoding:NSUTF8StringEncoding];
            printf("patched path: %s\n", qargs[arg]);
        }
    }
    
    extern int xmain(int argc, char ** argv, char **envp);
    int qemu_retval = xmain(qargc, qargs, 0);
    printf("%s: xmain returns %d\n", __func__, qemu_retval);
}

int main(int argc, char * argv[]) {
    runQemu();
}
