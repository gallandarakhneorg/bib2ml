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

Bib2HTML::Parser::BibScanner - A scanner for extracted bibtex entries

=head1 SYNOPSYS

use Bib2HTML::Parser::BibScanner ;

my $scan = Bib2HTML::Parser::BibScanner->new() ;

=head1 DESCRIPTION

Bib2HTML::Parser::BibScanner is a Perl module, which scannes
a source file to recognize the bibtex entries

=head1 GETTING STARTED

=head2 Initialization

To start a scanner, say something like this:

    use Bib2HTML::Parser::BibScanner;

    my $scan = Bib2HTML::Parser::BibScanner->new() ;

...or something similar.

=head1 METHOD DESCRIPTIONS

This section contains only the methods in BibScanner.pm itself.

=over

=cut

package Bib2HTML::Parser::BibScanner;

@ISA = ('Bib2HTML::Parser::Scanner');
@EXPORT = qw();
@EXPORT_OK = qw();

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $VERSION);
use Exporter;
use Carp ;
use File::Basename ;

use Bib2HTML::Parser::Scanner ;
use Bib2HTML::General::Misc ;

#------------------------------------------------------
#
# Global vars
#
#------------------------------------------------------

# Version number of the scanner
my $VERSION = "2.0" ;

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
    if ( $_[0] ) {
      if ( ! $_[1] ) {
	Bib2HTML::General::Error::syserr( "You must supply the initial state to the ".
					   "BibScanner constructor" ) ;
      }
      if ( ! $_[2] ) {
	Bib2HTML::General::Error::syserr( "You must supply the final states to the ".
					  "BibScanner constructor" ) ;
      }
      $self = $class->SUPER::new( $_[0], $_[1], $_[2] ) ;
    }
    else {
      $self = $class->SUPER::new(
              { 'main' => [ { state => 'line_comment',
			      pattern => '\\%',
			      merge => 1,
			      splitmerging => 1,
			    },
			    { state => 'block_comment',
			      pattern => '\\@COMMENT\\s*\\{\\s*',
			      caseinsensitive => 1,
			    },
			    { state => 'line_comment',
			      pattern => '\\@COMMENT\b\\s*',
			      merge => 1,
			      splitmerging => 1,
			      caseinsensitive => 1,
			    },
			    { state => 'constant',
			      pattern => '\\@STRING\\s*\\{\\s*',
			      caseinsensitive => 1,
			    },
                            { state => 'preamble',
			      pattern => '\\@PREAMBLE\\s*',
			      caseinsensitive => 1,
			    },
			    { state => 'entry',
			      pattern => '@',
			      merge => 1,
			    },
                            { state => 'main',
			      pattern => '[^@%]+',
			    },
			  ],
		# Eats the comment
	        'line_comment' => [ { state => 'main',
				      pattern => "\n",
				    },
				    { state => 'line_comment',
				      pattern => "[^\n]+",
				      merge => 1,
				    },
				  ],
	        'block_comment' => [ { state => 'main',
				       pattern => "\\}",
			               splitmerging => 1,
				       merge => 1,
				     },
				     { state => 'block_comment',
				       pattern => "[^\\}]+",
				       merge => 1,
				     },
				   ],
		# Matches @something
		'entry' => [ { state => 'entry_type',
			       pattern => '[a-zA-Z]+',
			     },
			   ],
		'entry_type' => [ { state => 'entry_key',
				    pattern => "\\{\\s*",
				  },
				  { state => 'entry_type',
				    pattern => "\\s+",
				  },
			   ],
		'entry_key' => [ { state => 'entry_fields',
				   pattern => '[^,\s]+',
				 },
				 { state => 'entry_key',
				   pattern => '\\s+',
				 },
			   ],
		'entry_fields' => [ { state => 'entry_fields',
				      pattern => ',\\s*',
				    },
				    { state => 'entry_fields',
				      pattern => '\\s+',
				    },
				    { state => 'entry_fieldname',
				      pattern => '[a-zA-Z0-9.:_\\-]+',
				    },
				    { state => 'main',
				      pattern => '\\s*\\}',
				    },
				  ],
		'entry_fieldname' => [ { state => 'string',
					 pattern => '\\s*=\\s*',
				       },
				       { state => 'main',
					 pattern => '\\}',
				       },
				       { state => 'entry_fieldname',
					 pattern => '\\s+',
				       },
				       { state => 'entry_fields',
					 pattern => '.',
				       },
				     ],
		# Matches @STRING
		'constant' => [ { state => 'main',
				  pattern => '\\}',
				},
				{ state => 'constant_name',
				  pattern => '[a-zA-Z0-9.:]+',
				},
				{ state => 'constant',
				  pattern => '\\s+',
				},
			      ],
		'constant_name' => [ { state => 'string',
				       pattern => '=\\s*',
				     },
				     { state => 'main',
				       pattern => '\\}',
				     },
				     { state => 'constant_name',
				       pattern => '\\s+',
				     },
				   ],
		# Matches @PREAMBLE
		'preamble' => [ { state => 'braced_string',
				  pattern => '\\{',
				  merge => 1,
				  splitmerging => 1,
				},
				{ state => 'preamble',
				  pattern => '\\s+',
				},
			      ],
		'preamble_end' => [ { state => 'main',
				      pattern => '.',
				    },
				  ],
		# Matches a string
		'string' => [ { state => 'string',
				pattern => '\\s+',
			      },
			      { state => 'braced_string',
				pattern => '{',
				merge => 1,
				splitmerging => 1,
			      },
			      { state => 'quoted_string',
				pattern => '\"',
				merge => 1,
				splitmerging => 1,
			      },
			      { state => 'keyword_string',
				pattern => '[^\\s"{},;#]+',
			      }
			    ],
		'keyword_string' => [],
		# Matches a braced string
		'braced_string' => [ { state => 'close_braced_string',
				       pattern => '}',
				     },
				     { state => 'open_braced_string',
				       pattern => '{',
				     },
				     { state => 'braced_string',
				       pattern => '\\\\.',
				       merge => 1,
				     },
				     { state => 'braced_string',
				       pattern => '[^{}\\\\]+',
				       merge => 1,
				     }
				   ],
		'close_braced_string' => [],
		'open_braced_string' => [],
		# Matches a quoted string
		'quoted_string' => [ { state => 'quote_quoted_string',
				       pattern => '\"',
				     },
				     { state => 'quoted_string',
				       pattern => '\\\\.',
				       merge => 1,
				     },
				     { state => 'quoted_string',
				       pattern => '[^\"\\\\]+',
				       merge => 1,
				     }
				   ],
		'quote_quoted_string' => [],
		# Concatenation operator
		'concatenation_operator' => [ { state => 'string',
						pattern => '\\s*\\#\\s*',
					      },
					      { state=> 'concatenation_operator',
						pattern => '[^#]',
					      },
					    ],
	      },
	      'main',
	      [ 'main', 'line_comment' ]
              ) ;
    }
    # Initializes the class attributes
    $self->clearentries() ;
  }
  bless( $self, $class );
  return $self;
}

