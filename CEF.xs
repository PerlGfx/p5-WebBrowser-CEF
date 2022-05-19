#include <xs.h>
using namespace xs;

#undef Copy
#include "include/cef_base.h"
#include "include/cef_browser.h"
#include "include/cef_command_line.h"
#include "include/views/cef_browser_view.h"
#include "include/views/cef_window.h"
#include "include/wrapper/cef_helpers.h"

#include "CEFTypes.xsi"
#include "String.xsi"

MODULE = WebBrowser::CEF                PACKAGE = WebBrowser::CEF
PROTOTYPES: DISABLE

BOOT {
	Stash(__PACKAGE__, GV_ADD).mark_as_loaded("WebBrowser::CEF");
}

INCLUDE: Rect.xsi

INCLUDE: Browser.xsi

# App.xsi needs to be first.
INCLUDE: App.xsi

INCLUDE: Settings.xsi

INCLUDE: MainArgs.xsi

INCLUDE: _Global.xsi
