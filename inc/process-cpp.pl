#!/usr/bin/env perl
use FindBin;
use lib "$FindBin::Bin/../lib";

use strict;
use warnings;

sub main {
	my ($input, $output) = @ARGV;
	my $exit = system(qw(cpp -o), $output, $input);
	die "Failed to run cpp" if $exit;
	$exit = system($^X, qw(-pi -e), 's/\\\\n/\n/g', $output);
	$exit;
}

main;
