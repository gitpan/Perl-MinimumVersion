package Perl::MinimumVersion;

=pod

=head1 NAME

Perl::MinimumVersion - Find the minimum required Perl version for any code

=head1 SYNOPSIS

  # Create the checker object
  $object = Perl::MinimumVersion->new( $filename );
  $object = Perl::MinimumVersion->new( \$source );
  $object = Perl::MinimumVersion->new( $Document );
  
  # Find the minimum version
  $version = $object->minimum_version;

=head1 DESCRIPTION

C<Perl::MinimumVersion> takes Perl source code and calculates the minimum
version of perl required to be able to run it. Because it is based on
L<PPI>, it can do this without having to actually load the code.

This first release only tests based on the syntax of your code.

As this module develops, it will also be able to check explicitly
specified versions via C<require 5.005;>, and trace module dependencies
as needed.

Amoungst other things, we hope to be able to build a test that is able to
tell when the version needed based on the code syntax is higher than the
version you explicitly specified (and thus, is a package bug).

Using C<Perl::MinimumVersion> is dead simple, the synopsis pretty much
covers it.

=head1 METHODS

=cut

use strict;
use UNIVERSAL 'isa';
use version;
use List::Util ();
use PPI;
use PPI::Util '_Document';

use vars qw{$VERSION %CHECKS};
BEGIN {
	$VERSION = '0.02';

	# Create the list of version checks
	%CHECKS = (
		# Included in 5.6. Broken until 5.8
		_pragma_utf8         => qv('5.008'),

		_any_our_variables   => qv('5.006'),
		_perl_5006_pragmas   => qv('5.006'),
		_any_binary_literals => qv('5.006'),
		_magic_version       => qv('5.006'),
		_any_attributes      => qv('5.006'),
		);
}





#####################################################################
# Constructor

=pod

=head2 new $filename | \$source | $PPI_Document

The C<new> constructor creates a new version checking object for a
L<PPI::Document>. You can also provide the document to be read as a
file name, or as a C<SCALAR> reference containing the code.

Returns a new C<Perl::MinimumVersion> object, or C<undef> on error.

=cut

sub new {
	my $class    = ref $_[0] ? ref shift : shift;
	my $Document = _Document(shift) or return undef;

	# Create the object
	my $self = bless {
		Document => $Document,
		}, $class;

	$self;
}

=pod

=head2 Document

The C<Document> accessor can be used to get the L<PPI::Document> object
back out of the version checker.

=cut

sub Document { $_[0]->{Document} }





#####################################################################
# Main Methods

=pod

=head2 minimum_version

The C<minimum_version> method is the primary method for finding the
minimum perl version required based on C<all> factors in the document.

Future versions of this package are expected to also add the methods
C<minimum_syntax_version>, C<minimum_explicit_version> and
C<minimum_module_version> to handle the three ways in which the version
dependency can be added.

Returns a L<version> object, or C<undef> on error.

=cut

sub minimum_version {
	my $self = _self(@_) or return undef;

	# Always check in descending version order.
	# By doing it this way, the version of the first check that matches
	# is also the version of the document as a whole.
	my $check = List::Util::first { $self->$_() }
	            sort { $CHECKS{$b} <=> $CHECKS{$a} }
	            keys %CHECKS;

	# If nothing matches, we default to 5.004
	$check and $CHECKS{$check} or qv("5.004");
}





#####################################################################
# Version Check Methods

sub _pragma_utf8 {
	shift->Document->find_any( sub {
		$_[1]->isa('PPI::Statement::Include')
		and
		$_[1]->pragma eq 'ut8'
	} );
}

sub _any_our_variables {
	shift->Document->find_any( sub {
		$_[1]->isa('PPI::Statement::Variable')
		and
		$_[1]->type eq 'our'
	} );
}

sub _perl_5006_pragmas {
	shift->Document->find_any( sub {
		$_[1]->isa('PPI::Statement::Include')
		and
		$_[1]->pragma
		and
		$_[1]->pragma =~ /^(?:warnings|attributes|open|filetest)$/
	} );
}

sub _any_binary_literals {
	shift->Document->find_any( sub {
		$_[1]->isa('PPI::Token::Number')
		and
		$_[1]->{_subtype}
		and
		$_[1]->{_subtype} eq 'binary'
	} );	
}

sub _magic_version {
	shift->Document->find_any( sub {
		$_[1]->isa('PPI::Token::Magic')
		and
		$_[1]->content eq '$^V'
	} );
}

sub _any_attributes {
	shift->Document->find_any( sub {
		$_[1]->isa('PPI::Token::Attribute')
	} );
}






#####################################################################
# Support Functions

# Let sub be a function, object method, and static method
sub _self {
	isa(ref $_[0], __PACKAGE__) and return shift;
	isa($_[0], __PACKAGE__)     and return shift->new(@_);
	__PACKAGE__->new(@_);
}

1;

=pod

=head1 BUGS

It's very early days, so this probably doesn't catch anywhere near enough
syntax cases, and I personally don't know enough of them.

B<However> it is exceedingly easy to add a new syntax check, so if you
find something this is missing, copy and paste one of the existing
5 line checking functions, modify it to find what you want, and report it
to rt.cpan.org, along with the version needed.

I don't even need an entire diff... just the function and version.

=head1 TO DO

- Write lots more version checkers

- Write the explicit version checker

- Write the recursive module descend stuff

=head1 SUPPORT

All bugs should be filed via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Perl-MinimumVersion>

For other issues, or commercial enhancement or support, contact the author.

=head1 AUTHORS

Adam Kennedy (Maintainer), L<http://ali.as/>, cpan@ali.as

=head1 SEE ALSO

L<PPI>, L<version>

=head1 COPYRIGHT

Copyright (c) 2005 Adam Kennedy. All rights reserved.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
