#!/usr/bin/perl -w

# Main testing for Perl::MinimumVersion

use strict;
use lib ();
use UNIVERSAL 'isa';
use File::Spec::Functions ':ALL';
BEGIN {
	$| = 1;
	unless ( $ENV{HARNESS_ACTIVE} ) {
		require FindBin;
		$FindBin::Bin = $FindBin::Bin; # Avoid a warning
		chdir catdir( $FindBin::Bin, updir() );
		lib->import('blib', 'lib');
	}
}

use Test::More tests => 18;
use PPI;
use Perl::MinimumVersion;

sub version_is {
	my $Document = PPI::Document->new( shift );
	isa_ok( $Document, 'PPI::Document' );
	my $Version = Perl::MinimumVersion->new( $Document );
	isa_ok( $Version, 'Perl::MinimumVersion' );
	is( $Version->minimum_version, shift, $_[0] || 'Version matches expected' );
	$Version;
}





#####################################################################
# Basic Testing

# Constructor testing
{
	my $Version = Perl::MinimumVersion->new( \'print "Hello World!\n";' );
	isa_ok( $Version, 'Perl::MinimumVersion' );
	$Version = Perl::MinimumVersion->new( catfile( 't', '02_main.t' ) );
	# version_is tests the final method

	# Bad things
	foreach ( [], {}, sub { 1 } ) { # Add undef as well after PPI 0.906
		is( Perl::MinimumVersion->new( $_ ), undef, '->new(evil) returns undef' );
	}
}


{
my $Version = version_is( <<'END_PERL', '5.004', 'Hello World matches expected version' );
print "Hello World!\n";
END_PERL
is( $Version->_any_our_variables, '', '->_any_our_variables returns false' );

# This first time, lets double check some assumptions
isa_ok( $Version->Document, 'PPI::Document' );
isa_ok( $Version->minimum_version, 'version' );
}

# Try one with an 'our' in it
{
my $Version = version_is( <<'END_PERL', '5.006', '"our" matches expected version' );
our $foo = 'bar';
END_PERL
is( $Version->_any_our_variables, 1, '->_any_our_variables returns true' );
}

# Try with attributes
{
my $Version = version_is( <<'END_PERL', '5.006', '"attributes" matches expected version' );
sub foo : attribute { 1 };
END_PERL
is( $Version->_any_attributes, 1, '->_any_attributes returns true' );
}

1;
