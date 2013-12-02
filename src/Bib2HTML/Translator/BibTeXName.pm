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

Bib2HTML::Translator::BibTeXName - An parser for BibTeX names

=head1 SYNOPSYS

use Bib2HTML::Translator::BibTeXName ;

my $gen = Bib2HTML::Translator::BibTeXName->new() ;

=head1 DESCRIPTION

Bib2HTML::Translator::BibTeXName is a Perl module, which parses
the names according to the BibTeX format

=head1 GETTING STARTED

=head2 Initialization

To create a parser, say something like this:

    use Bib2HTML::Translator::BibTeXName;

    my $parser = Bib2HTML::Translator::BibTeXName->new() ;

...or something similar.

=cut

package Bib2HTML::Translator::BibTeXName;

@ISA = ('Exporter');
@EXPORT = qw();
@EXPORT_OK = qw();

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $VERSION);
use Exporter;
use Carp ;

use Bib2HTML::General::Misc ;
use Bib2HTML::General::HTML ;
use Bib2HTML::General::Error ;

#------------------------------------------------------
#
# Global vars
#
#------------------------------------------------------

# Version number of the parser
my $VERSION = "2.2" ;

# The string for the junior part of a name
my @JUNIOR_PARTS = ( 'junior', 'jr.', 'jr', 'senior', 'sen.', 'sen',
		     'esq.', 'esq', 'phd.', 'phd' ) ;

# This is the label generated for the "et al."
my $ETAL_STRING = "<i>et&nbsp;al.</i>" ;

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
# Getters
#
#------------------------------------------------------

=pod

=item * countnames()

Replies the quantity of names inside the specified string
Takes 1 arg:

=over

=item * text (string)

is the text to parse.

=back

=cut
sub countnames($) : method {
  my $self = shift ;
  my @names = $self->splitnames($_[0]||'') ;
  return int(@names) ;
}

=pod

=item * samenames()

Replies if the two names are the same.
Takes 2 args:

=over

=item * name1 (hash)

=item * name2 (hash)

=back

=cut
sub samenames($$) : method {
  my $self = shift ;
  if ( $_[0]->{'et al'} || $_[0]->{'et al'} ) {
    return 0 ;
  }
  my $n1 = $self->formatname($_[0],'l,i.') ;
  my $n2 = $self->formatname($_[1],'l,i.') ;
  $n1 =~ s/[ \t\n\r]+//g ;
  $n2 =~ s/[ \t\n\r]+//g ;
  return ( lc($n1) eq lc($n2) ) ;
}

=pod

=item * isauthorin()

Replies if the first parameter is a author which
appears inside the second parameter.

Takes 2 args:

=over

=item * author (hash)

=item * authors (string)

=back

=cut
sub isauthorin($$) : method {
  my $self = shift ;
  if ( $_[0]->{'et al'} || (!$_[1]) ) {
    return 0 ;
  }
  my @names = $self->splitnames($_[1]) ;
  foreach my $author (@names) {
    if ( $self->samenames($_[0],$author) ) {
      return 1 ;
    }
  }
  return 0 ;
}

#------------------------------------------------------
#
# Formating API
#
#------------------------------------------------------

=pod

=item * formatname()

Replies a well-formated name
Takes 2 args:

=over

=item * name (hash)

is the components of the name to format

=item * format (string)

is the format of the name (composed by v l L f f. i i. j)

=back

=cut
sub formatname($$) : method {
  my $self = shift ;
  confess( 'you must supply a name' ) unless (($_[0])&&(ishash($_[0]))) ;
  confess( 'you must supply a valid format string' ) unless $_[1] ;

  if ( $_[0]->{'et al'} ) {
    return $ETAL_STRING ;
  }
  my @blocks = $self->_extract_blocks( $_[1] ) ;

  my $name = '' ;
  foreach my $part (@blocks) {
    my $txt;    
    my $isa = isarray( $part );
    if ( $isa ) {
      $txt = join('',@{$part});
    }
    else {
      $txt = $part;
    }
    if ($txt) {
      $name .= $self->_formatname_scan_pattern($txt,$_[0],$isa) ;
    }
  }
  return $name ;
}

