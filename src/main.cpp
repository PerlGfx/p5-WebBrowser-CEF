#include "cefperl_app.h"

int main(int argc, char **argv) {
	CefMainArgs mainArgs(argc, argv);

	CefRefPtr<CefPerlApp> app(new CefPerlApp);
	int exitCode = CefExecuteProcess(mainArgs, app.get(), NULL);
	return exitCode;
}
