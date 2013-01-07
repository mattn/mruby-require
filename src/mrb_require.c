#include <mruby.h>
#include <mruby/string.h>
#include <stdio.h>
#include <limits.h>
#include <unistd.h>

#ifdef _WIN32
#include <windows.h>
#define dlopen(x,y) (void*)LoadLibrary(x)
#define dlsym(x,y) (void*)GetProcAddress((HMODULE)x,y)
#define dlclose(x) FreeLibrary((HMODULE)x)
const char* dlerror() {
    DWORD err = (int) GetLastError();
    if (err == 0) return NULL;
    static char buf[256];
    FormatMessage(
            FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_IGNORE_INSERTS,
            NULL,
            err,
            MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT),
            buf,
            sizeof buf,
            NULL);
    return buf;
}
#else
#include <dlfcn.h>
#endif

typedef void (*fn_mrb_gem_init)(mrb_state *mrb);

static mrb_value
mrb_require(mrb_state *mrb, mrb_value self) {
  mrb_value arg = mrb_nil_value();
  mrb_get_args(mrb, "S", &arg);

  char* mruby_root = getenv("MRUBY_ROOT");
  if (!mruby_root) {
    mrb_raise(mrb, E_RUNTIME_ERROR, "$MRUBY_ROOT is not defined");
  }

  char* ptr = RSTRING_PTR(arg);
  while (*ptr) {
    if (*ptr == '-') *ptr = '_';
    ptr++;
  }
  char lib[PATH_MAX] = {0};
  char entry[PATH_MAX] = {0};
  snprintf(lib, sizeof(lib)-1, "%s/mrbgems/g/%s/mrb_%s.dll", mruby_root,
    RSTRING_PTR(arg), RSTRING_PTR(arg));
  snprintf(entry, sizeof(entry)-1, "mrb_%s_gem_init", mruby_root,
    RSTRING_PTR(arg), RSTRING_PTR(arg));

  void * handle = dlopen(lib, RTLD_LAZY|RTLD_GLOBAL);
  if (!handle) {
    mrb_raise(mrb, E_RUNTIME_ERROR, dlerror());
  }
  dlerror(); // clear last error

  fn_mrb_gem_init fn = (fn_mrb_gem_init) dlsym(handle, entry);
  if (fn == NULL) {
    mrb_raise(mrb, E_RUNTIME_ERROR, dlerror());
  }
  dlerror(); // clear last error

  fn(mrb);

  dlclose(handle);

  return mrb_nil_value();
}

void
mrb_mruby_require_gem_init(mrb_state* mrb) {
  struct RClass* clazz = mrb_class_get(mrb, "Kernel");
  mrb_define_method(mrb, clazz, "require", mrb_require, ARGS_REQ(1));
}

/* vim:set et ts=2 sts=2 sw=2 tw=0: */
