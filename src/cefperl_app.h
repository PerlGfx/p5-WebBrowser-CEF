#pragma once
#include "include/cef_app.h"
#include "include/cef_print_handler.h"

class CefPerlApp :
	public CefApp,
	public CefBrowserProcessHandler,
	public CefRenderProcessHandler {

private:
  IMPLEMENT_REFCOUNTING(CefPerlApp);
};
