package inc::CEFMaker;
use Moose;

use Config;
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
			map { my $r = $_; $r =~ s,/,\\,g if $^O eq 'MSWin32'; $r }
				( "src/main@{[ $Config{exe_ext} ]}" => "/main@{[ $Config{exe_ext} ]}" ),
		},
		postamble => [
			'export LDLOADLIBS LDLIBS MYEXTLIB CCFLAGS EXE_EXT',
			(map { my $r = $_; $r =~ s,/,\\,g if $^O eq 'MSWin32'; $r }
			'src/main$(EXE_EXT) :: src/main.cpp ; cd src && $(MAKE) all'),
			'clean:: ; cd src && $(MAKE) clean',

			'Settings.xsi :: Settings.struct',
			'Settings.struct :: Settings.struct.in Settings.struct.elem ; $(PERL) inc/process-cpp.pl $< $@',
		],
} };

override _build_WriteMakefile_dump => sub {
	my $str = super();
	$str .= <<'END';
$WriteMakefileArgs{CONFIGURE} = sub {
	require Alien::CEF;
	require Config;
	require File::Spec;
	require File::Glob;

	my $c = Alien::CEF->new;

	my $wrapper = File::Glob::bsd_glob(
			File::Spec->catfile( $c->dist_dir , 'Release', 'libcef_dll_wrapper.*' ) );
	my $cef_libs;
	if( $^O eq 'MSWin32' ) {
		$wrapper =~ s,\\,/,g;
		$cef_libs = join " ", ":nosearch", $c->libs, ":search";
		$cef_libs =~ s/-lcef/$wrapper $&/g;
	} else {
		$cef_libs = $c->libs;
	}

	+{
		CCFLAGS => join(" ",
			$Config::Config{ccflags},
			qw(-I src),
			$c->cflags, '-std=c++14',
		),
		LIBS => join(" ",
			$cef_libs,
		),
		MYEXTLIB => $wrapper,
	};
};
END
	$str;
};

__PACKAGE__->meta->make_immutable;
