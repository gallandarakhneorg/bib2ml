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

Bib2HTML::Generator::FileWriter - An output stream writer

=head1 DESCRIPTION

Bib2HTML::Generator::FileWriter is a Perl module, which permits to
output streams into files.

=head1 SYNOPSYS

Bib2HTML::Generator::FileWriter->new( ) ;

=head1 DESCRIPTION

Bib2HTML::Generator::FileWriter is a Perl module, which permits to
output streams into files.


=head1 METHOD DESCRIPTIONS

This section contains only the methods in FileWriter.pm itself.

=over

=cut

package Bib2HTML::Generator::FileWriter;

@ISA = ('Bib2HTML::Generator::Writer');
@EXPORT = qw();
@EXPORT_OK = qw();

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $VERSION);
use Exporter;
use Carp ;

use File::Path;
use File::Spec;

use Bib2HTML::Generator::Writer;
use Bib2HTML::General::Misc;
use Bib2HTML::General::Error;

#------------------------------------------------------
#
# Global vars
#
#------------------------------------------------------

# Version number of abstract generator
my $VERSION = "1.0" ;

# Opened streams
my @opened_streams = ();

#------------------------------------------------------
#
# Constructor
#
#------------------------------------------------------

sub new() : method {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $self = $class->SUPER::new() ;
  bless( $self, $class );
  return $self;
}

=pod

=item * openstream($)

Open the output stream.
Takes 1 param:

=over

=item * filename (string)

is the name of the output file.

=back

=cut
sub openstream($) {
  my $self = shift;
  my $filename = shift || confess( 'you must supply the root directory' ) ;
  confess('output stream already opened') if ($self->{'opened'});
  my $streamname = '';

  do {
    my $count = int(rand(5));
    $streamname = $filename;
    $streamname =~ s/[^a-zA-Z]//g;
    for(my $i=0; $i<$count; $i++) {
      my $c = rand(26);
      $streamname .= chr(ord('A')+$c);
    }
  }
  while (strinarray("$streamname",\@opened_streams));

  local *OUTPUTFILE;
  *OUTPUTFILE = $streamname;
  my $r = open( OUTPUTFILE, "> $filename" );
  if ($r) {
    $self->{'opened'} = "$streamname";
    push @opened_streams, "$streamname";
  }
  return $r;
}

=pod

=item * out($)

Put a string into the output stream.
Takes 1 param:

=over

=item * str (string)

is the string to output.

=back

=cut
sub out($) {
  my $self = shift;
  my $str = shift || '';
  if ($self->{'opened'}) {
    local *OUTPUTFILE;
    *OUTPUTFILE = $self->{'opened'};
    print OUTPUTFILE ("$str");
    return 1;
  }
  else {
    return undef;
  }
}

=pod

=item * closestream()

Close the currently opened stream.

=cut
sub closestream() {
  my $self = shift;
  if ($self->{'opened'}) {
    local *OUTPUTFILE;
    *OUTPUTFILE = $self->{'opened'};
    close(OUTPUTFILE);
    @opened_streams = grep {($self->{opened} ne $_)} @opened_streams;
    delete $self->{'opened'};
    return 1;
  }
  else {
    return undef;
  }
}

=pod

=item * create_output_directory()

Create the output directory if required.
Replies the output filename (directory).
Takes n params:

=over

=item * output (string)

is the output directory to create.

=item * exceptions (list of strings)

is the list of the file in the existing output directory
to not remove.

=back

=cut
sub create_output_directory($@) {
  my $self = shift;
  my $output = shift ;
  if ( ! $output ) {
    $output = File::Spec->catdir( ".", "bib2html" ) ;
  }
  if ( ! -d "$output" ) {
    mkdir( "$output", 0777 )
      or Bib2HTML::General::Error::syserr( "$output: $!\n" );
  }
  else {
    $self->_clear_output_directory("$output", @_);
  }
  return "$output" ;
}

=pod

=item * _clear_output_directory()

Clear the content of the output directory.

=cut
sub _clear_output_directory($@) {
  my $self = shift;
  my $output = shift ;
  my @protect = ();

  foreach my $expr (@_) {
    push @protect, shell_to_regex($expr);
  }

  local *DIR;
  opendir(*DIR,"$output") 
      or Bib2HTML::General::Error::syserr( "The output directory '$output".
					   "' can't be opened: $!\n" ) ;
  while (my $subfile = readdir(*DIR)) {
    if (($subfile ne File::Spec->curdir())&&($subfile ne File::Spec->updir())) {
      my $valid = 1;

      foreach my $expr (@protect) {
        if ($subfile =~ /$expr/) {
          $valid = undef;
          last;
        }
      }

      if ($valid) {
        my $fullpath = File::Spec->catfile("$output","$subfile");

        if ( -d "$fullpath" ) {
          rmtree( "$fullpath" )
            or Bib2HTML::General::Error::syserr( "The directory '$fullpath".
					          "' can't be deleted: $!\n" ) ;
        }
        else {
          unlink( "$fullpath" )
            or Bib2HTML::General::Error::syserr( "The file '$fullpath".
					          "' can't be deleted: $!\n" ) ;
        }
      }
    }
  }
  closedir(*DIR);
}

=pod

=item * is_file_creation_allowed()

Replies if this writer allows to create files.

=cut
sub is_file_creation_allowed() {
  my $self = shift;
  return 1;
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