# $_[0]: patterns
# $_[1]: hash of the name's components
# $_[2]: 1 if all the given patterns must be found
sub _formatname_scan_pattern($$$) {
  my $self = shift ;
  confess( 'you must supply a name' ) unless (($_[1])&&(ishash($_[1]))) ;
  my $pattern = $_[0] || '' ;
  my $result = '' ;
  my $foundall = 1 ;

  while ( $pattern =~ /^([^a-zA-Z.]*)([a-zA-Z.]+)(.*)$/ ) {
    ($result, my $str, $pattern) = ($result.$1, $2, $3) ;
    if ( $str eq 'l' ) {
      $foundall = ( $foundall && $_[1]->{'last'} ) ;
      $result .= html_ucwords( $_[1]->{'last'} ) ;
    }
    elsif ( $str eq 'L' ) {
      $foundall = ( $foundall && $_[1]->{'last'} ) ;
      $result .= html_ucwords( $_[1]->{'last'} ) ;
    }
    elsif ( $str eq 'f' ) {
      $foundall = ( $foundall && $_[1]->{'first'} ) ;
      $result .= html_ucwords( $_[1]->{'first'} ) ;
    }
    elsif ( $str eq 'f.' ) {
      $foundall = ( $foundall && $_[1]->{'first'} ) ;
      $result .= html_ucwords( html_getinitiales( $_[1]->{'first'} ) ) ;
    }
    elsif ( $str eq 'i' ) {
      my $ff = html_ucwords( $_[1]->{'first'} ) ;
      if ($ff =~ /^[ \t\n\r]*([^ \t\n\r]+)/) {
	$ff = $1 ;
      }
      else {
	$ff = '' ;
      }
      $foundall = ( $foundall && $ff ) ;
      $result .= $ff ;
    }
    elsif ( $str eq 'i.' ) {
      my $ff = html_ucwords( html_getinitiales( $_[1]->{'first'} ) ) ;
      if ($ff =~ /^[ \t\n\r]*([^ \t\n\r]+)/) {
	$ff = $1 ;
      }
      else {
	$ff = '' ;
      }
      $foundall = ( $foundall && $ff ) ;
      $result .= $ff ;
    }
    elsif ( $str eq 'v' ) {
      $foundall = ( $foundall && $_[1]->{'von'} ) ;
      $result .= $_[1]->{'von'} ;
    }
    elsif ( $str eq 'j' ) {
      $foundall = ( $foundall && $_[1]->{'jr'} ) ;
      $result .= $_[1]->{'jr'} ;
    }
    else {
      $result .= $str ;
    }
  }
  if ( $pattern ) {
    $result .= $pattern ;
  }

  if ( ( ! $_[2] ) || ( $foundall ) ) {
    return $result ;
  }
  else {
    return '' ;
  }
}

=pod

=item * formatnames()

Replies well-formated names
Takes 4 args:

=over

=item * names (hash)

is the components of the name to format

=item * formatname (string)

is the format of one name (composed by the letters [vlfj.{}]+)

=item * formatnames (string)

is the format which permits to merge the names (composed by the letters [n{}]+)

=item * count (optional integer)

is the maximum number of names which must be put inside the result.

=back

=cut
sub formatnames($$$) : method {
  my $self = shift ;
  return $self->formatnames_withurl($_[0], $_[1], $_[2], undef, $_[3], $_[4]) ;
}

=pod

=item * formatnames_withurl()

Replies well-formated names
with a link to their list-of-papers page.
Takes 4 args:

=over

=item * names (hash)

is the components of the name to format

=item * formatname (string)

is the format of one name (composed by the letters [vlfj.{}]+)

=item * formatnames (string)

is the format which permits to merge the names (composed by the letters [n{}]+)

=item * backend_object (AbstractGenertor object)

is the pointer to the object to call for creating the URL.
The called methid is: formatnames_url_backend.

=item * count (optional integer)

is the maximum number of names which must be put inside the result.

=item * rootdir (optional string)

=back

