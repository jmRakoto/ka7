# Builds Ka7's Linux packages against Ubuntu 22.04's libraries (GLib 2.72):
# what is compiled here runs on 22.04 and anything newer. Built on a newer
# system, the app asks for newer symbols (g_once_init_enter_pointer, GLib
# 2.80) and does not start on older ones.
# Flutter itself is not in the image: tool/package_linux.sh mounts the
# project's own SDK (fvm) at its usual path.
# make, gcc: media_kit builds mimalloc with CMake's default generator.
# nasm, meson ≥ 1.3, the -dev libraries: Ka7's own libmpv
# (tool/linux/build_libmpv.sh); Ubuntu's libmpv-dev is GPL, not used.
# rpm: rpmbuild, for the Fedora package.
FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
      ca-certificates curl git unzip xz-utils zip file fakeroot python3 rpm \
      binutils clang cmake ninja-build pkg-config \
      make gcc g++ nasm python3-pip patchelf \
      libgtk-3-dev liblzma-dev libstdc++-12-dev libepoxy-dev \
      libass-dev libpulse-dev libasound2-dev libgnutls28-dev zlib1g-dev \
    && rm -rf /var/lib/apt/lists/* \
    && pip3 install --no-cache-dir meson==1.6.1 \
    && git config --system --add safe.directory '*'
