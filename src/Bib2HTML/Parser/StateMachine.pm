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

Bib2HTML::Parser::StateMachine - A state machine

=head1 SYNOPSYS

use Bib2HTML::Parser::StateMachine ;

my $sm = Bib2HTML::Parser::StateMachine->new(
                       transitions,
                       initial_state,
                       final_states
                       ) ;

=head1 DESCRIPTION

Bib2HTML::Parser::StateMachine is a Perl module, which 
implementes a state machine.

=head1 GETTING STARTED

=head2 Initialization

To start a scanner, say something like this:

    use Bib2HTML::Parser::StateMachine;

    my $sm = Bib2HTML::Parser::StateMachine->new(
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

is the name of the state on which the machine must <be
after this transition. B<This value is required.>

=item * pattern (string)

is a regular expression that describe the selection
condition needed to do this translation. B<This
value is optional>. But, only once transition
is able to not defined the pattern. This special
transition is the default (if no other transition
could be selected). If the pattern was equal to
the string "$EOF", it matchs the end of the stream
(see changestateforEOF()).

=item * callback (string)

is the name (not the reference) to a function that
must be called each time this transition was selected.
B<This value is optional>.

=item * merge (boolean)

if true, the recognized
token will be merged to the next token.
B<This value is optional>.

=item * splitmerging (boolean)

if true, the previously saved tokens
are passed to the callbacks functions.
If I<merge> was also true, the current
token is not merging.
B<This value is optional>.

=back

=item * initial_state (string)

is the name of the initial state of the machine.
This state must be defined inside the previous parameter.

=item * final_states (array ref)

is an array that lists all the final states recognized
by this machine. This array is used by isfinalstate()
to determine is this machine is inside a stable final
state.

=back

=head2 State change

To change the state of the machine, say something like this:

    $scan->changestatefrom( "the string" ) ;
    
...where "the string" is a string which permits to select
the next state.

=head1 METHOD DESCRIPTIONS

This section contains only the methods in StateMachine.pm itself.

=over

=cut

package Bib2HTML::Parser::StateMachine;

@ISA = ('Exporter');
@EXPORT = qw();
@EXPORT_OK = qw();

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $VERSION);
use Exporter;
use Carp ;
use File::Basename ;

use Bib2HTML::General::Misc ;
use Bib2HTML::General::Verbose ;

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
    $self = { } ;
    # Sets the description of this machine
    $self->{'SM_STATES'} = { 'SM_PREVIOUS_TOKEN' => "",
                           } ;
    foreach my $state ( keys %{$_[0]} ) {
      my $list ;
      # Gets the list of the transitions
      if ( isarray( $_[0]{$state} ) ) {
        $list = $_[0]{$state} ;
      }
      else {
        $list = [ $_[0]{$state} ] ;
      }
      # Checks the transitions
      my $default = 0 ;
      foreach my $trans ( @{$list} ) {
        # Search for the target state
	if ( ( exists $trans->{'state'} ) &&
	     ( "s".$trans->{'state'} eq "s" ) ) {
	  confess( "A transition of the state '$state' ".
	           "must have a target state." ) ;
	}
	if ( ! exists $_[0]{$trans->{'state'}} ) {
	  confess( "The transition state '".
	           $trans->{'state'}.
	           "' from '$state' was not found." ) ;
	}
        # Search for the default transition
        if ( ! $trans->{'pattern'} ) {
	  if ( $default ) {
	    confess( "More than once default transition ".
	             "for the transition '$state'." ) ;
	  }
	  $default = 1 ;
	  $trans->{'pattern'} = '.' ;
	}
	elsif ( ! is_valid_regex( $trans->{'pattern'} ) ) {
	  confess( "The regular expression '".
	           $trans->{'pattern'}.
		   "' is not well-formed." ) ;
	}
      }
      # Copies the state
      @{$self->{'SM_STATES'}{$state}} = @{$list} ;
    }

    # Sets the initial state
    if ( exists $self->{'SM_STATES'}{$_[1]} ) {
      $self->{'SM_INITIAL_STATE'} = $_[1] ;
      $self->{'SM_CURRENT_STATE'} = $_[1] ;
    }
    else {
      confess( "The initial state '$_[1]' is not defined." ) ;
    }

    # Sets the final states
    $self->{'SM_FINAL_STATES'} = [] ;
    foreach my $state ( @{$_[2]} ) {
      if ( exists $self->{'SM_STATES'}{$state} ) {
        push( @{$self->{'SM_FINAL_STATES'}}, $state ) ;
      }
      else {
        confess( "The final state '$state' is not defined." ) ;
      }
    }
    if ( isemptyarray( $self->{'SM_FINAL_STATES'} ) ) {
      confess( "No final state defined." ) ;
    }
  }
  bless( $self, $class );
  return $self;
}

#------------------------------------------------------
#
# Getters / Setters
#
#------------------------------------------------------