=cut
sub formatnames_withurl($$$$;$$) : method {
  my $self = shift ;
  return '' unless $_[0] ;
  confess( 'you must supply a valid format string for a name' ) unless $_[1] ;
  confess( 'you must supply a valid format string for all names' ) unless $_[2] ;
  my $backend = $_[3] || undef ;
  my $max = (($_[4])&&($_[4]>=-1)) ? $_[4] : 1 ;
  my $rootdir = $_[5] || '' ;
  my @authors = $self->splitnames( $_[0] ) ;

  if ( $max <= 0 ) {
    $max = int(@authors) ;
  }

  my @blocks = $self->_extract_blocks( $_[2] ) ;
  my ($sep1,$sep2) = (join('',@{$blocks[1]}),
		      join('',@{$blocks[3]})) ;

  my ($i,$names) = (0,'') ;
  while ( ( $i <= $#authors ) && ( $i < $max ) ) {
    my $name ;
    if ( $authors[$i]{'et al'} ) {
      $name = " ".$ETAL_STRING ;
    }
    else {
      $name = $self->formatname( $authors[$i], $_[1] ) ;
      # Add the url
      if ($backend) {
	$name = $backend->formatnames_url_backend($authors[$i], $name, $rootdir) ;
      }
      if ( $names ) {
	$names .= ( $i == $#authors ) ? $sep1 : $sep2 ;
      }
    }
    $names .= $name ;
    $i ++ ;
  }
  if ( int(@authors) > $max ) {
    $names .= " ".$ETAL_STRING ;
  }
  return $names ;
}

#------------------------------------------------------
#
# Extracting API
#
#------------------------------------------------------

=pod

=item * splitnames()

Splits the specified string into names.
Takes 1 arg:

=over

=item * text (string)

is the text to split

=back

=cut
sub splitnames($) : method {
  my $self = shift ;
  my $text = $_[0] || '' ;
  my @names = () ;

  # Support no-standard notation "et al"
  if ( $text =~ /\s*et[ \t\r\n~]+al\.?\s*/g ) {
    my $original = $text ;
    $text =~ s/\s*et[ \t\r\n~]+al\.?\s*/ and others /g ;
    $text =~ s/^\s+//m ;
    $text =~ s/\s+$//m ;
    Bib2HTML::General::Error::syswarm( "the string \"".$original."\" does not respect the BibTeX standard for author's names. ".
				       "Assume \"".$text."\"." ) ;
  }

  # Scan the authors to extract the brace blocks
  my @blocks = $self->_extract_blocks($text) ;

  # Split the top level blocks
  for(my $i=0; $i<=$#blocks; $i++) {
    if ( ! isarray( $blocks[$i] ) ) {
      my @parts ;
      if ( $blocks[$i] =~ /^\s*and\s*$/i ) {
	@parts = ( '', '' ) ;
      }
      else {
	@parts = split /(?<=\s)and(?=\s)/i, " ".$blocks[$i]." " ;
      }
      if ( ! isemptyarray( \@names ) ) {
	$names[$#names] .= $parts[0] ;
        for(my $j=1; $j<=$#parts; $j++) {
	  push @names, $parts[$j] ;
	}
      }
      else {
	for(my $j=0; $j<=$#parts; $j++) {
	  my $p = $parts[$j] ;
	  $p =~ s/^\s+//gm ;
	  $p =~ s/\s+$//gm ;
	  if ( $p ) {
	    push @names, $p ;
	  }
	}
      }
    }
    else {
      if ( ! isemptyarray( \@names ) ) {
	$names[$#names] .= join( '', @{$blocks[$i]} ) ;
      }
      else {
	push @names, join( '', @{$blocks[$i]} ) ;
      }
    }
  }

  # Parse the names to extract the components
  my @newnames = () ;
  for(my $i=0; $i<=$#names; $i++) {
    my $r = $self->scan_name($names[$i]) ;

    if ( isarray( $r ) ) {
      foreach my $n (@{$r}) {
	push @newnames, $n ;
      }
    }
    else {
      push @newnames, $r ;
    }
  }

  return @newnames ;
}

=pod

=item * scan_name()

Scans a single name to extract there components.
The recognized formats are :
First [von] Last [jr]
[von] Last, First [jr]
[von] Last, jr, First

Takes 1 arg:

=over

=item * name (string)

is the name to scan

=back

=cut
sub scan_name($) : method {
  my $self = shift ;
  my $name = $_[0] || '' ;
  my ($first,$von,$last,$jr) = ('','','','') ;
  if ( $name =~ /^\s*others?\s*$/i ) {
    #
    # et al.
    #
    return { 'first' => $first,
	     'von' => $von,
	     'last' => $last,
	     'jr' => $jr,
	     'et al' => 1,
	   } ;
  }
  elsif ( $name =~ /^([^,]*),([^,]*),(.*)$/ ) {
    my ($p1,$p2,$p3) = ($1,$2,$3) ;
    if ( $self->_is_junior( $p2 ) ) {
      #
      # [von] Last, jr, First
      #
      ($von,$last,$jr,$first) = $self->_scanname_vl_j_f( $p1,$p2,$p3 ) ;
    }
    else {
      #
      # name, name, ...
      #
      Bib2HTML::General::Error::syswarm( "BibTeX author's names are expressed with a quiet ambigous syntax: ".$name.". Assume ',' as names' separator." ) ;
      my $subnames = [] ;
      foreach my $subname ( split(/\s*,\s*/, $name ) ) {
	($von,$last,$jr,$first) = $self->_scanname_fvlj( $subname ) ;
	$first =~ s/^\s+// ;
	$first =~ s/\s+$// ;
	$last =~ s/^\s+// ;
	$last =~ s/\s+$// ;
	$von =~ s/^\s+// ;
	$von =~ s/\s+$// ;
	$jr =~ s/^\s+// ;
	$jr =~ s/\s+$// ;
	push @{$subnames}, { 'first' => html_ucfirst($first),
			     'von' => lc($von),
			     'last' => html_ucfirst($last),
			     'jr' => $jr,
			     'et al' => 0,
			   } ;
      }
      return $subnames ;
    }
  }
  elsif ( $name =~ /^([^,]*),(.*)$/ ) {
    my ($p1,$p2) = ($1,$2) ;
    if ( $self->_is_junior( $p2 ) ) {
      #
      # First [von] Last, jr
      #
      ($von,$last,$jr,$first) = $self->_scanname_fvl_j( $p1,$p2 );
    }
    else {
      #
      # [von] Last, First [jr]
      #
      ($von,$last,$jr,$first) = $self->_scanname_vl_fj( $p1,$p2 ) ;
    }

  }
  elsif ( $name !~ /,/ ) {
    #
    # First [von] Last [jr]
    #
    ($von,$last,$jr,$first) = $self->_scanname_fvlj( $name ) ;
  }
  else {
    Bib2HTML::General::syserr( "unable to recognize a pattern for the bibTeX name: $name" ) ;
  }
  $first =~ s/^\s+// ;
  $first =~ s/\s+$// ;
  $last =~ s/^\s+// ;
  $last =~ s/\s+$// ;
  $von =~ s/^\s+// ;
  $von =~ s/\s+$// ;
  $jr =~ s/^\s+// ;
  $jr =~ s/\s+$// ;
  return { 'first' => html_ucfirst($first),
           'von' => lc($von),
           'last' => html_ucfirst($last),
           'jr' => $jr,
	   'et al' => 0,
         } ;
}

=pod

=item * _scanname_fvlj()

Name pattern: [von] Last, First [jr]

=cut
sub _scanname_vl_fj($$) {
  my $self = shift ;
  my ($p1,$p2)=($_[0],$_[1]) ;
  $p1 =~ s/^\s+//mg ;
  $p1 =~ s/\s+$//mg ;
  $p2 =~ s/^\s+//mg ;
  $p2 =~ s/\s+$//mg ;
  my ($von,$last,$jr,$first)=('','','','') ;
  $first = $p2 ;
  if ( $p2 =~ /^(.*)\s+([a-zA-Z.]+)$/ ) {
    my ($p3,$p4)=($1,$2) ; 
    $p3 =~ s/^\s+//mg ;
    $p3 =~ s/\s+$//mg ;
    $p4 =~ s/^\s+//mg ;
    $p4 =~ s/\s+$//mg ;
    if ( $self->_is_junior($p4) ) {
      $first = $p3 ;
      $jr = $p4 ;
    }
  }
  ($von,$last) = $self->_get_first_majword( $p1 ) ;
  return ($von,$last,$jr,$first) ;
}

=pod

=item * _scanname_fvl_j()

Name pattern: First [von] Last, jr

=cut
sub _scanname_fvl_j($$) {
  my $self = shift ;
  my ($name,$jr) = ($_[0],$_[1]) ;
  $name =~ s/^\s+//mg ;
  $name =~ s/\s+$//mg ;
  $jr =~ s/^\s+//mg ;
  $jr =~ s/\s+$//mg ;
  my ($von,$last,undef,$first)=$self->_scanname_fvlj($name) ;
  return ($von,$last,$jr,$first) ;
}

=pod

=item * _scanname_fvlj()

Name pattern: First [von] Last [jr]

=cut
sub _scanname_fvlj($) {
  my $self = shift ;
  my $name = $_[0] ;
  $name =~ s/^\s+//mg ;
  $name =~ s/\s+$//mg ;
  my ($von,$last,$jr,$first)=('','','','') ;
  ($first,my $reste) = $self->_get_majwords($name) ;
  # If the reste variable is empty (ie no von found)
  # It means that the last upercase word must
  # be the lastname
  if ( ! $reste ) {
    if ( $name =~ /^(.*?)\s+([^\s]+)\s*$/ ) {
      ($first,$reste) = ($1,$2) ;
    }
    else {
      ($first,$reste) = ('',$name) ;
    }
  }
  $first =~ s/^\s+//mg ;
  $first =~ s/\s+$//mg ;
  $reste =~ s/^\s+//mg ;
  $reste =~ s/\s+$//mg ;
  ($von,$reste) = $self->_get_first_majword($reste) ;
  $von =~ s/^\s+//mg ;
  $von =~ s/\s+$//mg ;
  $reste =~ s/^\s+//mg ;
  $reste =~ s/\s+$//mg ;
  if ( ( $reste =~ /^(.*)\s+([a-zA-Z.]+)$/ ) &&
       ( $self->_is_junior($2) ) ) {
    ($last,$jr) = ($1,$2) ;
  }
  else {
    $last = $reste ;
  }
  return ($von,$last,$jr,$first) ;
}

=pod

=item * _scanname_vl_j_f()

Name pattern: [von] Last, jr, First

=cut
sub _scanname_vl_j_f($$$) {
  my $self = shift ;
  my ($p1,$p2,$p3) = ($_[0],$_[1],$_[2]) ;
  $p1 =~ s/^\s+//mg ;
  $p1 =~ s/\s+$//mg ;
  $p2 =~ s/^\s+//mg ;
  $p2 =~ s/\s+$//mg ;
  $p3 =~ s/^\s+//mg ;
  $p3 =~ s/\s+$//mg ;
  my ($von,$last,$jr,$first)=('','',$p2,$p3) ;
  ($von,$last) = $self->_get_first_majword( $p1 ) ;
  return ($von,$last,$jr,$first) ;
}

=pod

=item * _get_majwords()

Replies all the maj words from the begining.

=over

=item * text (string)

=back

=cut
sub _get_majwords($) {
  my $self = shift ;
  return ('','') unless $_[0] ;
  my @words = split(/\s+/, $_[0]) ;
  my ($maj,$after) = ('','') ;
  my $inmaj = 1 ;
  foreach my $word (@words) {
    if ( $word !~ /^&?[A-Z].*$/ ) {
      $inmaj = 0 ;
    }
    if ( $inmaj ) {
      $maj .= ($maj?' ':'').$word ;
    }
    else {
      $after .= ($after?' ':'').$word ;
    }
  }
  return ($maj,$after) ;
}

=pod

=item * _get_first_majword()

Replies the string that begins from the first word
with first majuscule letter.

=over

=item * text (string)

=back

=cut
sub _get_first_majword($) {
  my $self = shift ;
  return ('','') unless $_[0] ;
  my @words = split(/\s+/, $_[0] ) ;
  my ($before,$after) = ('','') ;
  my $found = 0 ;
  foreach my $word (@words) {
    if ( $word =~ /^&?[A-Z].*$/ ) {
      $found = 1 ;
    }
    if ( $found ) {
      $after .= ($after?' ':'').$word ;
    }
    else {
      $before .= ($before?' ':'').$word ;
    }
  }
  if ( ! $after ) {
    return ('',$before) ;
  }
  else {
    return ($before,$after) ;
  }
}

=pod

=item * _is_junior()

Replies if the parameter is a string that corresponds
to the junior part of a BibTeX name.

=over

=item * text (string)

=back

=cut
sub _is_junior($) {
  my $self = shift ;
  my $jr = $_[0] ;
  if ( $jr ) {
    $jr =~ s/^\s+//mg ;
    $jr =~ s/\s+$//mg ;
    return ( ( strinarray( lc($jr), \@JUNIOR_PARTS ) ) ||
	     ( isnumber($jr) ) ) ;
  }
  else {
    return $jr ;
  }
}

=pod

=item * _extract_blocks()

Extracts the blocks from the specified string
Takes 1 arg:

=over

=item * text (string)

is the text to parse.

=back

=cut
sub _extract_blocks($) : method {
  my $self = shift ;
  my $text = $_[0] || '' ;
  my @blocks = () ;
  my $currentblock = "" ;
  my $count = 0 ;
  while ( $text =~ /^(.*?)((?:\\\{)|(?:\\\})|\{|\})(.*)$/ ) {
    (my $before, my $sep, $text) = ($1,$2,$3) ;
    $currentblock .= $before ;
    if ( ( $sep eq '\\{' ) || ( $sep eq '\\}' ) ) {
      $currentblock .= $sep ;
    }
    elsif ( $sep eq '{' ) {
      if ( $count > 0 ) {
        $currentblock .= $sep ;
      }
      else {
        push @blocks, $currentblock ;
        $currentblock = '' ;
      }
      $count ++ ;
    }
    elsif ( $sep eq '}' ) {
      $count -- unless ($count <= 0) ;
      if ( $count > 0 ) {
        $currentblock .= $sep ;
      }
      else {
        push @blocks, [ $currentblock ] ;
        $currentblock = '' ;
      }
    }
    else {
      confess( "Invalid block: $sep\n" ) ;
    }
  }
  if ( $text ) {
    $currentblock .= $text ;
  }
  if ( $currentblock ) {
    push @blocks, $currentblock ;
  }
  return @blocks ;
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
