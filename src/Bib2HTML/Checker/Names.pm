# Copyright (C) 2004-07  Stephane Galland <galland@arakhne.org>
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

Bib2HTML::Checker::Names - A checker for BibTeX names.

=head1 SYNOPSYS

use Bib2HTML::Checker::Names ;

my $gen = Bib2HTML::Checker::Names->new() ;

=head1 DESCRIPTION

Bib2HTML::Checker::Names is a Perl module, which checks
if author's names are similar or not.

=head1 GETTING STARTED

=head2 Initialization

To create a parser, say something like this:

    use Bib2HTML::Checker::Names;

    my $parser = Bib2HTML::Checker::Names->new() ;

...or something similar.

=head1 METHOD DESCRIPTIONS

This section contains only the methods in Names.pm itself.

=over

=cut

package Bib2HTML::Checker::Names;

@ISA = ('Exporter');
@EXPORT = qw();
@EXPORT_OK = qw();

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $VERSION);
use Exporter;
use Carp ;

use Bib2HTML::Translator::BibTeXName ;
use Bib2HTML::General::Error ;
use Bib2HTML::General::Misc ;

#------------------------------------------------------
#
# Global vars
#
#------------------------------------------------------

# Version number of the checker
my $VERSION = "0.1" ;

#------------------------------------------------------
#
# Constructor
#
#------------------------------------------------------

sub new() : method {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $parent = ref($proto) && $proto ;

  my $self ;
  if ( $parent ) {
    %{$self} = %{$parent} ;
  }
  else {
    $self = {} ;
  }
  bless( $self, $class );
  return $self;
}

#------------------------------------------------------
#
# Checking
#
#------------------------------------------------------

=pod

=item * check()

Check the names.
Takes 1 arg:

=over

=item * database (hash ref)

is the entire data structure toi check.

=back

=cut
sub check(\%) : method {
  my $self = shift ;
  if ($_[0]) {
    my %authors = $self->get_all_authors($_[0]->{'entries'}) ;
    my @ids = sortbyletters(keys %authors) ;

    for(my $i=0; $i<$#ids; $i++) {
      my $name1 = lc($authors{$ids[$i]}{'last'}) ;
      for(my $j=$i+1; $j<=$#ids; $j++) {
	my $name2 = lc($authors{$ids[$j]}{'last'}) ;

	my $error_msg = join('',
			     "  name1=".$authors{$ids[$i]}{'last'},
			     ",",
			     $authors{$ids[$i]}{'first'},
			     " (",
			     $authors{$ids[$i]}{'location'},
			     ")\n  name2=",
			     $authors{$ids[$j]}{'last'},
			     ",",
			     $authors{$ids[$j]}{'first'},
			     " (",
			     $authors{$ids[$j]}{'location'},
			     ")") ;

	# Check for the same name defined many times
	if ($name1 eq $name2) {
	  Bib2HTML::General::Error::syswarm("multiple author's name syntax for '$name1':\n".
					    $error_msg) ;
 	}

	# Check for the same name defined many times but with keyboard's mistaskes
	elsif ($self->is_similar($name1, $name2)) {
	  Bib2HTML::General::Error::syswarm("possible author's name mistake?\n".
					    $error_msg) ;
 	}

      }
    }
  }
}

=item * is_similar()

Replies if the 2 names have similar syntax
Takes 2 args:

=over

=item * name1 (string)

=item * name2 (string)

=back

=cut
sub is_similar($$) : method {
  my $self = shift ;
  my $percent = levenshtein($_[0],$_[1]) ;
  return ($percent>=90) ;
}

=item * get_all_authors()

Replies an array of entry authors.
Takes 1 arg:

=over

=item * data (hash ref)

=back

=cut
sub get_all_authors($) : method {
  my $self = shift ;
  my %authors = () ;
  my $parser = Bib2HTML::Translator::BibTeXName->new() ;
  foreach my $entry (sortbyletters(keys %{$_[0]})) {
    if ( $_[0]->{$entry}{'fields'}{'author'} ) {
      my @auts = $parser->splitnames($_[0]->{$entry}{'fields'}{'author'}) ;
      foreach my $aut (@auts) {	
	if ( ! $aut->{'et al'} ) {
	  $aut->{'location'} = $_[0]->{$entry}{'location'} ;
	  my $key = lc($parser->formatname( $aut, 'l f.' )) ;
	  $key =~ s/[^a-zA-Z0-1]+//g ;
	  my $count = 0 ;
	  my $thekey = $key ;
	  while ( ( $count >= 0 ) && ( exists $authors{$thekey} ) ) {
	    if ( $parser->samenames($aut,$authors{$thekey}) ) {
	      $count = -1 ;
	    }
	    else {
	      $count ++ ;
	      $thekey  = "${key}_${count}" ;
	    }
	  }
	  if ( $count >= 0 ) {
	    $authors{$thekey} = $aut ;
	  }
	}
      }
    }
  }
  return %authors ;
}

1;
__END__

=back

=head1 COPYRIGHT

(c) Copyright 2004-07 Stéphane Galland E<lt>galland@arakhne.orgE<gt>, under GPL.

=head1 AUTHORS

=over

=item *

Conceived and initially developed by Stéphane Galland E<lt>galland@arakhne.orgE<gt>.

=back

=head1 SEE ALSO

bib2html.pl
