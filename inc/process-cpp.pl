#!/usr/bin/env perl
use FindBin;
use lib "$FindBin::Bin/../lib";

use strict;
use warnings;

sub _clang_cpp {
	my ($input, $output) = @ARGV;
	my $exit = system(qw(clang -E -P -x c -o), $output, $input);
}

sub _general_cpp {
	my ($input, $output) = @ARGV;
	my $exit = system(qw(cpp -o), $output, $input);
}

sub _cpp {
	my ($input, $output) = @ARGV;
	if( $^O eq 'darwin' ) {
		return _clang_cpp($input, $output);
	} else {
		return _general_cpp($input, $output);
	}
}

sub main {
	my ($input, $output) = @ARGV;
	my $exit = _cpp($input, $output);
	die "Failed to run cpp" if $exit;
	$exit = system($^X, qw(-pi -e), 's/\\\\n/\n/g', $output);
	$exit;
}

main;
