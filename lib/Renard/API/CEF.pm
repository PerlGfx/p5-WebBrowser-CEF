use Renard::Incunabula::Common::Setup;
package Renard::API::CEF;
# ABSTRACT: API for Chromium Embedded Framework

use XS::Framework;
use XS::Loader;
XS::Loader::load();

use Alien::CEF;
use Renard::API::CEF::Settings;

1;
=head1 SEE ALSO

L<Repository information|http://project-renard.github.io/doc/development/repo/p5-Renard-API-CEF/>

=cut
