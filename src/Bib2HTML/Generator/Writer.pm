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

Bib2HTML::Generator::Writer - An output stream writer

=head1 DESCRIPTION

Bib2HTML::Generator::Writer is a Perl module, which permits to
abstract the output streams used by bib2html.

=head1 SYNOPSYS

Bib2HTML::Generator::Writer->new( ) ;

=head1 DESCRIPTION

Bib2HTML::Generator::Writer is a Perl module, which permits to
abstract the output streams used by bib2html.


=head1 METHOD DESCRIPTIONS

This section contains only the methods in Writer.pm itself.

=over

=cut

package Bib2HTML::Generator::Writer;

@ISA = ('Exporter');
@EXPORT = qw();
@EXPORT_OK = qw();

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $VERSION);
use Exporter;
use Carp ;

#------------------------------------------------------
#
# Global vars
#
#------------------------------------------------------

# Version number of abstract generator
my $VERSION = "1.0" ;

#------------------------------------------------------
#
# Constructor
#
#------------------------------------------------------

sub new() : method {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $self = {} ;
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
  return 1;
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
  return 1;
}

=pod

=item * closestream()

Close the currently opened stream.

=cut
sub closestream() {
  my $self = shift;
  return 1;
}

=pod

=item * create_output_directory()

Create the output directory if required.
Replies the output filename (directory).
Takes n params:

=over

=item * output (string)

is the output directory to create

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
  my $output = shift;
  return $output;
}

=pod

=item * is_file_creation_allowed()

Replies if this writer allows to create files.

=cut
sub is_file_creation_allowed() {
  my $self = shift;
  return undef;
}

1;
__END__

=back

=head1 COPYRIGHT

(c) Copyright 1998-09 St�phane Galland E<lt>galland@arakhne.orgE<gt>, under GPL.

=head1 AUTHORS

=over

=item *

Conceived and initially developed by St�phane Galland E<lt>galland@arakhne.orgE<gt>.

=back

=head1 SEE ALSO

bib2html.pl
