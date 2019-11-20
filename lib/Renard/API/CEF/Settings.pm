use Renard::Incunabula::Common::Setup;
package Renard::API::CEF::Settings;
# ABSTRACT: Settings

classmethod new_with_default_settings() {
	my $settings = $class->new;
	$settings->browser_subprocess_path(File::Spec->catfile( XS::Install::Payload::payload_dir('Renard::API::CEF'), 'main' ));
	$settings->resources_dir_path(Alien::CEF->resource_path);
	$settings->locales_dir_path(Alien::CEF->locales_path);
	$settings->framework_dir_path(Alien::CEF->framework_path);
	$settings;
}

1;
