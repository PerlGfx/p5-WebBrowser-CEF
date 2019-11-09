#!/usr/bin/env perl

use Test::Most tests => 1;

use Renard::Incunabula::Common::Setup;

use Renard::API::CEF;

use Renard::API::Glib;
use Renard::API::Gtk3;
use Renard::API::Gtk3::WindowID;
use Glib 'TRUE', 'FALSE';
use Gtk3 -init;

use lib 't/lib';

subtest "Create browser" => fun() {
	## Provide CEF with command-line arguments.
	#my $main_args = Renard::API::CEF::MainArgs->new(\@ARGV);
	#my $main_args = Renard::API::CEF::MainArgs->new([ $^X, $0, "--no-sandbox", "--disable-gpu" ]);
	my $main_args = Renard::API::CEF::MainArgs->new([]);

	#// CEF applications have multiple sub-processes (render, plugin, GPU, etc)
	#// that share the same executable. This function checks the command-line and,
	#// if this is a sub-process, executes the appropriate logic.
	#int exit_code = CefExecuteProcess(main_args, NULL, NULL);
	#if (exit_code >= 0) {
		#// The sub-process has completed so return here.
		#return exit_code;
	#}

	##if defined(CEF_X11)
		#// Install xlib error handlers so that the application won't be terminated
		#// on non-fatal errors.
		#XSetErrorHandler(XErrorHandlerImpl);
		#XSetIOErrorHandler(XIOErrorHandlerImpl);
	##endif

	#// Specify CEF global settings here.
	my $settings = Renard::API::CEF::Settings->new_with_default_settings;

	#// When generating projects with CMake the CEF_USE_SANDBOX value will be defined
	#// automatically. Pass -DUSE_SANDBOX=OFF to the CMake command-line to disable
	#// use of the sandbox.
	##if !defined(CEF_USE_SANDBOX)
		#settings.no_sandbox = true;
	##endif
	$settings->no_sandbox(1);

	#// SimpleApp implements application-level callbacks for the browser process.
	#// It will create the first browser instance in OnContextInitialized() after
	#// CEF has initialized.
	my $app = Renard::API::CEF::App->new;

	my $exit_code = Renard::API::CEF::_Global::CefExecuteProcess($main_args, $app);
	return $exit_code if $exit_code >= 0;

	#// Initialize CEF for the browser process.
	#CefInitialize(main_args, settings, app.get(), NULL);
	Renard::API::CEF::_Global::CefInitialize($main_args, $settings, $app);


	my $browser;

	my $w = Gtk3::Window->new;
	$w->set_default_size(600,800);
	Renard::API::CEF::App::fix_default_x11_visual($w);
	$w->show_all;
	$browser = Renard::API::CEF::App::create_client(Renard::API::Gtk3::WindowID->get_widget_id($w));
	use Renard::API::Gtk3::GdkX11;
	$w->signal_connect( 'size-allocate' => sub {
		my ($widget, $allocation) = @_;
		my $display = Gtk3::Gdk::Display::get_default();
		my $xid = $browser->GetWindowHandle;
		my $window = Renard::API::Gtk3::GdkX11::X11Window->foreign_new_for_display( $display, $xid );
		$window->move_resize( $allocation->{x}, $allocation->{y}, $allocation->{width}, $allocation->{height} );
	});

	$w->queue_resize;

	#// Run the CEF message loop. This will block until CefQuitMessageLoop() is
	#// called.
	#Renard::API::CEF::_Global::CefRunMessageLoop();
	Glib::Timeout->add(10, sub {
		return unless $browser;
		Renard::API::CEF::_Global::CefDoMessageLoopWork();
		return TRUE;
	});

	$w->signal_connect( 'delete-event' => sub {
		#// Shut down CEF.
		Renard::API::CEF::_Global::CefShutdown();
	});

	Gtk3::main;

	pass;
};

done_testing;
