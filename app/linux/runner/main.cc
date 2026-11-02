#include "my_application.h"

int main(int argc, char** argv) {
  // Drag and drop (desktop_drop 0.8) receives nothing under Wayland: run
  // through XWayland unless the user chose a backend.
  g_setenv("GDK_BACKEND", "x11", FALSE);
  g_autoptr(MyApplication) app = my_application_new();
  return g_application_run(G_APPLICATION(app), argc, argv);
}
