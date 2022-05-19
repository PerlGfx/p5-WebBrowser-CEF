use Renard::Incunabula::Common::Setup;
package WebBrowser::CEF;
# ABSTRACT: API for Chromium Embedded Framework

use XS::Framework;
use Env qw(@PATH);
use Alien::CEF;
use XS::Loader;
use DynaLoader;
XS::Loader::load();

BEGIN {
	if( $^O eq 'MSWin32' ) {
		push @PATH, Alien::CEF->rpath;
	} else {
		push @DynaLoader::dl_library_path, Alien::CEF->rpath;
		my @files = DynaLoader::dl_findfile("-lcef");
		DynaLoader::dl_load_file($files[0]) if @files;
	}
}

use WebBrowser::CEF::Settings;

1;
=head1 SEE ALSO



=cut