=pod

=item * getcurrentstate()

Replies the name of the current state of this
machine.

=cut
sub getcurrentstate() : method {
  my $self = shift ;
  return $self->{'SM_CURRENT_STATE'} ;
}

=pod

=item * isfinalstate()

Replies the machine is inside a final state.

=cut
sub isfinalstate() : method {
  my $self = shift ;
  return strinarray( $self->{'SM_CURRENT_STATE'},
                     $self->{'SM_FINAL_STATES'} ) ;
}

=pod

=item * resetstatemachine()

Forces the state of this machine to the initial
state.

=cut
sub resetstatemachine() : method {
  my $self = shift ;
  $self->{'SM_CURRENT_STATE'} = $self->{'SM_INITIAL_STATE'} ;
  $self->{'SM_PREVIOUS_TOKEN'} = "" ;
}

#------------------------------------------------------
#
# State changement functions
#
#------------------------------------------------------

=pod

=item * changestatefrom()

This method permits to select the new state according to
the specified string and to the current state.
The state transitions are defined when initializing.
This method calls the callback function specified
to the constructor, or (if not exists) calls the
class methods transition_callback_XXX_YYY() and
state_callback_YYY(), where XXX is the name of 
the old state, and YYY is the name of the new state.

This method replies the rest of the specified
parameter that is not eaten.

Takes 1 arg:

=over

=item * token (string)

is eaten to determine the new state.

=back

=item * transition_callback_XXX_YYY()

This method is called each time a transition
from the state XXX to the state YYY was
encountered.
Takes 1 arg:

=over

=item * token (string)

is the last recognized token.

=back

=item * state_callback_YYY()

This method is called each time the machine
arrived inside a state (except for the
initial state).
Takes 1 arg:

=over

=item * token (string)

is the last recognized token.

=back

=cut
sub changestatefrom($) : method {
  my $self = shift ;
  my $input = $_[0] || '' ;

  # Searches the max token matching
  my $trans = $self->_searchtransition( $input, 0 ) ;

  # Treats the translation matching
  if ( ! isemptyhash( $trans ) ) {
    my ($token,$rest) ;
    if ( $trans->{'caseinsensitive'} ) {
      $input =~ /^($trans->{'pattern'})(.*)$/si ;
      ($token,$rest) = ($1,$2) ;
    }
    else {
      $input =~ /^($trans->{'pattern'})(.*)$/s ;
      ($token,$rest) = ($1,$2) ;
    }

    my $oldstate = $self->{'SM_CURRENT_STATE'} ;
    $self->{'SM_CURRENT_STATE'} = $trans->{'state'} ;
    $input = $rest ;

    my $for_event = undef ;
    if ( ( $trans->{'merge'} ) &&
       	 ( $trans->{'splitmerging'} ) ) {
      # Generates an transition event
      # and merges the current token
      $for_event = $self->{'SM_PREVIOUS_TOKEN'} ;
      $self->{'SM_PREVIOUS_TOKEN'} = $token ;
    }
    elsif ( ( $trans->{'merge'} ) &&
       	    ( ! $trans->{'splitmerging'} ) ) {
      # Merges the current token
      $self->{'SM_PREVIOUS_TOKEN'} .= $token ;
   }
   else {
     # Does not merged the current token
     $for_event = $self->{'SM_PREVIOUS_TOKEN'} . $token ;
     $self->{'SM_PREVIOUS_TOKEN'} = "" ;
   }

   if ( defined $for_event ) {
     $self->_callback( $for_event,
   		       $oldstate,
		       $trans ) ;
   }
  }
  elsif ( $self->can('backend_error_function') ) {
    $self->backend_error_function( "Syntax error: unexpected character sequence \"".
                                   tohumanreadable("$input").
                                   "\"\n(unable to find a transition from ".
				   "the state '".
				   $self->{'SM_CURRENT_STATE'}.
				   "')." ) ;
    exit(1) ;
  }
  else {
    confess( "Syntax error: unexpected character sequence \"".
             tohumanreadable("$input").
             "\"\n(unable to find a transition from ".
	     "the state '".
	     $self->{'SM_CURRENT_STATE'}.
	     "')." ) ;
  }
  return $input ;
}

=pod

=item * changestateforEOF()

This method permits to select the new state according to
an EOF and to the current state.
The state transitions are defined when initializing.
This method calls the class method 
EOF_callback_function() (only if no transition with
the pattern '$EOF' was found from the current state).

=item * EOF_callback_function()

The methid is called each time the EOF was encountered
and a transition with pattern '$EOF' is not found from
the current state.

=over

=item * token (string)

is the token which is not already eaten by the machine.

=back

