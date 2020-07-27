#pragma once
#include "include/cef_app.h"
#include "include/cef_print_handler.h"

#if defined(OS_MACOSX)
#include "include/wrapper/cef_library_loader.h"
#endif

class CefPerlApp :
	public CefApp,
	public CefBrowserProcessHandler,
	public CefRenderProcessHandler {

private:
  IMPLEMENT_REFCOUNTING(CefPerlApp);
};