#------------------------------------------------------
#
# Callback functions
#
#------------------------------------------------------

sub transition_callback_concatenation_operator_concatenation_operator($) {
  my $self = shift ;
  $self->ungetpattern( $_[0] ) ;
  $self->pop_state() ;
}

sub transition_callback_concatenation_operator_string($) {
  my $self = shift ;
  $self->translate_to_contatenatedstring() ;
}

sub transition_callback_string_keyword_string($) {
  my $self = shift ;
  $self->setstring($_[0],1) ;
  $self->pop_state() ;
}

sub transition_callback_braced_string_close_braced_string($) {
  my $self = shift ;
  $self->setstring($_[0]) ;
  if ( $self->{'BUFFER'}{'BRACE_COUNT'} > 0 ) {
    $self->{'BUFFER'}{'BRACE_COUNT'} -- ;
    $self->set_state('braced_string');
  }
  else {
    $self->pop_state() ;
  }
}

sub transition_callback_braced_string_open_braced_string($) {
  my $self = shift ;
  $self->{'BUFFER'}{'BRACE_COUNT'} ++ ;
  $self->setstring($_[0]) ;
  $self->set_state('braced_string');
}

sub transition_callback_string_braced_string($) {
  my $self = shift ;
  $self->{'BUFFER'}{'BRACE_COUNT'} = 0 ;
}