=cut
sub changestateforEOF() : method {
  my $self = shift ;

  # Calls the callback functions
  # if a token was not treated

  my $trans = $self->_searchtransition( "", 1 ) ;
  if ( ! isemptyhash( $trans ) ) {
    my $oldstate = $self->{'SM_CURRENT_STATE'} ;
    $self->{'SM_CURRENT_STATE'} = $trans->{'state'} ;
    $self->_callback( $self->{'SM_PREVIOUS_CONTENT'},
    		      $oldstate,
		      $trans ) ;
  }
  else {
    if ( Bib2HTML::General::Verbose::currentlevel() >= 4 ) {
      my $verbstr = join( '',
     		     	  "\t\ttoken = '",
			  tohumanreadable($self->{'SM_PREVIOUS_TOKEN'}),
			  "'" ) ;
      $verbstr .= ", when EOF in '".$self->{'SM_CURRENT_STATE'}."'" ;
      Bib2HTML::General::Verbose::verb( "$verbstr.", 4 ) ;
    }
    my $reffunc = $self->can( "EOF_callback_function" ) ;
    if ( $reffunc ) {
      $self->$reffunc( $self->{'SM_PREVIOUS_TOKEN'} ) ;
    }
  }
}

=pod

=item * _callback()

Calls the callback functions.
Takes 3 args:

=over

=item * token (string)

is the token to pass to the callback functions.

=item * old_state (string)

is the name of the state before the transition
(the name of the state after the transition is
stored inside $self->{'SM_CURRENT_STATE'}).

=item * transition (hash ref)

is the transition choosen.

=back

=cut
sub _callback($$$) : method {
  my $self = shift ;
  my $token = $_[0] || '' ;
  my $oldstate = $_[1] || confess( 'you must supply the old state' ) ;
  if ( Bib2HTML::General::Verbose::currentlevel() >= 4 ) {
    my $verbstr = join( '',
     		     	"\t\ttoken = '",
			tohumanreadable($token),
			"'" ) ;
    if ( $self->{'SM_CURRENT_STATE'} eq $oldstate ) {
      $verbstr .= ", in state '".tohumanreadable($oldstate)."'" ;
    }
    else {
      $verbstr .= join( '',
      	       	  	", transition: '",
			tohumanreadable($oldstate),
			"' -> '",
			tohumanreadable($self->{'SM_CURRENT_STATE'}),
			"'" ) ;
    }
    Bib2HTML::General::Verbose::verb( "$verbstr.", 4 ) ;
  }

  if ( ishash( $_[2] ) ) {
    if ( ( exists $_[2]->{'callback'} ) &&
	 ( my $func = $self->can($_[2]->{'callback'}) ) ) {
      $self->$func( $token, $oldstate ) ;
    }
    else {
      my $reffunc = $self->can( "transition_callback_".
        	 	    	$oldstate."_".
      	 	    	        $self->{'SM_CURRENT_STATE'} ) ;
      if ( $reffunc ) {
        $self->$reffunc( $token ) ;
      }
      $reffunc = $self->can( "state_callback_".
      	 	    	     $self->{'SM_CURRENT_STATE'} ) ;
      if ( $reffunc ) {
        $self->$reffunc( $token, $oldstate ) ;
      }
    }
  }
}

=pod

=item * _searchtransition()

Search a valid transition
Takes 2 args:

=over

=item * input (string)

is the content of the string to scan.

=item * eof (boolean)

is true if an EOF was encountered. In this
case, the I<input> will be ignored.

=back

=cut
sub _searchtransition($$) : method {
  my $self = shift ;
  my $input = $_[0] || '' ;
  my $eof = $_[1] || 0 ;
  # Searches the max token matching
  my $maxlength = 0 ;
  my $trans = {} ;
  my $recognizedtoken = "" ;
  foreach my $t (@{$self->{'SM_STATES'}{$self->{'SM_CURRENT_STATE'}}}) {
    if ( ( ( $eof ) &&
           ( $input eq '$EOF' ) ) ||
         ( ( $t->{'caseinsensitive'} ) &&
	   ( $input =~ /^($t->{'pattern'})/si ) ) ||
	 ( ( ! $t->{'caseinsensitive'} ) &&
	   ( $input =~ /^($t->{'pattern'})/s ) ) ) {
      my $token = $1 ;
      if ( length($token) > $maxlength ) {
        $maxlength = length($token) ;
	$trans = $t ;
	$recognizedtoken = $token ;
      }
    }
  }
  if ( ( $recognizedtoken ) && ( Bib2HTML::General::Verbose::currentlevel() >= 5 ) ) {
    Bib2HTML::General::Verbose::verb( join( '',
					     "\t\tnext transition:\n\t\t\tfrom: ",
					     $self->{'SM_CURRENT_STATE'},
					     "\n\t\t\tto: ",
					     $trans->{'state'},
					     "\n\t\t\tpattern: /",
					     $trans->{'pattern'},
					     "/\n\t\t\ttoken: '",
					     $recognizedtoken,
					     "'\n"),
				       5 ) ;
  }
  return $trans ;
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
