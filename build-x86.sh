./iphone/build-qemu-ios-x86.sh ; make -j8 subdir-i386-softmmu 2>&1 | tee err
mv i386-softmmu/qemu-system-i386 aarch64-softmmu/libqemu-aarch64-softmmu.dylib
install_name_tool -id @executable_path/libqemu-aarch64-softmmu.dylib aarch64-softmmu/libqemu-aarch64-softmmu.dylib
xattr -cr aarch64-softmmu/libqemu-aarch64-softmmu.dylib
