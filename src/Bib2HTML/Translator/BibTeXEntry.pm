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

Bib2HTML::Translator::BibTeXEntry - An BibTeX entry manager

=head1 SYNOPSYS

use Bib2HTML::Translator::BibTeXEntry ;

my $gen = Bib2HTML::Translator::BibTeXEntry->new() ;

=head1 DESCRIPTION

Bib2HTML::Translator::BibTeXEntry is a Perl module, which parses
the names according to the BibTeX format and build a BibTeX
bibliographical reference.

=head1 GETTING STARTED

=head2 Initialization

To create a parser, say something like this:

    use Bib2HTML::Translator::BibTeXEntry;

    my $parser = Bib2HTML::Translator::BibTeXEntry->new() ;

...or something similar.

=cut

package Bib2HTML::Translator::BibTeXEntry;

@ISA = ('Exporter');
@EXPORT = qw(bibtex_ignore_field_parsing);
@EXPORT_OK = qw();

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $VERSION);
use Exporter;
use Carp ;

use Bib2HTML::General::Misc ;
use Bib2HTML::General::HTML ;
use Bib2HTML::Translator::BibTeXName ;

#------------------------------------------------------
#
# Global vars
#
#------------------------------------------------------

# Version number of the parser
my $VERSION = "3.1" ;

# List of ignore field for the parsing
my @IGNORE_PARSING_FOR_FIELDS = ( 'localfile', 'url', 'pdf',
				) ;

# List of ignore field for the parsing
my @IGNORE_ENTRY_EXPORT_FOR_FIELDS = ( 'localfile', 'url', 'pdf',
				       'domain', 'nddomain', 'rddomain',
				       'abstract', 'keywords',
				     ) ;

# Citation label database
my %CITATION_LABEL_DATABASE = () ;

#------------------------------------------------------
#
# Constructor
#
#------------------------------------------------------

sub new($) : method {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $parent = ref($proto) && $proto ;

  my $self ;
  if ( $parent ) {
    %{$self} = %{$parent} ;
  }
  else {
    $self = { } ;
  }
  bless( $self, $class );
  return $self;
}

#------------------------------------------------------
#
# Citation
#
#------------------------------------------------------

=pod

=item * citation_label()

Replies the citation label of the specified entry.
Takes 1 arg:

=over

=item * key (string)

is the key of the entry.

=item * entry (hash)

is the entry for which creates an entry.

=back

=cut
sub citation_label($$) : method {
  my $self = shift ;
  my $key = $_[0] || confess( 'you must supply the key' ) ;
  my $entry = $_[1] || confess( 'you must supply the entry data' ) ;
  if ( ( ! exists $CITATION_LABEL_DATABASE{$key} ) ||
       ( ! $CITATION_LABEL_DATABASE{$key} ) ) {
    my $bibtex = new Bib2HTML::Translator::BibTeXName() ;
    my @authors ;
    if ( $entry->{'fields'}{'author'} ) {
      @authors = $bibtex->splitnames( $entry->{'fields'}{'author'} ) ;
    }
    else {
      @authors = $bibtex->splitnames( $entry->{'fields'}{'editor'} ) ;
    }
    my $label ;
    if ( @authors ) {
      my $count = 0 ;
      foreach my $author ( @authors ) {
	if ( $author->{'last'} ) {
	  if ($count<3) {
	    $label .= html_uc( html_substr( $author->{'last'}, 0, 1 ) ) ;
	  }
	  $count ++ ;
	}
      }
      if ( $count <= 1 ) {
	$label = html_ucfirst(html_lc(html_substr($authors[0]->{'last'}, 0, 3))) ;
      }
      else {
	$label .= "+" ;
      }
      if ( $entry->{'fields'}{'year'} ) {
	$label .= substr($entry->{'fields'}{'year'},-2) ;
      }
    }
    else {
      $label = 'unk' ;
      if ( $entry->{'fields'}{'year'} ) {
	$label .= substr($entry->{'fields'}{'year'},-2) ;
      }
    }
    my $count = 0 ;
    my $lbl = $label ;
    while ( valueinhash( $lbl, \%CITATION_LABEL_DATABASE ) ) {
      $count ++ ;
      $lbl = $label . integer2alphabetic( $count ) ;
    }
    $CITATION_LABEL_DATABASE{$key} = $lbl ;
  }
  return $CITATION_LABEL_DATABASE{$key} ;
}

=pod

=item * save_citation_label()

Replies the citation label of the specified entry.
Takes 1 arg:

=over

=item * key (string)

is the key of the entry.

=item * entry (hash)

is the entry for which creates an entry.

=back

=cut
sub save_citation_label($$) : method {
  my $self = shift ;
  my $key = $_[0] || confess( 'you must supply the key' ) ;
  if ( ( $_[1] ) &&
       ( ! $CITATION_LABEL_DATABASE{$key} ) ) {
    $CITATION_LABEL_DATABASE{$key} = $_[1] ;
  }
}

=pod

=item * bibtex_ignore_field_parsing()

Replies if the specified field could be parsed
Takes 1 arg:

=over

=item * field (string)

is the name of the field.

=back

=cut
sub bibtex_ignore_field_parsing($) {
  my $field = $_[0] || confess( 'you must supply the field name' ) ;
  return ( strinarray($field,\@IGNORE_PARSING_FOR_FIELDS) ) ;
}

=pod

