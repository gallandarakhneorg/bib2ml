# Copyright (C) 1998-09  Stephane Galland <galland@arakhne.org>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; see the file COPYING.  If not, write to
# the Free Software Foundation, Inc., 59 Temple Place - Suite 330,
# Boston, MA 02111-1307, USA.

=pod

=head1 NAME

Bib2HTML::Parser::Parser - A parser for BibTeX files.

=head1 SYNOPSYS

use Bib2HTML::Parser::Parser ;

my $gen = Bib2HTML::Parser::Parser->new() ;

=head1 DESCRIPTION

Bib2HTML::Parser::Parser is a Perl module, which parses
a source file to recognize the BibTeX tokens.

=head1 GETTING STARTED

=head2 Initialization

To create a parser, say something like this:

    use Bib2HTML::Parser::Parser;

    my $parser = Bib2HTML::Parser::Parser->new() ;

...or something similar.
The constructor could take 1 arg:

=over

=item * show_bibtex (boolean)

indicates if the BibTeX code will be generated inside
a verbatim area. This flag permits to this parser
to store (or not) the initial value of each field.
Caution about the memory space.

=head1 METHOD DESCRIPTIONS

This section contains only the methods in Parser.pm itself.

=over

=cut

package Bib2HTML::Parser::Parser;

@ISA = ('Exporter');
@EXPORT = qw();
@EXPORT_OK = qw();

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $VERSION);
use Exporter;
use Carp ;
use File::Basename ;
use File::Spec ;

use Bib2HTML::General::Misc ;
use Bib2HTML::General::Error ;
use Bib2HTML::General::Verbose ;

use Bib2HTML::Parser::BibScanner ;

use Bib2HTML::Translator::TeX ;
use Bib2HTML::Translator::BibTeXEntry ;

#------------------------------------------------------
#
# Global vars
#
#------------------------------------------------------

# Version number of the parser
my $VERSION = "2.1" ;

#------------------------------------------------------
#
# Constructor
#
#------------------------------------------------------

sub new(;$) : method {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $parent = ref($proto) && $proto ;

  my $self ;
  if ( $parent ) {
    %{$self} = %{$parent} ;
    bless( $self, $class );
  }
  else {
    $self = { 'CONTENT' => {},
	      'FILE_PREAMBLES' => '',
	      'SHOW_BIBTEX' => $_[0],
	    } ;
    bless( $self, $class );
    $self->clearcontent() ;
  }
  return $self;
}

#------------------------------------------------------
#
# Getter/setter functions
#
#------------------------------------------------------

=pod

=item * content()

Replies the content of the documentation
read by the parser.

=cut
sub content() : method {
  my $self = shift ;
  return $self->{'CONTENT'} ;
}

=pod

=item * clearcontent()

Destoys the readed content and sets it
to the empty.

=cut
sub clearcontent() : method {
  my $self = shift ;
  $self->{'CONTENT'} = { } ;
}

#------------------------------------------------------
#
# Main parsing functions
#
#------------------------------------------------------

=pod

=item * parse()

Parses the files.
Takes 1 arg:

=over

=item * file_list (array ref)

is an array that contains the names of the files and the
directories from which the parser must read the bibtex entries.

=back

=cut
sub parse(\@) : method {
  my $self = shift ;
  $self->clearcontent() ;
  # Evaluate the TeX expressions
  if ( ( $self->{'FILE_PREAMBLES'} ) &&
       ( exists( $self->{'FILE_PREAMBLES'}{'tex'} ) ) &&
       ( $self->{'FILE_PREAMBLES'}{'tex'} ) ) {
    Bib2HTML::General::Verbose::two( "Evaluate the user's LaTeX definitions...\n" ) ;
    my $trans = Bib2HTML::Translator::TeX->new( $self->{'FILE_PREAMBLES'}{'filename'} ) ;
    $trans->translate( $self->{'FILE_PREAMBLES'}{'tex'},
		       $self->{'CONTENT'}{'entries'} ) ;
  }
  # Evaluate each file
  if ( isarray( $_[0] ) ) {
    foreach my $file (@{$_[0]}) {
      $self->readfile( $file ) ;
    }
  }
  else {
      die("END1");
    $self->readfile( $_[0] ) ;
  }
  # Save the TeX entries
  if ( $self->{'SHOW_BIBTEX'} ) {
    $self->save_bibtex_entries() ;
  }
  # Evalute TeX expressions
  $self->tex_translation() ;
  # Expand the crossref fields
  $self->expand_crossref() ;

  return $self->content() ;
}

=pod

=item * readfile()

Reads the content of a file.
Takes 1 arg:

=over

=item * name (string)

is the name of the file to read.

=back

=cut
sub readfile($) : method {
  my $self = shift ;
  my $filename = $_[0] || confess( 'you must supply the filename' ) ;

  # Read the file content
  Bib2HTML::General::Verbose::two( "Read $filename..." ) ;
  my $scanner = new Bib2HTML::Parser::BibScanner() ;
  if ($self->{'CONTENT'}) {
      my $content = $scanner->scanentries($filename) ;
      # Merge the constants
      if ($content->{'constants'}) {
	  foreach my $constant (keys %{$content->{'constants'}}) {
	      if (exists $self->{'CONTENT'}{'constants'}{"$constant"}) {
		  Bib2HTML::General::Error::warm( "multiple definition for the constant '".
						  $constant."'",
						  $filename,
						  extract_line_from_location($content->{'constants'}{"$constant"}{'location'})) ;
		}
	      $self->{'CONTENT'}{'constants'}{"$constant"} = $content->{'constants'}{"$constant"} ;
	  }
      }
      # Merge the preambles
      if ($content->{'preambles'}) {
	  push @{$self->{'CONTENT'}{'preambles'}}, @{$content->{'preambles'}} ;
      }
      # Merge the comments
      if ($content->{'comments'}) {
	  push @{$self->{'CONTENT'}{'comments'}}, @{$content->{'comments'}} ;
      }
      # Merge the red content to the previous content
      if ($content->{'entries'}) {
	  foreach my $entry (keys %{$content->{'entries'}}) {
	      if (exists $self->{'CONTENT'}{'entries'}{"$entry"}) {
		  Bib2HTML::General::Error::warm( "multiple definition for the entry '".
						  $entry."'",
						  $filename,
						  extract_line_from_location($content->{'entriess'}{"$entry"}{'location'})) ;
		}
	  $self->{'CONTENT'}{'entries'}{"$entry"} = $content->{'entries'}{"$entry"} ;
	  }
      }
  }
  else {
      $self->{'CONTENT'} = $scanner->scanentries($filename) ;
  }
}

=pod

=item * read_preambles()

Read some LaTeX commands from a file.
There commands are defined previously
any command from the BibTeX files.
Takes 1 arg:

=over

=item * file (string)

=back

=cut
sub read_preambles($) : method {
  my $self = shift ;
  $self->{'FILE_PREAMBLES'} = '' ;
  if ( $_[0] ) {
    Bib2HTML::General::Verbose::two( "Reading the user's LaTeX definitions...\n" ) ;
    if ( ( -f $_[0] ) &&
	 ( -r $_[0] ) ) {
      my $tex = '' ;
      local *FILE_PREAMBLE ;
      open( *FILE_PREAMBLE, "< $_[0]" )
	or Bib2HTML::General::Error::syserr( "$_[0]: $!" ) ;
      while ( my $line = <FILE_PREAMBLE> ) {
	$tex .= $line ;
      }
      close( *FILE_PREAMBLE ) ;
      $tex =~ s/^[ \t\n\r]+// ;
      $tex =~ s/[ \t\n\r]+$// ;
      if ( $tex ) {
	$self->{'FILE_PREAMBLES'} = {} ;
	$self->{'FILE_PREAMBLES'}{'tex'} = $tex ;
	$self->{'FILE_PREAMBLES'}{'filename'} = $_[0] ;
      }
    }
    else {
      Bib2HTML::General::Error::syserr( "unable to find or read the preamble file '$_[0]'" ) ;
    }
  }
}

=pod

=item * expand_crossref()

Expands crossref fields.

=cut
sub expand_crossref() : method {
  my $self = shift ;

  Bib2HTML::General::Verbose::two( "Expand crossref fields...\n" ) ;

  foreach my $entry (keys %{$self->{'CONTENT'}{'entries'}}) {

    if ( exists $self->{'CONTENT'}{'entries'}{"$entry"}{'fields'}{'crossref'} ) {

      my $parent = $self->{'CONTENT'}{'entries'}{"$entry"}{'fields'}{'crossref'} ;
      if ( exists $self->{'CONTENT'}{'entries'}{"$parent"} ) {

	foreach my $field (keys %{$self->{'CONTENT'}{'entries'}{"$parent"}{'fields'}}) {
	  if ( ! exists $self->{'CONTENT'}{'entries'}{"$entry"}{'fields'}{"$field"} ) {
	    $self->{'CONTENT'}{'entries'}{"$entry"}{'fields'}{"$field"} =
	      $self->{'CONTENT'}{'entries'}{"$parent"}{'fields'}{"$field"} ;
	  }
	}

      }
      else {
	my $filename = extract_file_from_location( $self->{'CONTENT'}{'entries'}{"$entry"}{'location'} ) ;
	my $lineno = extract_line_from_location( $self->{'CONTENT'}{'entries'}{"$entry"}{'location'} ) ;
	Bib2HTML::General::Error::warm( "unable to find the entry '$parent' required for ".
					"the crossref from '$entry'",
					$filename, $lineno ) ;
      }

    }
  }

}

