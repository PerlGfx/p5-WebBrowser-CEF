package inc::CEFMaker;
use Moose;

extends 'Dist::Zilla::Plugin::MakeMaker::Awesome';

override _build_MakeFile_PL_template => sub {
	my ($self) = @_;
	my $template = super();

	# Use XS::Install
	$template =~ s/\Quse ExtUtils::MakeMaker\E/use XS::Install;\n$&/sg;
	$template =~ s/\QWriteMakefile(\E/write_makefile(/sg;

	return $template;
};

override _build_WriteMakefile_args => sub { +{
		# Add LIBS => to WriteMakefile() args
		%{ super() },
		BIN_DEPS  => ['XS::Framework'],
		PARSE_XS  => 'XS::Framework::ParseXS',
		CPLUS   => 14,
		PAYLOAD => {
			'src/main$(EXT_EXT)' => '/main$(EXE_EXT)',
		},
		postamble => [
			'export LDLOADLIBS LDLIBS MYEXTLIB CCFLAGS EXE_EXT',
			'src/main$(EXT_EXT) :: src/main.cpp ; cd src && $(MAKE) all',
			'clean:: ; cd src && $(MAKE) clean',

			'Settings.xsi :: Settings.struct',
			'Settings.struct :: Settings.struct.in Settings.struct.elem ; cpp -o $@ $<; ' . $^X . ' -pi -e \'s/\\\\n/\n/g\' $@'
		],
} };

override _build_WriteMakefile_dump => sub {
	my $str = super();
	$str .= <<'END';
$WriteMakefileArgs{CONFIGURE} = sub {
	require Alien::CEF;
	require Config;
	use File::Spec;
	use File::Glob;

	require Renard::API::Gtk3;

	my $c = Alien::CEF->new;
	+{
		CCFLAGS => join(" ",
			$Config::Config{ccflags},
			qw(-I src),
			Renard::API::Gtk3->Inline('C')->{CCFLAGSEX},
			$c->cflags, '-std=c++14',
		),
		LIBS => join(" ",
			$c->libs,
			Renard::API::Gtk3->Inline('C')->{LIBS},
		),
		MYEXTLIB => File::Glob::bsd_glob(
			File::Spec->catfile( $c->dist_dir , 'Release', 'libcef_dll_wrapper.*' ) )
	};
};
END
	$str;
};

__PACKAGE__->meta->make_immutable;