sub transition_callback_quoted_string_quote_quoted_string($) {
  my $self = shift ;
  $self->setstring($_[0]) ;
  $self->pop_state('braced_string') ;
}

sub state_callback_string($$) {
  my $self = shift ;
  if ( ( $_[1] !~ /string/ ) &&
       ( $_[1] ne 'concatenation_operator' ) ) {
    $self->clearstring() ;
    $self->push_state($_[1]) ;
  }
  $self->push_state('concatenation_operator') ;
}

sub transition_callback_entry_fields_main($) {
  my $self = shift ;
  $self->addentry( $self->{'BUFFER'}{'currententry'}{'key'},
                   $self->{'BUFFER'}{'currententry'}{'type'},
                   $self->{'BUFFER'}{'currententry'}{'fields'},
		   $self->{'BUFFER'}{'currententry'}{'lineno'} ) ;
  delete( $self->{'BUFFER'}{'currententry'} ) ;
}

sub transition_callback_entry_fieldname_main($) {
  my $self = shift ;
  my $field = $self->{'BUFFER'}{'currentfield'} ;
  $self->{'BUFFER'}{'currententry'}{'fields'}{$field} = $self->clearstring() ;
  $self->transition_callback_entry_fields_main(undef) ;
}

sub transition_callback_entry_fieldname_entry_fields($) {
  my $self = shift ;
  my $field = $self->{'BUFFER'}{'currentfield'} ;
  $self->{'BUFFER'}{'currententry'}{'fields'}{$field} = $self->clearstring() ;
}

sub transition_callback_entry_fields_entry_fieldname($) {
  my $self = shift ;
  $self->{'BUFFER'}{'currentfield'} = $_[0] || '' ;
}

sub transition_callback_entry_key_entry_fields($) {
  my $self = shift ;
  $self->{'BUFFER'}{'currententry'}{'key'} = $_[0] || '' ;
}

sub transition_callback_entry_entry_type($) {
  my $self = shift ;
  my $type = $_[0] || '' ;
  $type =~ s/^\s*\@// ;
  $self->{'BUFFER'}{'currententry'} = { 'type' => lc($type),
					'lineno' => $self->{'LINENO'},
				      } ;
}

sub transition_callback_preamble_braced_string($) {
  my $self = shift ;
  $self->{'BUFFER'}{'BRACE_COUNT'} = 0 ;
  $self->push_state('preamble_end');
}

sub transition_callback_preamble_end_main($) {
  my $self = shift ;
  $self->addpreamble( $self->clearstring(), $self->{'LINENO'} ) ;
  $self->ungetpattern($_[0]);
}

sub transition_callback_constant_constant_name($) {
  my $self = shift ;
  $self->{'BUFFER'}{'constant'}{'name'} = $_[0] || '' ;
  $self->{'BUFFER'}{'constant'}{'lineno'} = $self->{'LINENO'} ;
}

sub transition_callback_constant_name_main($) {
  my $self = shift ;
  $self->addconstant( $self->{'BUFFER'}{'constant'}{'name'},
                      $self->clearstring(),
		      $self->{'BUFFER'}{'constant'}{'lineno'} ) ;
}

sub transition_callback_block_comment_main($) {
  my $self = shift ;
  $self->addcomment("$_[0]");
}

#------------------------------------------------------
#
# Scanning API
#
#------------------------------------------------------

=pod

=item * scanentries()

Replies an array that contains the bibtex
parts readed from the source file.
Takes 1 arg:

=over

=item * filename (string)

is the name of the file from which the bibtex parts must
be extracted.

=back