=pod

=item * tex_translation()

Translates TeX expressions

=cut
sub tex_translation() : method {
  my $self = shift ;

  # Evaluate @preamble
  Bib2HTML::General::Verbose::two( "Evaluate TeX expressions for the preambles...\n" ) ;

  foreach my $preamble (@{$self->{'CONTENT'}{'preambles'}}) {
    if ( $preamble->{'tex'} ) {
      my $trans = Bib2HTML::Translator::TeX->new( extract_file_from_location( $preamble->{'location'} ) ) ;
      $trans->translate( $preamble->{'tex'},
			 $self->{'CONTENT'}{'entries'},
			 extract_line_from_location( $preamble->{'location'} ) ) ;
    }
  }

  # Evaluate @string
  Bib2HTML::General::Verbose::two( "Evaluate TeX expressions for the constants...\n" ) ;
  my $be = new Bib2HTML::Translator::BibTeXEntry() ;
  foreach my $const (keys %{$self->{'CONTENT'}{'constants'}}) {
    $self->{'CONTENT'}{'constants'}{$const}{'text'} = $be->expand_bibtex_vars($self->{'CONTENT'}{'constants'}{$const}{'text'},
									      $self->{'CONTENT'}{'constants'}) ;
  }

  # Evaluate @preamble
  Bib2HTML::General::Verbose::two( "Evaluate TeX expressions for the preambles...\n" ) ;

  # Evaluate entries' fields
  foreach my $entry (keys %{$self->{'CONTENT'}{'entries'}}) {

    Bib2HTML::General::Verbose::two( "Evaluate TeX expressions for '$entry'...\n" ) ;
    my $filename = extract_file_from_location( $self->{'CONTENT'}{'entries'}{$entry}{'location'} ) ;
    my $lineno = extract_line_from_location( $self->{'CONTENT'}{'entries'}{$entry}{'location'} ) ;
    my $trans = Bib2HTML::Translator::TeX->new( $filename ) ;

    foreach my $field (keys %{$self->{'CONTENT'}{'entries'}{$entry}{'fields'}}) {

      if ( ! bibtex_ignore_field_parsing( $field ) ) {

	# Translate the TeX code of this field into HTML source code
	Bib2HTML::General::Verbose::three( "\ttreat field '$field'" ) ;

	my $text = $be->expand_bibtex_vars($self->{'CONTENT'}{'entries'}{$entry}{'fields'}{$field},
					   $self->{'CONTENT'}{'constants'} ) ;

	$self->{'CONTENT'}{'entries'}{$entry}{'fields'}{$field} = $trans->translate( $text,
										     $self->{'CONTENT'}{'entries'},
										     $lineno ) ;

      }
      else {
	
	# Do not translate the TeX code of this field into HTML source code
	# Simply remove the
	if ( $self->{'CONTENT'}{'entries'}{$entry}{'fields'}{$field} =~ /^{(.*)}$/) {
	  $self->{'CONTENT'}{'entries'}{$entry}{'fields'}{$field} = "$1" ;
	}

      }
    }

  }

}

=pod

=item * save_bibtex_entries()

Saves the original text for the BibTeX entries

=cut
sub save_bibtex_entries() : method {
  my $self = shift ;

  Bib2HTML::General::Verbose::two( "Save the BibTeX original values for futher verbatim...\n" ) ;

  # Evaluate entries' fields
  foreach my $entry (keys %{$self->{'CONTENT'}{'entries'}}) {

    foreach my $field (keys %{$self->{'CONTENT'}{'entries'}{$entry}{'fields'}}) {

      $self->{'CONTENT'}{'entries'}{$entry}{'original-fields'}{$field} =
	$self->{'CONTENT'}{'entries'}{$entry}{'fields'}{$field} ;

    }

  }
}

1;
__END__

=back

=head1 COPYRIGHT

(c) Copyright 1998-09 Stéphane Galland <galland@arakhne.org>, under GPL.

=head1 AUTHORS

=over

=item *

Conceived and initially developed by Stéphane Galland E<lt>galland@arakhne.orgE<gt>.

=back

=head1 SEE ALSO

bib2html.pl
