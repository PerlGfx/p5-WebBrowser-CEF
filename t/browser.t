#!/usr/bin/env perl

use Test::Most tests => 1;

use Renard::Incunabula::Common::Setup;

use Glib 'TRUE', 'FALSE';
use Renard::API::Glib;
use Renard::API::Gtk3;
use Renard::API::Gtk3::WindowID;
use Gtk3 -init;

use Imager::Screenshot;
use Renard::API::CEF;

use lib 't/lib';

BEGIN {
	if( $^O eq 'MSWin32' ) {
		# disable layered windows
		$ENV{GDK_WIN32_LAYERED} = 0;

		require Win32::API;
		Win32::API->Import("user32", "HWND SetParent( HWND hWndChild, HWND hWndNewParent )");
		Win32::API::Struct->typedef(qw(
			RECT
			LONG left;
			LONG top;
			LONG right;
			LONG bottom;
		));
		Win32::API->Import("user32", "BOOL GetClientRect( HWND   hWnd, LPRECT lpRect )");
	}
}

fun fix_default_x11_visual($widget) {
	return unless exists $ENV{DISPLAY};
	return if Gtk3::check_version(3,15,1);
	# GTK+ > 3.15.1 uses an X11 visual optimized for GTK+'s OpenGL stuff
	# since revid dae447728d: https://github.com/GNOME/gtk/commit/dae447728d
	# However, it breaks CEF: https://github.com/cztomczak/cefcapi/issues/9
	# Let's use the default X11 visual instead of the GTK's blessed one.
	#$widget->get_window =~ /X11Window/;
	require Renard::API::Gtk3::GdkX11;
	Renard::API::Gtk3::GdkX11->import;

	my $gdk_screen = $widget->get_screen;
	my $gdk_visuals = $gdk_screen->list_visuals;
	my $default_xvisual = $gdk_screen->get_xscreen->DefaultVisual;
	my ($default_gdkvisual) = grep { $_->get_xvisual->xvisualid == $default_xvisual->xvisualid } @$gdk_visuals;
	$widget->set_visual($default_gdkvisual);
}

fun get_foreign_window_constructor() {
	my $display = Gtk3::Gdk::Display::get_default();
	my $display_type = ref $display;
	my $constructor;
	if($display_type =~ /\QX11Display\E$/) {
		require Renard::API::Gtk3::GdkX11;
		Renard::API::Gtk3::GdkX11->import;
		$display = bless $display, 'Renard::API::Gtk3::GdkX11::X11Display';
		$constructor = sub {
			my ($id) = @_;
			my $window = Renard::API::Gtk3::GdkX11::X11Window->foreign_new_for_display( $display, $id );
		};
	} elsif($display_type =~ /\QWin32Display\E$/) {
		require Renard::API::Gtk3::GdkWin32;
		Renard::API::Gtk3::GdkWin32->import;
		#$display = bless $display, 'Renard::API::Gtk3::GdkWin32::Win32Display';
		$constructor = sub {
			my ($id) = @_;
			my $window = Renard::API::Gtk3::GdkWin32::Win32Window->foreign_new_for_display( $display, $id );
		};
	} elsif($display_type =~ /\QQuartzDisplay\E$/) {
		require Renard::API::Gtk3::GdkQuartz;
		Renard::API::Gtk3::GdkQuartz->import;
		$constructor = sub {
			my ($id) = @_;
			# Gtk3 on macOS does not support foreign windows. There
			# does exist a patch for GtkNSView, but this is not
			# going to be incorporated.
			#my $window = Renard::API::Gtk3::GdkQuartz::QuartzWindow->foreign_new_for_display( $display, $id );
			return undef;
		};
	} else {
		die "unimplemented foreign window constructor for diplay type $display_type";
	}
	return $constructor;
}

fun get_allocation( $widget, $allocation ) {
	if( $^O eq 'MSWin32' ) {
		my $parent_hwnd = Renard::API::Gtk3::WindowID->get_widget_id($widget);
		my $lpRect = Win32::API::Struct->new('RECT');
		GetClientRect($parent_hwnd, $lpRect);
		return +{
			x => $lpRect->{left},
			y => $lpRect->{top},
			width => $lpRect->{right} - $lpRect->{left},
			height => $lpRect->{bottom} - $lpRect->{top},
		};
	}
	return $allocation;
}

subtest "Create browser" => fun() {
	plan skip_all => "No monitor for display" unless Gtk3::Gdk::Display::get_default()->get_primary_monitor;

	if( Alien::CEF->framework_path ) {
		Renard::API::CEF::_Global::LoadLibrary(
			path(Alien::CEF->framework_path)
				->child('Chromium Embedded Framework')
				->stringify
		);
	}
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
	fix_default_x11_visual($w);
	my $widget = Gtk3::DrawingArea->new;
	$widget->set_double_buffered(FALSE);
	$w->add($widget);

	$widget->signal_connect( realize => sub {
		#my $url = "https://www.google.com/ncr";
		my $url = "https://upload.wikimedia.org/wikipedia/commons/f/ff/Solid_blue.svg";
		$browser = Renard::API::CEF::App::create_client(
			Renard::API::Gtk3::WindowID->get_widget_id($widget),
			$url,
			0, 0,
			$widget->get_allocated_width, $widget->get_allocated_height );
		$widget->queue_resize;
	});

	my $new_foreign_window = get_foreign_window_constructor();
	$widget->signal_connect( 'size-allocate' => sub {
		my ($widget, $allocation) = @_;
		return unless $browser;
		my $xid = $browser->GetWindowHandle;
		my $window = $new_foreign_window->($xid);
		$allocation = get_allocation( $widget, $allocation );
		if( $window ) {
			$window->move_resize( $allocation->{x}, $allocation->{y}, $allocation->{width}, $allocation->{height} );
		}
		$browser->NotifyMoveOrResizeStarted;
	});

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

	my $img;
	Glib::Timeout->add(5*1000, sub {
		my $handle = Renard::API::Gtk3::WindowID->get_widget_id($widget);
		if( Imager::Screenshot->have_win32 ) {
			$img = Imager::Screenshot::screenshot( hwnd => $handle );
		} elsif( Imager::Screenshot->have_x11 ) {
			$img = Imager::Screenshot::screenshot( id => $handle );
		} elsif( Imager::Screenshot->have_darwin ) {
			...
		}
		Gtk3::main_quit;
		return FALSE;
	});

	$w->show_all;
	Gtk3::main;

	my $colors = $img->getcolorusagehash;
	#$img->write( file => 'window.png' );
	my $blue_color = pack("CCC", 0x00, 0x00, 0xFF );
	ok exists $colors->{ $blue_color  } && $colors->{ $blue_color  } > 200, 'has the blue color we are looking for: #0000FF';
};

done_testing;