=cut
sub scanentries($) : method {
  my $self = shift ;
  my $filename = $_[0] || confess( 'you must supply the filename' ) ;
  $self->clearentries() ;
  $self->clearstring() ;

  if ( ! $self->scan( $filename ) ) {
    Bib2HTML::General::Error::err( "Unexpected end of file (state: ".$self->{'SM_CURRENT_STATE'}.")",
				   $filename,
				   $self->{'LINENO'} ) ;
  }

  Bib2HTML::General::Verbose::three( join( '',
					   "\t",
					   hashcount($self->{'BIBSCANNER_ENTRIES'}{'entries'}),
					   " entr",
					   (hashcount($self->{'BIBSCANNER_ENTRIES'}{'entries'})>1)?"ies":"y" ) ) ;

  return $self->getentries() ;
}

#------------------------------------------------------
#
# Block functions
#
#------------------------------------------------------

=pod

=item * clearentries()

Destroyes all recognized blocks.

=cut
sub clearentries() {
  my $self = shift ;
  $self->{'BIBSCANNER_ENTRIES'} = { 'constants' => {},
				    'comments' => [],
				    'preambles' => [],
				    'entries' => {},
				  } ;
}

=pod

=item * getentries()

Replies the readed entries

=cut
sub getentries() {
  my $self = shift ;
  return $self->{'BIBSCANNER_ENTRIES'} ;
}

=pod

=item * addconstant()

Adds a constant inside the readed data.
Takes 3 args:

=over

=item * name (string)

is the name of the constant

=item * value (string)

is the value of the constant

=item * lineno (integer)

is the line number where the constant starts

=back

=cut
sub addconstant($$$) {
  my $self = shift ;
  my $name = $_[0] || '' ;
  my $lineno = $_[2] || 0 ;
  my $lcname = lc( $name ) ;
  if ( ! $lcname ) {
    Bib2HTML::General::Error::warm( "I expected a string name. Ignore this constant definition.",
				    $self->{'FILENAME'},
				    $self->{'LINENO'} ) ;
  }
  elsif ( exists $self->{'BIBSCANNER_ENTRIES'}{'constants'}{$lcname} ) {
    Bib2HTML::General::Error::warm( "the \@STRING '".$name."' was already ".
				    "defined. Ignored the last instance.",
				    $self->{'FILENAME'},
				    $lineno ) ;
  }
  else {
    $self->{'BIBSCANNER_ENTRIES'}{'constants'}{$lcname}{'text'} = $_[1] ;
    $self->{'BIBSCANNER_ENTRIES'}{'constants'}{$lcname}{'location'} = $self->{'FILENAME'}.":".$lineno ;
  }
}

=pod

=item * addcomment()

Adds a comment inside the readed data.
Takes 3 args:

=over

=item * value (string)

is the value of the comment

=back

=cut
sub addcomment($) {
  my $self = shift ;
  my $value = $_[0] || '' ;
  push @{$self->{'BIBSCANNER_ENTRIES'}{'comments'}}, "$value";
}

=pod

=item * addpreamble()

Adds a preamble inside the readed data.
Takes 1 args:

=over

=item * content (string)

is the content of the preamble

=item * lineno (integer)

is the line number where the preamble starts

=back

=cut
sub addpreamble($$) {
  my $self = shift ;
  my $lineno = $_[1] || 0 ;
  if ( $_[0] ) {
    push @{$self->{'BIBSCANNER_ENTRIES'}{'preambles'}}, { 'tex' => $_[0],
							  'location' => $self->{'FILENAME'}.":".$lineno,
							} ;
  }
}

=pod

=item * addentry()

Adds an entry inside the readed data.
Takes 3 args:

=over

=item * key (string)

is the bibtex key

=item * type (string)

is the bibtex type of the entry

=item * fields (hash)

is the list of the field for this entry

=item * lineno (integer)

is the line number where the entry starts

=back

