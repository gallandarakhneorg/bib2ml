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

Bib2HTML::Parser::Scanner - An abstract scanner for extracted bibtex entries

=head1 SYNOPSYS

use Bib2HTML::Parser::Scanner ;

my $scan = Bib2HTML::Parser::StateMachine->new(
                       transitions,
                       initial_state,
                       final_states
                       ) ;

=head1 DESCRIPTION

Bib2HTML::Parser::Scanner is a Perl module, which is a
state machine which reads a input stream. This is an
abstract scanner, i.e. it is not specific to a language
such as PHP, HTML...

=head1 GETTING STARTED

=head2 Initialization

To start a scanner, say something like this:

    use Bib2HTML::Parser::Scanner;

    my $sm = Bib2HTML::Parser::Scanner->new(
                       { '0' => [ { callback => 'myfunc',
		                    pattern => 'a+',
				    state => '1',
		                  },
				  { state => '0' },
				],
			 '1' => { state => '0',
			        },
		       },
		       '0',
		       [ '1' ]
                       ) ;

...or something similar. Acceptable parameters to the constructor are:

=over

=item * transitions (hash ref)

describes the states of this machine. It must be an
associative array in which the keys are the name of
each states, and the associated values describe the
states with an array of transitions or with only
one transition. A transition is defined as an
associative array in which the following keys are
recognized:

=over

=item * state (string)

is the name of the state on which the machine must be
after this transition. B<This value is required.>

=item * pattern (string)

is a regular expression that describe the selection
condition needed to do this translation. B<This
value is optional>. But, only once transition
is able to not defined the pattern. This special
transition is the default (if no other transition
could be selected).

=item * callback (string)

is the name (not the reference) to a function that
must be called each time this transition was selected.
B<This value is optional>.

=item * merge (boolean)

if true and the state does not changed, the recognized
token will be merged to the previous token.
B<This value is optional>.

=back

=head1 METHOD DESCRIPTIONS

This section contains only the methods in Scanner.pm itself.

=over

=cut

package Bib2HTML::Parser::Scanner;

@ISA = ('Bib2HTML::Parser::StateMachine');
@EXPORT = qw();
@EXPORT_OK = qw();

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $VERSION);
use Exporter;
use Carp ;
use File::Basename ;

use Bib2HTML::Parser::StateMachine ;
use Bib2HTML::General::Misc ;

#------------------------------------------------------
#
# Global vars
#
#------------------------------------------------------

# Version number of the scanner
my $VERSION = "1.0" ;

#------------------------------------------------------
#
# Constructor
#
#------------------------------------------------------

sub new($$$) : method {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $parent = ref($proto) && $proto ;

  my $self ;
  if ( $parent ) {
    %{$self} = %{$parent} ;
  }
  else {
    $self = $class->SUPER::new( $_[0], $_[1], $_[2] ) ;
    $self->{'LINENO'} = 0 ;
    $self->{'STATE_STACK'} = [] ;
  }
  bless( $self, $class );
  return $self;
}

#------------------------------------------------------
#
# Scanning functions
#
#------------------------------------------------------

=pod

=item * scan()

Reads a input stream. Replies if the state machine is
in a final state.
Takes 1 arg:

=over

=item * filename (string)

is the name of the file from which the tokens must
be extracted.

=back

=cut
sub scan($) : method {
  my $self = shift ;
  my $filename = $_[0] || confess( 'you must supply the filename' ) ;
  local *SOURCEFILE ;
  open( SOURCEFILE, "< $filename" )
    or Bib2HTML::General::Error::syserr( "unable to open $filename: $!" ) ;

  # Initialize the state machine
  $self->{'LINENO'} = 0 ;
  $self->{'FILENAME'} = $filename ;

  $self->resetstatemachine() ;

  while ( my $line = <SOURCEFILE> ) {
    # Read a line
    $self->{'LINENO'} ++ ;
    # Translate the red line
    # This translation is dependent of
    # the scanner which inherited from this Scanner.
    $line = $self->translate_current_line( $line ) ;
    if ( $line !~ /^(\n|\r|\s)$/ ) {
      while ( $line ) {
	# Clear the buffer which store the unget
	# tokens
	$self->{'UNGET_BUFFER'} = '' ;
	# Try to recognize the next token
	# according to the translation table
        $line = $self->changestatefrom( $line ) ;
	# In case some call to ungetpattern
	# was made, merges the unget string
	# to the start of the current red
	# line
	if ( $self->{'UNGET_BUFFER'} ) {
	  $line = $self->{'UNGET_BUFFER'} . $line ;
	}
      }
    }
  }
  $self->changestateforEOF() ;

  Bib2HTML::General::Verbose::three( join( '',
  			   	 "\t",
				 $self->{'LINENO'},
				 " line",
				 ($self->{'LINENO'}>1)?"s":"",
				 "\n" ) ) ;

  close( SOURCEFILE )
    or Bib2HTML::General::Error::syserr( "unable to close $filename: $!" ) ;

  return $self->isfinalstate() ;
}

=pod

=item * ungetpattern()

Pushes the specified string into the current red string.
Takes 1 arg:

=over

=item * text (string)

is the text that must be put inside the current stream.

=back

