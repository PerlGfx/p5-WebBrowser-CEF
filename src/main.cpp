#include "cefperl_app.h"

int main(int argc, char **argv) {
	cef_main_args_t main_args;
#ifndef _WIN32 /* Microsoft Windows */
	main_args.argc = argc;
	main_args.argv = argv;
#endif
	CefMainArgs mainArgs(main_args);

	CefRefPtr<CefPerlApp> app(new CefPerlApp);
	int exitCode = CefExecuteProcess(mainArgs, app.get(), NULL);
	return exitCode;
}
