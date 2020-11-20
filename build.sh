./iphone/build-qemu-ios.sh ; make -j8 subdir-aarch64-softmmu 2>&1 | tee err
mv aarch64-softmmu/qemu-system-aarch64 aarch64-softmmu/libqemu-aarch64-softmmu.dylib
install_name_tool -id @executable_path/libqemu-aarch64-softmmu.dylib aarch64-softmmu/libqemu-aarch64-softmmu.dylib
xattr -cr aarch64-softmmu/libqemu-aarch64-softmmu.dylib
