# Building dependencies
Use the `build-ios-glib.sh` script to build the following dependencies:
* libffi
* iconv
* gettext
* glib
* pixman

It is suggested that you cd to "/tmp" and make a directory there.
It seems that some packages fail to build when the path is too long.

# Building QEMU
First, export the path to the directory where you have built or extracted
GLib and dependencies. After the build is complete, you can move it to another
location with a longer path. You can also use the pre-built binaries.
```
export QEMU_IOS_ROOT=/Users/alexander/Documents/workspace/builds/apps/qemu-ios-root
```

Apply the patch for DTC to force it to cross-compile
```
cd dtc
git am ../iphone/0001-XXX-iphone-hack-CFLAGS-for-DTC.patch
```

Execute the actual build
```
./iphone/build.sh
```

There are two tricks here:
* Overriding the path to prepend the Xcode toolchain. This is to avoid conflicts
with GNU binutils in case you've installed them via Homebrew
* Using the dummy "pkg-config" script to avoid pulling host-side libraries/headers

# Running
Download the Linux kernel you want to run and place it into the corresponding
location.
```
touch iphone/test_kernel/versatile-pb.dtb
touch iphone/test_kernel/kernel-qemu
touch iphone/test_kernel/linux
touch iphone/test_kernel/vgabios-stdvga.bin
```

`vgabios-stdvga.bin` - the VGA bios. Needed for EFI platforms.
TODO: build it from QEMU tree.
```
wget https://qemu.weilnetz.de/w32/2011/2011-04-15/vgabios-stdvga.bin
```

`linux` - the image for ARM Virt platform
```
wget http://ftp.debian.org/debian/dists/Debian9.6/main/installer-arm64/current/images/netboot/debian-installer/arm64/linux
wget https://releases.linaro.org/components/kernel/uefi-linaro/latest/release/qemu64/QEMU_EFI.fd
```

`kernel-qemu` and `versatile-pb.dtb` - the image for ARM VersatilePB
```
wget https://github.com/dhruvvyas90/qemu-rpi-kernel/raw/master/kernel-qemu-4.4.34-jessie
mv kernel-qemu-4.4.34-jessie kernel-qemu
wget https://github.com/dhruvvyas90/qemu-rpi-kernel/raw/master/
```

To add a disk image or another file, copy it via iTunes file sharing.
For example, the file name for the raspberry pi disk image is `rpi_mmc.img`.

Edit the command line options in `main.m` and run via Xcode.
If you are running on a jailbroken device and your kernel is patched to allow RWX memory mapping, you can try enabling JIT (TCG) by commenting out the option `--enable-tcg-interpreter` in `iphone/build-qemu-ios.sh`

# TODO
* iOS UI backend: add keyboard and mouse input
* iOS UI backend: add menus or on-screen buttons
* add support for reading disk images from app dir to copy them via iTunes
* Clean up hacks in Makefiles/code by wrapping them in an ifdef
* Try refactoring TCG to only use RW/RX mmap flags but not RWX to allow running on non-jailbroken device at least under Xcode
