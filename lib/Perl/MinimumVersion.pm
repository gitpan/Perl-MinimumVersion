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
use version;
use Carp         ();
use List::Util   ();
use PPI          ();
use Params::Util '_INSTANCE';
use PPI::Util    '_Document';

use vars qw{$VERSION %CHECKS %MATCHES};
BEGIN {
	$VERSION = '0.05';
	%MATCHES = ();

	# Create the list of version checks
	%CHECKS = (
		# Various small things
		_bugfix_magic_errno   => qv('5.008.003'),

		# Included in 5.6. Broken until 5.8
		_pragma_utf8          => qv('5.008'),

		_perl_5006_pragmas    => qv('5.006'),
		_any_our_variables    => qv('5.006'),
		_any_binary_literals  => qv('5.006'),
		_magic_version        => qv('5.006'),
		_any_attributes       => qv('5.006'),

		_perl_5005_pragmas    => qv('5.005'),
		_perl_5005_modules    => qv('5.005'),
		_any_tied_arrays      => qv('5.005'),
		_any_quotelike_regexp => qv('5.005'),
		_any_INIT_blocks      => qv('5.005'),
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

At the present time, this is just syntax and explicit version checks,
as L<Perl::Depends> is not yet completed.

Returns a L<version> object, or C<undef> on error.

=cut

sub minimum_version {
	my $self    = _self(@_) or return undef;

	# We start with a default of 5.004
	my $minimum = qv(5.004);

	# Is the explicit version greater?
	my $explicit = $self->minimum_explicit_version;
	return undef unless defined $explicit;
	if ( $explicit and $explicit > $minimum ) {
		$minimum = $explicit;
	}

	# Is the syntax version greater?
	my $syntax = $self->minimum_syntax_version;
	return undef unless defined $syntax;
	if ( $syntax and $syntax > $minimum ) {
		$minimum = $syntax;
	}

	### FIXME - Disabled until minimum_external_version completed
	# Is the external version greater?
	#my $external = $self->minimum_external_version;
	#return undef unless defined $external;
	#if ( $external and $external > $minimum ) {
	#	$minimum = $external;
	#}

	$minimum;
}

=pod

=hea2 minimum_explicit_version

The C<minimum_explicit_version> method checks through Perl code for the
use of explicit version dependencies such as.

  use 5.006;
  use 5.005_03;

Although there is almost always only one of these in a file, if more than
one are found, the highest version dependency will be returned.

Returns a L<version> object, false if no dependencies could be found,
or C<undef> on error.

=cut

sub minimum_explicit_version {
	my $self     = _self(@_) or return undef;
	my $explicit = $self->Document->find( sub {
		$_[1]->isa('PPI::Statement::Include') or return '';
		$_[1]->version                        or return '';
		1;
		} );
	return $explicit unless $explicit;

	# Convert to version objects
	List::Util::max map { version->new($_) } map { $_->version } @$explicit;
}

=pod

=head2 minimum_syntax_version $limit

The C<minimum_syntax_version> method will explicitly test only the
Document's syntax to determine it's minimum version, to the extent
that this is possible.

It takes an optional parameter of a L<version> object defining the
the lowest known current value. For example, if it is already known
that it must be 5.006 or higher, then you can provide a param of
qv(5.006) and the method will not run any of the tests below this
version. This should provide dramatic speed improvements for
large and/or complex documents.

The limitations of parsing Perl mean that this method may provide
artifically low results, but not artificially high results.

For example, if C<minimum_syntax_version> returned 5.006, you can be
confident it will not run on anything lower, although there is a chance
it during actual execution it may use some untestable  feature that creates
a dependency on a higher version.

Returns a L<version> object, false if no dependencies could be found,
or C<undef> on error.

=cut

sub minimum_syntax_version {
	my $self  = _self(@_) or return undef;
	my $limit = _INSTANCE(shift, 'version') || qv(5.004);

	# Always check in descending version order.
	# By doing it this way, the version of the first check that matches
	# is also the version of the document as a whole.
	my $check = List::Util::first { $self->$_() }
	            sort { $CHECKS{$b} <=> $CHECKS{$a} }
	            keys %CHECKS;

	# If nothing matches, we default to 5.004
	$check and $CHECKS{$check} or '';
}

=pod

=head2 minimum_external_version

B<WARNING: This method has not been implemented. Any attempted use will throw
an exception>

The C<minimum_external_version> examines code for dependencies on other
external files, and recursively traverses the dependency tree applying the
same tests to those files as it does to the original.

Returns a C<version> object, false if no dependencies could be found, or
C<undef> on error.

=cut

sub minimum_external_version {
	Carp::croak("Perl::MinimumVersion::minimum_external_version is not implemented");
}

	



#####################################################################
# Version Check Methods

sub _bugfix_magic_errno {
	my $Document = shift->Document;
	$Document->find_any( sub {
		$_[1]->isa('PPI::Token::Magic')
		and
		$_[1]->content eq '$^E'
	} )
	and
	$Document->find_any( sub {
		$_[1]->isa('PPI::Token::Magic')
		and
		$_[1]->content eq '$!'
	} );
}

sub _pragma_utf8 {
	shift->Document->find_any( sub {
		$_[1]->isa('PPI::Statement::Include')
		and
		$_[1]->pragma eq 'ut8'
	} );
}

$MATCHES{_perl_5006_pragmas} = {
	warnings   => 1,
	attributes => 1,
	open       => 1,
	filetest   => 1,
	};
sub _perl_5006_pragmas {
	shift->Document->find_any( sub {
		$_[1]->isa('PPI::Statement::Include')
		and
		$MATCHES{_perl_5006_pragmas}->{$_[1]->pragma}
	} );
}

sub _any_our_variables {
	shift->Document->find_any( sub {
		$_[1]->isa('PPI::Statement::Variable')
		and
		$_[1]->type eq 'our'
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
	shift->Document->find_any( 'Token::Attribute' );
}

$MATCHES{_perl_5005_pragmas} = {
	re     => 1,
	fields => 1,
	attr   => 1,
	};
sub _perl_5005_pragmas {
	shift->Document->find_any( sub {
		$_[1]->isa('PPI::Statement::Include')
		and
		$MATCHES{_perl_5005_pragmas}->{$_[1]->pragma}
	} );
}

# A number of modules are highly indicative of using techniques
# that are themselves version-dependant.
sub _perl_5005_modules {
	shift->Document->find_any( sub {
		$_[1]->isa('PPI::Statement::Include')
		and
		$_[1]->module
		and (
			$_[1]->module eq 'Tie::Array'
			or
			$_[1]->module =~ /\bException\b/
			or
			$_[1]->module =~ /\bThread\b/
			or
			$_[1]->module =~ /^Error\b/
			or
			$_[1]->module eq 'base'
		)
	} );
}

sub _any_tied_arrays {
	shift->Document->find_any( sub {
		$_[1]->isa('PPI::Statement::Sub')
		and
		$_[1]->name eq 'TIEARRAY'
	} )
}

sub _any_quotelike_regexp {
	shift->Document->find_any( 'Token::QuoteLike::Regexp' );
}

sub _any_INIT_blocks {
	shift->Document->find_any( sub {
		$_[1]->isa('PPI::Statement::Scheduled')
		and
		$_[1]->type eq 'INIT'
	} );
}






#####################################################################
# Support Functions

# Let sub be a function, object method, and static method
sub _self {
	if ( _INSTANCE($_[0], 'Perl::MinimumVersion') ) {
		return shift;
	}
	if ( _CLASS($_[0]) and $_[0]->isa('Perl::MinimumVersion') ) {
		return shift->new(@_);
	}
	Perl::MinimumVersion->new(@_);
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
