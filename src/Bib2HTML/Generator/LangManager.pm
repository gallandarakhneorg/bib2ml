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

Bib2HTML::Generator::LangManager - A Language support for the generators

=head1 SYNOPSYS

use Bib2HTML::Generator::LangManager ;

my $gen = Bib2HTML::Generator::LangManager->new( names ) ;

=head1 DESCRIPTION

Bib2HTML::Generator::LangManager is a Perl module, which proposes
a generic language support for all the generators.

=head1 GETTING STARTED

=head2 Initialization

To start a generator script, say something like this:

    use Bib2HTML::Generator::LangManager;

    my $gen = Bib2HTML::Generator::LangManager->new( [ 'English_HTMLGen',
                                                       'English' ] ) ;

...or something similar. Acceptable parameters to the constructor are:

=over

=item * names (array of strings)

is the ordred list of the desired language files.

=back

=head1 METHOD DESCRIPTIONS

This section contains only the methods in LangManager.pm itself.

=over

=cut

package Bib2HTML::Generator::LangManager;

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
use Bib2HTML::General::Verbose ;
use Bib2HTML::Generator::Lang ;

#------------------------------------------------------
#
# Global vars
#
#------------------------------------------------------

# Version number of language support
my $VERSION = "4.0" ;

# Default language
my $DEFAULT_LANGUAGE = "English";

#------------------------------------------------------
#
# Static functions
#
#------------------------------------------------------

=pod

=item * set_default_language()

Set the default language.
Takes 1 arg:

=over

=item * default (string)

is the name of the default language.

=back

=cut
sub set_default_lang($) {
  $DEFAULT_LANGUAGE = "$_[0]";
}

=pod

=item * display_supported_languages()

Display the list of supported languages.
Takes 2 args:

=over

=item * perldir (string)

is the path to the directory where the Perl packages
are stored.

=item * default (string)

is the name of the default language

=back

=cut
sub display_supported_languages($$) {
  my $path = $_[0] || confess( 'you must specify the pm path' ) ;
  my $default = $_[1] || '' ;
  my @pack = split /\:\:/, __PACKAGE__ ;
  pop @pack ;
  push @pack, 'Lang' ;
  @pack = ( File::Spec->splitdir($path), @pack ) ;
  my $glob = File::Spec->catfile(@pack, '*');
  $glob =~ s/ /\\ /g;
  foreach my $file ( glob($glob) ) {
    my $name = basename($file) ;
    if ( ( $name !~ /[._-][a-zA-Z0-9]+Gen$/ ) &&
         ( $name !~ /\.perl$/ ) && # For Perl scripts
         ( $name !~ /\.pl$/ ) && # For Perl scripts
         ( $name !~ /\.pm$/ ) && # For Perl modules
         ( $name !~ /~$/ ) ) { # For backup files
      print join( '',
		  "$name",
		  ( $default && ( $default eq $name ) ) ?
		  " (default)" : "",
		  "\n" ) ;
    }
  }
}

#------------------------------------------------------
#
# Constructor
#
#------------------------------------------------------

sub new($) : method {
  my $proto = shift;
  my $class = ref($proto) || $proto;

  # Compute the list of the desired languages
  my @desired_langs;
  if (isarray($_[0])) {
    @desired_langs = @{$_[0]};
  }
  else {
    @desired_langs = ( $_[0] );
  }
  push @desired_langs, "$DEFAULT_LANGUAGE";

  # Build the directory filename where are located the
  # language files
  my @pack = split /\:\:/, __PACKAGE__ ;
  pop @pack ;
  push @pack, 'Lang' ;

  # Get the language directory
  my $directory_path = undef;
  foreach my $path (@INC) {
    my $fullpath = File::Spec->catfile($path,@pack);
    if (-d "$fullpath") {
      $directory_path = $path;
      last;
    }
  }

  @pack = ( File::Spec->splitdir($directory_path), @pack);

  # Search for and load the desired languages
  my @lang_objs = ();
  my @real_desired_langs = ();
  foreach my $desired_lang (@desired_langs) {
    $desired_lang =~ s/[-_.=,:;!~\s]/./g;
    my $filename = File::Spec->catfile(@pack,$desired_lang);
    if (-r "$filename") {
      my $obj = Bib2HTML::Generator::Lang->new($desired_lang,"$filename");
      my $found = undef;
      foreach my $ex_lang (@lang_objs) {
        if ($ex_lang->getname() eq $desired_lang) {
          $found = 1;
          last;
        }
      }
      if (!$found) {
        push @lang_objs, $obj;
        push @real_desired_langs,$desired_lang;
      }
    }
    elsif (Bib2HTML::General::Verbose::currentlevel()>=2) {
      Bib2HTML::General::Error::syswarm( "'$filename' language file was not found or can't be red\n" );
    }
  }

  # Check for one language found
  Bib2HTML::General::Error::syserr( "Unable to find the language class\n" ) unless (@lang_objs);

  my $self = { 'langs' => (@lang_objs ? \@lang_objs : []),
               'desired_langs' => \@real_desired_langs,
               'lang_directory' => \@pack,
	     } ;

  bless( $self, $class );
  return $self;
}

=pod

=item * registerLang($)

Register a language file.
The name of the new language files must respect the following pattern:
<lang_dir>/<lang_name>.<extension>
where <lang_dir> is the predefined directory where language files
are stored, <lang_name> is the name of the language, and
<extension> is a string specified to this function.
Takes at least 1 arg:

=over

=item * extension (string)

is the extension of the language file.

=back

=cut
sub registerLang($) {
  my $self = shift;
  my $extension = shift;

  foreach my $desired_lang (@{$self->{'desired_langs'}}) {
    $desired_lang =~ s/[-_.=,:;!~\s]/./g;
    my $realname = $desired_lang.".".$extension;
    my $filename = File::Spec->catfile(@{$self->{'lang_directory'}},"$realname");
    if (-r "$filename") {
      my $obj = Bib2HTML::Generator::Lang->new("$realname","$filename");

      my $found = 0;
      foreach my $ex_lang (@{$self->{'langs'}}) {
        if ($ex_lang->getname() eq $realname) {
          $found = 1;
          last;
        }
      }

      if (!$found) {
	      unshift @{$self->{'langs'}}, $obj;
	      unshift @{$self->{'desired_langs'}}, $realname;
      }
    }
  }
}

#------------------------------------------------------
#
# Getters
#
#------------------------------------------------------

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
  my $id = $_[0] || confess( 'you must supply the id' ) ;

  my $lgs = '';

  foreach my $l (@{$self->{'langs'}}) {
    my $n = $l->_get_noerror(@_);
    if ($n) {
      return $n;
    }
    if ($lgs) {
      $lgs .= ", ";
    }
    $lgs .= "'".$l->{'name'}."'";
  }

  Bib2HTML::General::Error::syserr( "the string id '$id' is not defined ".
				     "for all the current languages: $lgs" );
  return undef;
}

=pod

=item * getname()

Replies the name of the current language.

=cut
sub getname() : method {
  my $self = shift ;
  foreach my $l (@{$self->{'langs'}}) {
    my $n = $l->getname() ;
    if ($n !~ /_[a-zA-Z0-9]+Gen$/) {
      return $n;
    }
  }
  return "unknow";
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