=item * bibtex_ignore_field_in_export()

Replies if the specified field must be ignored during export
Takes 1 arg:

=over

=item * field (string)

is the name of the field.

=back

=cut
sub bibtex_ignore_field_in_export($) {
  my $field = $_[0] || confess( 'you must supply the field name' ) ;
  return (( $field =~ /^opt/i) ||
          ( strinarray($field,\@IGNORE_ENTRY_EXPORT_FOR_FIELDS) )) ;
}

=pod

=item * bibtex_build_entry()

Replies a string which corresponds to the BibTeX source
code for the specified parameters.
Takes 4 args:

=over

=item * type (string)

is the type of the entry.

=item * key (string)

is the key of the entry.

=item * fields (hash)

is the list of fields.

=item * constants (hash)

is the list of constants.

=back

=cut
sub bibtex_build_entry($$\%\%) {
  my $self = shift ;
  return '' unless ($_[0]&&$_[1]) ;
  my $code = join('',
		  "@",
		  $_[0],
		  "{",
		  $_[1],
		  ",\n" ) ;
  while ( my ($field,$value) = each(%{$_[2]}) ) {
    if ( $field ) {
      $code .= "  $field = " ;
      if ( isarray($value) ) {
	$code .= "{".$self->expand_bibtex_vars($value,$_[3])."}" ;
      }
      else {
	$code .= "$value" ;
      }
      $code .= ",\n" ;
    }
  }
  $code .= "}" ;
  return $code ;
}

=pod

=item * bibtex_build_entry_html()

Replies an HTML string which corresponds to the BibTeX source
code for the specified parameters.
Takes 5 args:

=over

=item * type (string)

is the type of the entry.

=item * key (string)

is the key of the entry.

=item * fields (hash)

is the list of fields.

=item * constants (hash)

is the list of constants.

=item * page_width (integer)

is the size of the page. It is used to split the
lines (default value is 80).

=back

=cut
sub bibtex_build_entry_html($$\%\%$) {
  my $self = shift ;
  return '' unless ($_[0]&&$_[1]) ;
  my $page_width = ((($_[4])&&($_[4]>0))?$_[4]:80) ;
  my $code = join('',
		  "@",
		  $_[0],
		  "{",
		  $_[1],
		  ",\n" ) ;
  while ( my ($field,$value) = each(%{$_[2]}) ) {
    if (($field)&&(!bibtex_ignore_field_in_export($field))) {
      my $fldval = "  $field = " ;
      my $indent = length("$fldval") ;
      if ( isarray($value) ) {
	$fldval .= "{".$self->expand_bibtex_vars($value,$_[3])."}" ;
	$indent ++ ;
      }
      else {
	$fldval .= "$value" ;
	$indent ++ if ( $value =~ /^\{.*\}$/ ) ;
      }
      $fldval .= "," ;
      if (bibtex_ignore_field_parsing("$field")) {
	$code .= "$fldval" ;
      }
      else {
	$code .= splittocolumn("$fldval",$page_width,$indent, 2) ;
      }
      $code .= "\n" ;
    }
  }
  $code .= "}" ;
  return $code ;
}

=pod

=item * expand_bibtex_vars()

Does the TeX preprocessing which permits to
replace the constants (@STRING) by there values.
The parameter could be a sting or an array in
case the BibTeX merging operator was used to
build the value.
Takes 2 args:

=over

=item * tex (string or array)

is the tex expression to evaluate

=item * constants (hash)

is the list of constants.

=back

=cut
sub expand_bibtex_vars($\%) {
  my $self = shift ;
  if ( $_[0] ) {

    if ( isarray($_[0]) ) {

      # Treats the case of the BibTeX merging operator
      my @text = () ;
      foreach my $elt (@{$_[0]}) {
	push @text, $self->expand_bibtex_vars($elt,$_[1]) ;
      }
      return join( '', @text) ;

    }
    else {

      # Treat "standard" definition
      return $self->__expand_bibtex_vars($_[0],$_[1]) ;

    }

  }
  return '' ;
}

=pod

=item * __expand_bibtex_vars()

Does the TeX preprocessing which permits to
replace the constants (@STRING) by there values.
Takes 2 args:

=over

=item * tex (string)

is the tex expression to evaluate

=item * constants (hash)

is the list of constants.

=back

=cut
sub __expand_bibtex_vars($) : method {
  my $self = shift ;

  my $tex = $_[0] || confess( 'you must supply a TeX expression' ) ;

  return $1 if ( $tex =~ /^{(.*)}$/ ) ;

  my $lctex = lc($tex) ;
  trim $lctex ;

  return $tex
    unless ( exists $_[1]->{$lctex} ) ;

  my $lcval = lc($_[1]->{$lctex}{'text'}) ;
  trim $lcval ;

  if ( $lcval eq $lctex ) {
    return $_[1]->{$lctex}{'text'} ;
  }
  else {
    return $self->expand_bibtex_vars($_[1]->{$lctex}{'text'},$_[1]) ;
  }
}

1;
__END__

=back

=head1 COPYRIGHT

(c) Copyright 1998-09 Stéphane Galland E<lt>galland@arakhne.orgE<gt>, under GPL.

=head1 AUTHORS

=over

=item *

Conceived and initially developed by Stéphane Galland E<lt>galland@arakhne.orgE<gt>.

=back

=head1 SEE ALSO

bib2html.pl
