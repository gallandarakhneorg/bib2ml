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

Bib2HTML::Generator::StdOutWriter - An output stream writer

=head1 DESCRIPTION

Bib2HTML::Generator::StdOutWriter is a Perl module, which permits to
output streams into the standard output.

=head1 SYNOPSYS

Bib2HTML::Generator::StdOutWriter->new( ) ;

=head1 DESCRIPTION

Bib2HTML::Generator::SydOutWriter is a Perl module, which permits to
output streams into the standard output.


=head1 METHOD DESCRIPTIONS

This section contains only the methods in StdOutWriter.pm itself.

=over

=cut

package Bib2HTML::Generator::StdOutWriter;

@ISA = ('Bib2HTML::Generator::Writer');
@EXPORT = qw();
@EXPORT_OK = qw();

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $VERSION);
use Exporter;
use Carp ;

use Bib2HTML::Generator::Writer;

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
  $self->{'opened'} = $filename;
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
  print STDOUT ("$str");
  return 1;
}

=pod

=item * closestream()

Close the currently opened stream.

=cut
sub closestream() {
  my $self = shift;
  delete $self->{'opened'};
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
