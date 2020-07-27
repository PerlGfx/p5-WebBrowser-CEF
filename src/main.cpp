#include "cefperl_app.h"

int main(int argc, char **argv) {
#if 0 /* DEBUG: output arguments for subprocess */
	for( int i = 0; i < argc; i++ ) {
		fprintf(stderr, "argv[%i]: %s\n", i, argv[i] ); // DEBUG
	}
#endif


	cef_main_args_t main_args;

#ifndef _WIN32 /* Microsoft Windows */
	main_args.argc = argc;
	main_args.argv = argv;
#endif

#if defined(OS_MACOSX)
	/* Obtain the framework-dir-path argument. */
	char* framework_dir_path_argv = NULL;
	const char framework_dir_path_arg_name[] = "--framework-dir-path=";
	for( int i = 0; i < argc; i++ ) {
		if( 0 == strncmp(argv[i], framework_dir_path_arg_name, strlen(framework_dir_path_arg_name)) ) {
			framework_dir_path_argv = argv[i];
			break;
		}
	}
	if( NULL != framework_dir_path_argv ) {
		std::string library_path( framework_dir_path_argv + strlen(framework_dir_path_arg_name) );
		library_path += "/Chromium Embedded Framework";
		cef_load_library(library_path.c_str());
	}
#endif
	CefMainArgs mainArgs(main_args);

	CefRefPtr<CefPerlApp> app(new CefPerlApp);
	int exitCode = CefExecuteProcess(mainArgs, app.get(), NULL);
	return exitCode;
}
