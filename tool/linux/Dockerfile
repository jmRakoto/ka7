# Builds Ka7's Linux packages against Ubuntu 22.04's libraries (GLib 2.72):
# what is compiled here runs on 22.04 and anything newer. Built on a newer
# system, the app asks for newer symbols (g_once_init_enter_pointer, GLib
# 2.80) and does not start on older ones.
# Flutter itself is not in the image: tool/package_linux.sh mounts the
# project's own SDK (fvm) at its usual path.
FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
      ca-certificates curl git unzip xz-utils zip file fakeroot python3 \
      clang cmake ninja-build pkg-config \
      libgtk-3-dev liblzma-dev libstdc++-12-dev \
    && rm -rf /var/lib/apt/lists/* \
    && git config --system --add safe.directory '*'