=cut
sub addentry($$$$) {
  my $self = shift ;
  my $key = $_[0] || confess( 'you must supply the entry key' ) ;
  my $type = $_[1] || confess( 'you must supply the entry type' ) ;
  my $fields = $_[2] || { } ;
  my $lineno = $_[3] || 0 ;
  $fields = { } unless ishash( $fields ) ;

  if ($key !~ /^[a-zA-Z0-9.:_\-=\+]+$/) {
    Bib2HTML::General::Error::warm( "the entry '".$key."' does not respect the ".
				    "official entry key guidelines from ".
				    "the BibTeX specifications.",
				    $self->{'FILENAME'},
				    $lineno ) ;
  }

  if ( exists $self->{'BIBSCANNER_ENTRIES'}{'entries'}{$key} ) {
    Bib2HTML::General::Error::warm( "the entry '".$key."' was already ".
				    "defined. Ignored the last instance.",
				    $self->{'FILENAME'},
				    $lineno ) ;
  }
  else {
    $self->{'BIBSCANNER_ENTRIES'}{'entries'}{$key}{'type'} = lc($type) ;
    $self->{'BIBSCANNER_ENTRIES'}{'entries'}{$key}{'location'} = $self->{'FILENAME'}.":".$lineno ;
    $self->{'BIBSCANNER_ENTRIES'}{'entries'}{$key}{'dirname'} = dirname($self->{'FILENAME'}) ;
    while ( my ($k, $value) = each (%{$fields}) ) {
      # Patched by: Martin P.J. ZINSER <zinser@zinser.no-ip.info>
      #   lc was added to support multi-case field names
      $self->{'BIBSCANNER_ENTRIES'}{'entries'}{$key}{'fields'}{lc($k)} = $value ;
    }
  }
}

#------------------------------------------------------
#
# String functions
#
#------------------------------------------------------

=pod

=item * clearstring()

Clear the string, and replies the old value.

=cut
sub clearstring() {
  my $self = shift ;
  my $str = $self->getstring() ;
  delete( $self->{'BUFFER'}{'string'} ) ;
  return $str ;
}

=pod

=item * getstring()

Replies the current string.

=cut
sub getstring() {
  my $self = shift ;
  if ( isarray( $self->{'BUFFER'}{'string'} ) ) {
    for(my $i=0; $i<=$#{$self->{'BUFFER'}{'string'}}; $i++) {
      $self->{'BUFFER'}{'string'}[$i] = $self->cleanstring($self->{'BUFFER'}{'string'}[$i]) ;
    }
    return $self->{'BUFFER'}{'string'} ;
  }
  else {
    return $self->cleanstring($self->{'BUFFER'}{'string'}) ;
  }
}

=pod

=item * cleanstring()

Removes string delimiters.
Takes 1 arg:

=over

=item * text (string)

is the string to remove.

=over

=cut
sub cleanstring($) {
  my $self = shift ;
  my $text = $_[0] || '' ;
  $text =~ s/[ \t]*[\n\r][ \t]*/ /gm ;
  if ( $text =~ /^\".*\"$/ ) {
    $text =~ s/^\"/{/ ;
    $text =~ s/\"$/}/ ;
  }
  return $text ;
}

=pod

=item * setstring()

Sets the string.

=cut
sub setstring($;$) {
  my $self = shift ;
  my $iskeyword = $_[1] || 0 ;
  my $str = $_[0] || '' ;
  if ( isarray( $self->{'BUFFER'}{'string'} ) ) {
    my $last = $#{$self->{'BUFFER'}{'string'}} ;
    if ( $self->{'BUFFER'}{'string'}[$last] ) {
      $self->{'BUFFER'}{'string'}[$last] .= $str ;
    }
    else {
      $self->{'BUFFER'}{'string'}[$last] = $str ;
    }
  }
  elsif ( $self->{'BUFFER'}{'string'} ) {
    $self->{'BUFFER'}{'string'} .= $str ;
  }
  else {
    $self->{'BUFFER'}{'string'} = $str ;
  }
}

=pod

=item * translate_to_contatenatedstring()

Sets the string as a concatened string if
it was not already set as.
Adds an empty element to this contatened
string.
A concatened string is used to split the 
different components of the string in order
to extract the potential string constant to
replace.

=cut
sub translate_to_contatenatedstring() {
  my $self = shift ;
  force_add_value_entry($self->{'BUFFER'}, 'string', '' ) ;
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