=cut
sub ungetpattern($) : method {
  my $self = shift ;
  my $text = $_[0] || '' ;
  $self->{'UNGET_BUFFER'} = $text . $self->{'UNGET_BUFFER'} ;
  Bib2HTML::General::Verbose::verb( join( '',
					  "\t\tUNGET = '",
					  tohumanreadable($text),
					  "'" ),
				    4 ) ;
}

=pod

=item * translate_current_line()

Replies the translation of the current line which was readed from
the current input file.
Takes 1 arg:

=over

=item * line (string)

is the line to translate.

=back

=cut
sub translate_current_line($) : method {
  my $self = shift ;
  return ($_[0] || '') ;
}

=pod

=item * push_switch_state()

Pushes the current state on the state stack and switch to the specified state.
Takes 1 arg:

=over

=item * state (string)

is the name of the new state to reach.

=back

=cut
sub push_switch_state($) : method {
  my $self = shift ;
  my $state = $_[0] || confess( 'you must supply a state' ) ;
  if ( exists $self->{'SM_STATES'}{$state} ) {
    if ( Bib2HTML::General::Verbose::currentlevel() >= 4 ) {
      my $verbstr = join( '',
     		     	  "\t\ttoken = '",
			  tohumanreadable($self->{'SM_PREVIOUS_TOKEN'}),
			  "'" ) ;
      $verbstr .= ", PUSH('".$self->{'SM_CURRENT_STATE'}."') -> '".$state."'" ;
      Bib2HTML::General::Verbose::verb( "$verbstr.", 4 ) ;
    }
    push @{$self->{'STATE_STACK'}}, $self->{'SM_CURRENT_STATE'} ;
    $self->{'SM_CURRENT_STATE'} = $state ;
  }
  else {
    Bib2HTML::General::Error::syserr( "Unable to switch to the unexisting state '$state'" ) ;
  }
}

=pod

=item * push_state()

Pushes the current state on the state stack. Does not switch to another state.
Takes 1 arg:

=over

=item * state (string)

is the name of the state to push.

=back

=cut
sub push_state($) : method {
  my $self = shift ;
  my $state = $_[0] || confess( 'you must supply the state' ) ;
  if ( exists $self->{'SM_STATES'}{$state} ) {
    if ( Bib2HTML::General::Verbose::currentlevel() >= 4 ) {
      my $verbstr = join( '',
     		     	  "\t\ttoken = '",
			  tohumanreadable($self->{'SM_PREVIOUS_TOKEN'}),
			  "'" ) ;
      $verbstr .= ", PUSH('".$self->{'SM_CURRENT_STATE'}."')" ;
      Bib2HTML::General::Verbose::verb( "$verbstr.", 4 ) ;
    }
    push @{$self->{'STATE_STACK'}}, $state ;
  }
  else {
    confess( "Unable to push the unexisting state '$state'" ) ;
  }
}

=pod

=item * pop_state()

Pops a state from the state stack and set as the new current state.

=cut
sub pop_state() : method {
  my $self = shift ;
  if ( isemptyarray( $self->{'STATE_STACK'} ) ) {
    confess( "Unable to pop a state from an empty state stack" ) ;
  }
  else {
    my $state = pop @{$self->{'STATE_STACK'}} ;
    if ( Bib2HTML::General::Verbose::currentlevel() >= 4 ) {
      my $verbstr = join( '',
     		     	  "\t\ttoken = '",
			  tohumanreadable($self->{'SM_PREVIOUS_TOKEN'}),
			  "'" ) ;
      $verbstr .= ", POP('".$self->{'SM_CURRENT_STATE'}."') -> '$state'" ;
      Bib2HTML::General::Verbose::verb( "$verbstr.", 4 ) ;
    }
    $self->{'SM_CURRENT_STATE'} = $state ;
  }
}

=pod

=item * set_state()

Sets the current state, and replies the old state.
Takes 1 arg:

=over

=item * state (string)

is the name of the new state.

=back

=cut
sub set_state($) : method {
  my $self = shift ;
  my $state = $_[0] || confess( 'you must supply the state' ) ;
  my $old = $self->{'SM_CURRENT_STATE'} ;
  $self->{'SM_CURRENT_STATE'} = $state ;
  return $old ;
}

=pod

=item * get_state()

Replies the current state machine.

=cut
sub get_state() : method {
  my $self = shift ;
  return $self->{'SM_CURRENT_STATE'} ;
}

=pod

=item * get_stackstate()

Replies the current state machine on the top of the stack.

=cut
sub get_stackstate() : method {
  my $self = shift ;
  return $self->{'STATE_STACK'}->[$#{$self->{'STATE_STACK'}}] ;
}

=pod

=item * get_statestack()

Replies the whole state stack.

=cut
sub get_statestack() : method {
  my $self = shift ;
  return @{$self->{'STATE_STACK'}} ;
}

=pod

=item * backend_error_function()

Called each time no rule match the current buffer.

=over

=item * msg (string)

is the error message.

=back

=cut
sub backend_error_function($) : method {
  my $self = shift ;
  confess( 'you must supply the error message' ) unless $_[0] ;
  Bib2HTML::General::Error::err( $_[0],
				 $self->{'FILENAME'},
				 $self->{'LINENO'} ) ;
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
