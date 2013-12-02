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

Bib2HTML::Generator::Lang - A Language support for the generators

=head1 SYNOPSYS

use Bib2HTML::Generator::Lang ;

my $gen = Bib2HTML::Generator::Lang->new( name, defs ) ;

=head1 DESCRIPTION

Bib2HTML::Generator::Lang is a Perl module, which proposes
a generic language support for all the generators.

=head1 GETTING STARTED

=head2 Initialization

To start a generator script, say something like this:

    use Bib2HTML::Generator::Lang;

    my $gen = Bib2HTML::Generator::Lang->new( 'English',
					       '/usr/lib/bib2html/Langs/English' ) ;

...or something similar. Acceptable parameters to the constructor are:

=over

=item * name (string)

is the name of the current language.

=item * defs_path (string)

is the filename of the file which contains the definitions.

=back

=head1 METHOD DESCRIPTIONS

This section contains only the methods in Lang.pm itself.

=over

=cut

package Bib2HTML::Generator::Lang;

@ISA = ('Exporter');
@EXPORT = qw();
@EXPORT_OK = qw();

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $VERSION);
use Exporter;

use Carp ;

use Bib2HTML::General::Error ;
use Bib2HTML::Release ;

#------------------------------------------------------
#
# Global vars
#
#------------------------------------------------------

# Version number of language support
my $VERSION = "3.0" ;

# Language definitions
my %LANG_DEFS = ( ) ;

#------------------------------------------------------
#
# Constructor
#
#------------------------------------------------------

sub new($$) : method {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $filename = $_[1];
  my $self = { 'defs' => {},
	       'name' => $_[0] || 'unknow',
	     } ;
  bless( $self, $class );

  foreach my $key (keys %LANG_DEFS) {
    $self->{'defs'}->{$key} = $LANG_DEFS{$key} ;
  }

  %{$self->{'defs'}} = $self->loadScript("$filename");

  return $self;
}

#------------------------------------------------------
#
# Getters
#
#------------------------------------------------------

sub get_final_copyright() {
  my $final_copyright = 1998;
  my $soft_release = getVersionDate();
  if ($soft_release =~ /^([0-9]+)\/[0-9]+\/[0-9]+$/) {
    if ($1<=98) {
      $final_copyright = 2000 + $1;
    }
    elsif ($1==99) {
      $final_copyright = 1999;
    }
    else {
      $final_copyright = $1;
    }
  }

  if ($final_copyright!=1998) {
    $final_copyright = "1998-$final_copyright";
  }

  return $final_copyright;
}

sub replace_function_calls($) {
  my $str = shift;
  $str =~ s/\{\{\*([a-zA-Z0-9_]+)\}\}/{local *s=$1;&s();}/eg;
  return $str;
}

sub loadScript($) {
  my $self = shift;
  my $filename = shift;

  my %defs = ();

  if (($filename)&&(-r "$filename")) {
    local *LANG_FILE;
    open *LANG_FILE, "<$filename"
      or Bib2HTML::General::Error::syserr( "Unable to find the language file '$filename': $!\n" );

    my $lastkey = undef;
    while (my $line = <LANG_FILE>) {
      if ($lastkey) {
        $line =~ s/^\s+//;
        if ($line =~ /^(.*?)\s*\\\s*$/) {
          $line = $1;
          $defs{'$lastkey'} .= ' ' if ($defs{'$lastkey'});
          $defs{"$lastkey"} .= replace_function_calls("$line");
        }
        else {
          $line =~ s/\s+$//;
          $defs{'$lastkey'} .= ' ' if ($defs{'$lastkey'});
          $defs{"$lastkey"} .= replace_function_calls("$line");
          $lastkey = undef;
        }
      }
      else {
        if (($line)&&($line =~ /^\s*([a-aA-Z0-9_\-:]+)\s*=\s*(.*)?\s*$/)) {
          my ($key,$value) = ($1,$2);
          if ($value =~ /^(.*?)\s*\\\s*$/) {
            $value = $1;
            $lastkey = $key;
          }
          else {
            $value =~ s/\s+$//;
          }
          $defs{"$key"} = replace_function_calls("$value");
        }
      }
    }

    close *LANG_FILE;
  }

  return %defs;
}

=pod

=item * get()

Replies the specified string according to the language.
Takes at least 1 arg:

=over

=item * id (string)

is the id of the string.

=item * param1 (string)

is a string which must replace the string "#1" in the language definition.

=item * param2 (string)

is a string which must replace the string "#2" in the language definition.

=item ...

=back

=cut
sub get($) : method {
  my $self = shift ;
  my $id = shift || confess( 'you must supply the id' ) ;
  my $str = ( ( exists $self->{'defs'}{$id} ) ?
	      $self->{'defs'}{$id} : '' ) ;
  Bib2HTML::General::Error::syserr( "the string id '$id' is not defined ".
				     "for the current language '".$self->{'name'}."'" ) unless $str ;
  if ( @_ ) {
    for(my $i=0; $i<=$#_; $i++ ) {
      my $j = $i+1 ;
      my $s = $_[$i] || "#$j" ;
      $str =~ s/#$j/$s/g ;
    }
  }
  return $str ;
}

=pod

=item * _get_noerror()

Replies the specified string according to the language.
Takes at least 1 arg:

=over

=item * id (string)

is the id of the string.

=item * param1 (string)

is a string which must replace the string "#1" in the language definition.

=item * param2 (string)

is a string which must replace the string "#2" in the language definition.

=item ...

=back

=cut
sub _get_noerror($) : method {
  my $self = shift ;
  my $id = shift || confess( 'you must supply the id' ) ;
  my $str = ( ( exists $self->{'defs'}{$id} ) ?
	      $self->{'defs'}{$id} : '' ) ;
  return undef unless $str ;
  if ( @_ ) {
    for(my $i=0; $i<=$#_; $i++ ) {
      my $j = $i+1 ;
      my $s = $_[$i] || "#$j" ;
      $str =~ s/#$j/$s/g ;
    }
  }
  return $str ;
}

=pod

=item * getname()

Replies the name of the current language.

=cut
sub getname() : method {
  my $self = shift ;
  return $self->{'name'} ;
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
