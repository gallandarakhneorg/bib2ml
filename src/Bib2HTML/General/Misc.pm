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

Bib2HTML::General::Misc - Miscellaneous definitions

=head1 DESCRIPTION

Bib2HTML::General::Misc is a Perl module, which proposes
a set of miscellaneous functions.

=head1 METHOD DESCRIPTIONS

This section contains only the methods in Misc.pm itself.

=over

=cut

package Bib2HTML::General::Misc;

@ISA = ('Exporter');
@EXPORT = qw( &strinarray &mkdir_rec &add_value_entry
	      &isemptyhash &buildtree &removefctbraces
	      &addfctbraces &extract_file_from_location
	      &extract_line_from_location &formathashkeyname
	      &formatfctkeyname &isarray &ishash &isemptyarray
	      &hashcount &is_valid_regex &tohumanreadable
              &readfileastext &valueinhash &issub &isnumber
	      &arabictoroman &romantoarabic &extract_first_words
	      &force_add_value_entry &tonumber &addslashes
	      &restore_strings &remove_strings &removeslashes
	      &array_slice &filecopy &ucwords
	      &integer2alphabetic &splittocolumn &uniq &trim
	      &splittocolumn_base &levenshtein
	      &levenshtein_ops &shell_to_regex);
@EXPORT_OK = qw();

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $VERSION);

use File::Spec ;
use File::Copy ;

#------------------------------------------------------
#
# Global vars
#
#------------------------------------------------------

# Version number of the misc functions
my $VERSION = "4.0" ;

#------------------------------------------------------
#
# General purpose functions
#
#------------------------------------------------------

=pod

=item * splittocolumn_base()

Replies the specified text splitted to the given column.
This function treats the text line by line.
Takes 3 args:

=over

=item * text (string)

=item * column (integer)

=item * header (optional string)

is the text to merge in the begining of each line.

=back

=cut
sub splittocolumn_base($$;$) {
  my $source = shift || '' ;
  my $size = shift || 0 ;

  return "$source" unless (($source)&&($size>0)) ;

  my $header = shift || '' ;

  my @result = () ;

  foreach my $line (split(/[\n\r\f]/, "$source")) {

    my $result = '' ;
    my $linesize = 0 ;
    my $startline = 1 ;

    foreach my $w (split(/[ \t]+/, $line)) {
      if ($w) {

	if ($startline) {
	  $linesize = length("$w")+length("$header") ;
	  $result .= "$header$w" ;
	  $startline = 0 ;

       	}
	else {

	  if (($linesize+length($w)+1)>$size) {
	    $result .= "\n$header$w" ;
	    $linesize = length("$header")+length($w) ;
	  }
	  else {
	    $result .= " $w" ;
	    $linesize += length($w)+1 ;
	  }

	}
      }
    }

    push @result, "$result" ;

  }

  return join("\n",@result) ;
}

=pod

=item * splittocolumn()

Replies the specified text splitted to the given column.
This function treats the text line by line.
Takes 4 args:

=over

=item * text (string)

=item * column (integer)

=item * ident (integer)

is the text which will be merged to each begining
of lines.

=item * firstindent (integer)

if positive, indicates how mush the first line must be indented

=back

=cut
sub splittocolumn($$$;$) {
  my $source = shift || '' ;
  my $size = shift || 0 ;

  return "$source" unless (($source)&&($size>0)) ;

  my $indent = shift || 0 ;
  my $firstindent = shift ;
  $firstindent = 0 unless (($firstindent)&&($firstindent>0)) ;

  my ($indent_str,$first_indent) = ('','') ;

  {
    for(my $i=0; (($i<$indent)||($i<$firstindent)); $i++) {
      $indent_str .= ' ' if ($i<$indent) ;
      $first_indent .= ' ' if ($i<$firstindent) ;
    }
  }
  my @result = () ;
  my $veryfirstline = 1 ;

  foreach my $line (split(/[\n\r\f]/, "$source")) {

    my $result = '' ;
    my $linesize = 0 ;
    my $startline = 1 ;

    foreach my $w (split(/[ \t]+/, $line)) {
      if ($w) {

	if ($startline) {
	  $linesize = length("$w") ;
	  if ($veryfirstline) {
	    $linesize += $firstindent ;
	    $result .= "$first_indent" ;
	  }
	  $result .= "$w" ;
	  $startline = 0 ;

       	}
	else {

	  if (($linesize+length($w)+1)>$size) {
	    $result .= "\n$indent_str$w" ;
	    $linesize = $indent+length($w) ;
	  }
	  else {
	    $result .= " $w" ;
	    $linesize += length($w)+1 ;
	  }

	}
      }
    }

    push @result, "$result" ;
    $veryfirstline = 0 ;

  }

  return join("\n",@result) ;
}

=pod

=item * strinarray()

Replies if the specified value is in an array.
Takes 2 args:

=over

=item * str (string)

is the string to search.

=item * array (array ref)

is the array in which the string will be searched.

=back

=cut
sub strinarray($$) {
  return 0 unless ( $_[1] ) && ( $_[0] ) ;
  foreach my $g (@{$_[1]}) {
    if ( $g eq $_[0] ) {
      return 1 ;
    }
  }
  return 0 ;
}

=pod

=item * valueinhash()

Replies if the specified value is a value of thez associative array.
Takes 2 args:

=over

=item * str (string)

is the string to search.

=item * hash (hash ref)

is the associative array in which the string will be searched.

=back

=cut
sub valueinhash($$) {
  return 0 unless ( $_[1] ) && ( $_[0] ) ;
  foreach my $k (keys %{$_[1]}) {
    if ( ( $_[1]->{$k} ) &&
         ( $_[1]->{$k} eq $_[0] ) ) {
      return 1 ;
    }
  }
  return 0 ;
}

=pod

=item * mkdir_rec()

Creates recursively a directory.
Takes 1 arg:

=over

=item * path (string)

is the name of the directory to create.

=back

=cut
sub mkdir_rec($) {
  # Fix proposed by joezespak@yahoo.com:
  # platform-independant paths
  return 0 unless $_[0] ;
  my $param = File::Spec->rel2abs($_[0]) ;
  my @parts = File::Spec->splitdir( $param ) ;
  my $current = "" ;
  foreach my $r (@parts) {
    # Fix by joezespak@yahoo.com:
    # support of absolute paths
    if ( $r ) {
      $current = File::Spec->catdir($current,$r) ;
    }
    else {
      $current = File::Spec->rootdir() ;
    }
    if ( ! -d "$current" ) {
      if ( ! mkdir( "$current", 0777 ) ) {
	return 0 ;
      }
    }
  }
  return 1 ;
}

=pod

=item * isemptyhash()

Replies if the specified hashtable was empty.
Takes 1 arg:

=over

=item * hash (hash ref)

is the hash table.

=back

=cut
sub isemptyhash($) {
  if ( ! $_[0] ) {
    return (1==1) ;
  }
  else {
    my @k = keys %{$_[0]} ;
    return ($#k < 0) ;
  }
}

=pod

=item * isemptyarray()

Replies if the specified array was empty.
Takes 1 arg:

=over

=item * array (array ref)

is the array.

=back

=cut
sub isemptyarray($) {
  if ( ! $_[0] ) {
    return (1==1) ;
  }
  else {
    return ($#{$_[0]} < 0) ;
  }
}

=pod

=item * hashcount()

Replies the count of keys inside the specified hash.
Takes 1 arg:

=over

=item * hash (hash ref)

is the hash table.

=back

=cut
sub hashcount($) {
  if ( ! $_[0] ) {
    return 0 ;
  }
  else {
    my @k = keys %{$_[0]} ;
    return (0 + @k) ;
  }
}

=pod

=item * ishash()

Replies if the specified struct is an hash.
Takes 1 arg:

=over

=item * object

is the object to test.

=back

=cut
sub ishash {
  return 0 unless defined($_[0]) ;
  my $r = ref( $_[0] ) ;
  return ( $r eq "HASH" ) ;
}

=pod

=item * issub()

Replies if the specified parameter is a sub name.
Takes 1 arg:

=over

=item * name (string)

is the name of a sub

=back

=cut
sub issub($) {
  return 0 unless defined($_[0]) ;
  return defined( &{$_[0]} ) ;
}

=pod

=item * isarray()

Replies if the specified struct is an array.
Takes 1 arg:

=over

=item * object

is the object to test.

=back

=cut
sub isarray {
  return 0 unless defined($_[0]) ;
  my $r = ref( $_[0] ) ;
  return ( $r eq "ARRAY" ) ;
}

=pod

=item * add_value_entry()

Adds an entry to the specified hashtable. if the
the value is not defined, adds as a scalar, else
adds as a array entry.
Takes 3 args:

=over

=item * hash (hash ref)

is the hashtable.

=item * key (string)

is the key in which the value must be put.

=item * value

is the value.

=back

=cut
sub add_value_entry($$$) {
  if ( ( $_[0] ) && ( $_[1] ) &&
       ( $_[2] ) ) {
    if ( exists $_[0]{$_[1]} ) {
      my $old = $_[0]{$_[1]} ;
      my $r = ref( $old ) ;
      if ( ! ( $r eq "ARRAY" ) ) {
	delete $_[0]{$_[1]} ;
	push( @{$_[0]{$_[1]}}, $old ) ;
      }
      push( @{$_[0]{$_[1]}}, $_[2] ) ;
    }
    else {
      $_[0]{$_[1]} = $_[2] ;
    }
  }
}

=pod

=item * force_add_value_entry()

Adds an entry to the specified hashtable. if the
the value is not defined, adds as a scalar, else
adds as a array entry.
Takes 3 args:

=over

=item * hash (hash ref)

is the hashtable.

=item * key (string)

is the key in which the value must be put.

=item * value

is the value.

=back

=cut
sub force_add_value_entry($$$) {
  if ( ( $_[0] ) && ( $_[1] ) ) {
    my $value = $_[2] || '' ;
    if ( exists $_[0]{$_[1]} ) {
      my $old = $_[0]{$_[1]} ;
      my $r = ref( $old ) ;
      if ( ! ( $r eq "ARRAY" ) ) {
	delete $_[0]{$_[1]} ;
	push( @{$_[0]{$_[1]}}, $old ) ;
      }
      push( @{$_[0]{$_[1]}}, $value ) ;
    }
    else {
      $_[0]{$_[1]} = $value ;
    }
  }
}

=pod

=item * buildtree()

Updates the specified hashtable by
adding the value at the specified keys.
Takes 2 args:

=over

=item * hash (hash ref)

is the tree.

=item * keys (array ref)

is the array of the keys.

=item * name (string)

is the classname.

=back

=cut
sub buildtree($$$) {
  return unless ( (isarray($_[1])) && $_[2] ) ;
  my $ref = $_[0] || '' ;
  foreach my $key (@{$_[1]}) {
    if ( ! ( exists $$ref{$key} ) ) {
      my %hash = () ;
      $$ref{$key} = \%hash ;
    }
    $ref = $$ref{$key} ;
  }
  if ( ! ( exists $$ref{$_[2]} ) ) {
    $$ref{$_[2]} = { } ;
  }
}

=pod

=item * removefctbraces()

Replies a string without "()" at the end.
Takes 1 arg:

=over

=item * str (string)

is a string.

=back

=cut
sub removefctbraces($) {
  my $name = $_[0] || '' ;
  if ( $name ) {
    $name =~ s/\s*\(\s*\)\s*$// ;
  }
  return $name ;
}

=pod

=item * addfctbraces()

Replies a string with "()" at the end.
Takes 1 arg:

=over

=item * str (string)

is a string.

=back

=cut
sub addfctbraces($) {
  my $name = removefctbraces( $_[0] ) ;
  return $name."()" ;
}

=pod

=item * extract_file_from_location()

Replies the file from the specified location.
Takes 1 arg:

=over

=item * location (string)

is the location inside the input stream.

=back

=cut
sub extract_file_from_location($) {
  return '' unless $_[0] ;
  my $loc = $_[0] ;
  my $file = "" ;
  $loc =~ s/^(.*):[0-9]*/$file=$1;/e ;
  return $file ;
}

=pod

=item * extract_line_from_location()

Replies the line number from the specified location.
Takes 1 arg:

=over

=item * location (string)

is the location inside the input stream.

=back

=cut
sub extract_line_from_location($) {
  return 0 unless $_[0] ;
  my $loc = $_[0] ;
  my $line = 0 ;
  $loc =~ s/^.*:([0-9]*)/$line=$1;/e ;
  if ( $line > 0 ) {
    return $line ;
  }
  else {
    return 0 ;
  }
}

#------------------------------------------------------
#
# Formating of the name of the tokens
#
#------------------------------------------------------

=pod

=item * formathashkeyname()

Replies a formatted hash key name.
Takes 1 arg:

=over

=item * name (string)

is the string to format.

=back

=cut
sub formathashkeyname($) {
  return lc( $_[0] || '' ) ;
}

=pod

=item * formatfctkeyname()

Replies a formatted hash key name for functions.
Takes 1 arg:

=over

=item * name (string)

is the string to format.

=back

=cut
sub formatfctkeyname($) {
  return addfctbraces( formathashkeyname( $_[0] || '' ) ) ;
}

=pod

=item * is_valid_regex()

Replies if the specified regular expression
was well-formed.
Takes 1 arg:

=over

=item * regex (string)

is the regular expression to verify.

=back

=cut
sub is_valid_regex($) {
  return 0 unless $_[0] ;
  return eval { "" =~ /$_[0]/; 1; } || 0 ;
}

=pod

=item * tohumanreadable()

Replies a string string that corresponds to
the human readable form of the specified string.
Takes 1 arg:

=over

=item * string (string)

is the string to convert.

=back

=cut
sub tohumanreadable($) {
  my $string = $_[0] || '' ;
  $string =~ s/\n/\\n/g;
  $string =~ s/\r/\\r/g;
  $string =~ s/\t/\\t/g;
  $string =~ s/\"/\\\"/g;
  $string =~ s/\'/\\\'/g;
  return $string ;
}

=pod

=item * readfileastext()

Replies the content of a file as a string
Takes 1 arg:

=over

=item * filename (string)

is the name of the file to read

=back

=cut
sub readfileastext($) {
  my $string = "" ;
  return $string unless $_[0] ;
  open( READFILE_FID, "< $_[0]" )
    or Bib2HTML::General::Error::syserr( "unable to open $_[0]: $!" ) ;
  while ( my $line = <READFILE_FID> ) {
    $string .= $line ;
  }
  close( READFILE_FID )
    or Bib2HTML::General::Error::syserr( "unable to close $_[0]: $!" ) ;
  return $string ;
}

=pod

=item * isnumber()

Replies if the parameter is a arabic or a roman number
Takes 1 arg:

=over

=item * text (string)

is the text to scan

=back

=cut
sub isnumber($) {
  return ( ( $_[0] ) &&
	   ( ( $_[0] =~ /^\s*[0-9]+\s*$/ ) ||
	     ( romantoarabic($_[0]) >= 0 ) ) ) ;
}

=pod

=item * tonumber()

Replies the integer value that correspond to the
specified number. Replies undef if something wrong
appends.
Takes 1 arg:

=over

=item * number (string)

is the text to translate

=back

=cut
sub tonumber($) {
  my $number = undef ;
  if ( isnumber($_[0]) ) {
    if ( $_[0] =~ /^\s*[0-9]+\s*$/ ) {
      $number = $_[0] ;
      $number =~ s/^\s+//m ;
      $number =~ s/\s+$//m ;
    }
    else {
      my $n = romantoarabic($_[0]) ;
      if ( $n > 0 ) {
	$number = $n ;
      }
    }
  }
  return $number ;
}

=pod

=item * arabictoroman()

Replies the roman number that correspond to the
specified arabic number
Takes 1 arg:

=over

=item * arabic (integer)

is the number to convert

=back

=cut
sub arabictoroman($) {
  my $nb = $_[0] || 0 ;
  my @CENT_TRANS_TBL = ( '', 'C', 'CC', 'CCC', 'CD', 'D', 'DC', 'DCC', 'DCCC', 'CM' ) ;
  my @DEC_TRANS_TBL = ( '', 'X', 'XX', 'XXX', 'XL', 'L', 'LX', 'LXX', 'LXXX', 'XC' ) ;
  my @UNIT_TRANS_TBL = ( '', 'I', 'II', 'III', 'IV', 'V', 'VI', 'VII', 'VIII', 'IX' ) ;
  my $roman = "" ;
  my $mille = int($nb / 1000) ;
  my $cent = int(($nb % 1000) / 100) ;
  my $dec = int(($nb % 100) / 10) ;
  my $unit = $nb % 10 ;

  while( $mille > 0 ) {
    $roman .= "M" ;
    $mille -- ;
  }
  $roman .= $CENT_TRANS_TBL[$cent] ;
  $roman .= $DEC_TRANS_TBL[$dec] ;
  $roman .= $UNIT_TRANS_TBL[$unit] ;
  return $roman ;
}

=pod

=item * romantoarabic()

Replies the arabic number that correspond to the
specified roman number
Takes 1 arg:

=over

=item * roman (integer)

is the number to convert

=back

=cut
sub romantoarabic($) {
  my $nb = $_[0] || '' ;
  my @CENT_TRANS_TBL = ( '', 'C', 'CC', 'CCC', 'CD', 'D', 'DC', 'DCC', 'DCCC', 'CM' ) ;
  my @DEC_TRANS_TBL = ( '', 'X', 'XX', 'XXX', 'XL', 'L', 'LX', 'LXX', 'LXXX', 'XC' ) ;
  my @UNIT_TRANS_TBL = ( '', 'I', 'II', 'III', 'IV', 'V', 'VI', 'VII', 'VIII', 'IX' ) ;

  my $roman = uc($nb) ;
  my $arabic = 0 ;

  if ( $roman =~ /^(M*)(.*)$/ ) {
    $roman = $2 ;
    $arabic = 1000 * length($1) ;
    if ( ___romantoarabic($arabic,$roman,100,\@CENT_TRANS_TBL) ) {
      if ( ___romantoarabic($arabic,$roman,10,\@DEC_TRANS_TBL) ) {
	if ( ___romantoarabic($arabic,$roman,1,\@UNIT_TRANS_TBL) ) {
	  return $arabic ;
	}
      }
    }
  }
  return -1 ;
}

sub ___romantoarabic($$$$) {
  my ($max,$index,$after) = ('',-1,$_[1]) ;
  for(my $i=1; $i<=$#{$_[3]};$i++) {
    if ( $_[1] =~ /^($_[3][$i])(.*)$/ ) {
      my ($nb,$reste) = ($1,$2) ;
      if ( length($nb) > length($max) ) {
	$max = $nb ;
	$index = $i ;
	$after = $reste ;
      }
    }
  }
  if ( $index > 0 ) {
    $_[1] = $after ;
    $_[0] += $_[2] * $index ;
    return 1 ;
  }
  else {
    return 0 ;
  }
}

=pod

=item * extract_first_words()

Replies the first words of the specified string.
Takes 2 args:

=over

=item * text (string)

is the text from which the words must be extracted

=item * len (integer)

is the maximal length of the result

=back

=cut
sub extract_first_words($$) {
  my $index = $_[1] || 0 ;
  my @words = split(/\s+/, ($_[0] || '')) ;
  return '' unless @words ;
  my ($result,$i) = ('',0) ;

  while ( ( $i <= $#words ) && ( (length($result)+length($words[$i])) <= $index )) {
    $result .= " " if ( $result ) ;
    $result .= $words[$i] ;
    $i ++ ;
  }

  if ( $i == 0 ) {
    $result = substr($words[0],0,$index-3) ;
  }
  elsif ( $i < int(@words) ) {
    if ( length($result) > $index ) {
      $result = substr($result,0,$index-3) ;
    }
    $result .= "..." ;
  }

  return $result ;
}

=pod

=item * addslahes()

Replies a string in which the " are protected
Takes 1 args:

=over

=item * text (string)

is the text to translate

=back

=cut
sub addslashes($) {
  my $text = $_[0] || '' ;
  $text =~ s/\\/\\\\/g ;
  $text =~ s/"/\\"/g ;
  return $text ;
}

=pod

=item * removeslahes()

Replies a string in which the " are unprotected
Takes 1 args:

=over

=item * text (string)

is the text to translate

=back

=cut
sub removeslashes($) {
  my $text = $_[0] || '' ;
  $text =~ s/\\(.)/$1/g ;
  return $text ;
}

=pod

=item * remove_strings()

Takes 2 args:

=over

=item * array (ref)

=item * text (string)

is the text to translate

=back

=cut
sub remove_strings($$) {
  my $delims= "\\\"|\\'" ;
  my $count = int(@{$_[0]}) ;
  while ( $_[1] =~ /($delims)/ ) {
    my $delim = $1 ;
    $_[1] =~ s/$delim((\\$delim|[^$delim])*)$delim/$_[0]->[$count++]="$1";"<<STRING".$count.">>"/ge;
  }
}

=pod

=item * restore_strings()

Takes 2 args:

=over

=item * array (ref)

=item * text (string)

is the text to translate

=back

=cut
sub restore_strings($$) {
  $_[1] =~ s/<<STRING([0-9]+)>>/$_[0]->[$1-1]/eg ;
}

=pod

=item * integer2alphabetic()

Replies the string representation of the specified integer.
Takes 1 arg.

=cut
sub integer2alphabetic($) {
  my $value = $_[0] || 0 ;
  my $q = chr( ord('a') + ( $value % 26 ) ) ;
  while ( $value >= 26 ) {
    $value = ($value/26)-1 ;
    $q = chr( ord('a') + ( ($value % 26) % 26 ) ) . $q ;
  }
  return $q ;
}

=pod

=item * array_slice()

Slices an array content and insert the specified string
Takes 3 args:

=over

=item * array (ref)

=item * location (integer)

is the index where insert the string

=item * str (string)

is the string to insert

=back

=cut
sub array_slice($$$) {
  return unless ( (isarray($_[0])) && ($_[1]>=0) ) ;
  my $i=$#{$_[0]} ;
  while ( $i >= $_[1] ) {
    $_[0]->[$i+1] = $_[0]->[$i] ;
    $i -- ;
  }
  $_[0]->[$_[1]] = $_[2] ;
}

=pod

=item * filecopy()

Copy a file
Takes 2 args:

=over

=item * source (string)

=item * target (string)

=back

=cut
sub filecopy($$) {
#   if ( ! "$_[0]" ) {
#     $! = 2 ;
#     return 0 ;
#   }
#   if ( ! "$_[1]" ) {
#     $! = 2 ;
#     return 0 ;
#   }
#   if ( ! -f "$_[0]" ) {
#     $! = 2 ;
#     return 0 ;
#   }
#   local (*SOURCE,*TARGET) ;
#   open( *SOURCE, "< $_[0]" )
#     or return 0 ;
#   if ( ! open( *TARGET, "> $_[1]" ) ) {
#     my $msg = $! ;
#     close( *SOURCE ) ;
#     $! = $msg ;
#     return 0 ;
#   }
#   my ($tampon,$q,$w) ;
#   $q = sysread( *SOURCE, $tampon, 4096 ) ;
#   if ( ! defined( $q ) ) {
#     my $msg = $! ;
#     close( *TARGET ) ;
#     close( *SOURCE ) ;
#     unlink( $_[1] ) ;
#     $! = $msg ;
#     return 0 ;
#   }
#   while ( $q > 0 ) {
#     $w = syswrite( *TARGET, $tampon, $q ) ;
#     if ( ! defined( $w ) ) {
#       my $msg = $! ;
#       close( *TARGET ) ;
#       close( *SOURCE ) ;
#       unlink( $_[1] ) ;
#       $! = $msg ;
#       return 0 ;
#     }
#     $q = sysread( *SOURCE, $tampon, 4096 ) ;
#     if ( ! defined( $q ) ) {
#       my $msg = $! ;
#       close( *TARGET ) ;
#       close( *SOURCE ) ;
#       unlink( $_[1] ) ;
#       $! = $msg ;
#       return 0 ;
#     }
#   }
#   close( *TARGET ) ;
#   close( *SOURCE ) ;
#   return 1 ;

  return copy("$_[0]","$_[1]") ;

}

=pod

=item * ucwords()

Upper case the first letter of each word.
Takes 1 arg:

=over

=item * text (string)

=back

=cut
sub ucwords($) {
  my $text = $_[0] || '' ;
  $text =~ s/^([^\s\-_])/\u$1/g ;
  $text =~ s/(?<=[\s\-_])([^\s\-_]+)/\u$1/g ;
  return $text ;
}


=pod

=item * uniq()

Eliminates redundant values from sorted list of values input.
Takes 1 arg:

=over

=item * items (list)

The sorted list to be made uniq

=back

=cut
sub uniq {
  # Function added the 2003/03/17 by a patch from Norbert Preining
  #
  # Eliminates redundant values from sorted list of values input.
  my $prev = undef;
  my @out=();
  foreach my $val (@_){
    next if $prev && ($prev eq $val);
    $prev = $val;
    push(@out, $val);
  }
  return @out;
}

=pod

=item * trim()

Eliminates trailing spaces for each parameter.

=cut
sub trim {
  foreach my $val (@_){
    $val =~ s/^\s+// ;
    $val =~ s/\s+$// ;
  }
}

=pod

=item * __matchlen()

Returns the length of matching
substrings at beginning of $a and $b.
Takes 2 args:

=over

=item * str1 (string)

=item * str2 (string)

=back

=cut
sub __matchlen($$) {
  my $c=0;
  my $alen = length($_[0]);
  my $blen = length($_[1]);
  my $d = ($alen<$blen)?$alen:$blen;
  while( (substr($_[0],$c,1) eq substr($_[1],$c,1))&&
	 ($c<$d) ) {
    $c++;
  }
  return $c;
}

=pod

=item * levenshtein_ops()

Computes the levenshtein distance between two strings.
A levenshtein distance corresponds to the adds, removes
required to transform a string to obtain another one.
Replies the actions to perform.
Takes 2 args:

=over

=item * str1 (string)

=item * str2 (string)

=back

=cut
sub levenshtein_ops($$) {
  my $alen = length($_[0]);
  my $blen = length($_[1]);
  my $aptr = 0;
  my $bptr = 0;
  my $stop = 0 ;

  my @ops = ();

  while((!$stop)&&($aptr<$alen)&&($bptr<$blen)) {
    # Search for similar text at the start
    my $matchlen = __matchlen(substr($_[0], $aptr), substr($_[1], $bptr));
    if($matchlen>0) {
      #
      # Similar text found
      #
      push @ops, { '=' => substr($_[0], $aptr, $matchlen) };
      $aptr += $matchlen;
      $bptr += $matchlen;
    }
    else {
      #
      # Difference found
      #
      # search for the best next similar text
      my $bestlen=0;
      my @bestpos=(0,0);
      my $bestfound = 0 ;
      for(my $atmp=$aptr; (!$bestfound)&&($atmp<$alen); $atmp++) {
	for(my $btmp=$bptr; $btmp<$blen; $btmp++) {
	  my $matchlen = __matchlen(substr($_[0], $atmp),
				    substr($_[1], $btmp));
	  if($matchlen>$bestlen) {
	    $bestlen = $matchlen;
	    @bestpos = ($atmp,$btmp);
	  }
	  $bestfound = ($matchlen>=$blen-$btmp) ;
	}
      }
      if ($bestlen>0) {

	my $adifflen = $bestpos[0] - $aptr;
	my $bdifflen = $bestpos[1] - $bptr;

	if($adifflen>0) {
	  push @ops, { '-' => substr($_[0], $aptr, $adifflen) };
	  $aptr += $adifflen;
	}
	if($bdifflen) {
	  push @ops, { '+' => substr($_[1], $bptr, $bdifflen) };
	  $bptr += $bdifflen;
	}
	push @ops, { '=' => substr($_[0], $aptr, $bestlen) };
	$aptr += $bestlen;
	$bptr += $bestlen;
      }
      else {
	$stop = 1 ;
      }
    }
  }
  if($aptr<$alen) {
    # b has too much stuff
    push @ops, { '-' => substr($_[0], $aptr) };
  }
  if($bptr<$blen) {
    # a has too little stuff
    push @ops, { '+' => substr($_[1], $bptr) };
  }
  return @ops;
}

=pod

=item * levenshtein()

Computes the levenshtein distance between two strings.
A levenshtein distance corresponds to the adds, removes
required to transform a string to obtain another one.
Replies the percent of similarity of the strings.
Takes 2 args:

=over

=item * str1 (string)

=item * str2 (string)

=back

=cut
sub levenshtein($$) {
  my @ops = &levenshtein_ops($_[0],$_[1]) ;
  my $alen = length($_[0]);
  my $blen = length($_[1]);
  my $max = ($alen>$blen)?$alen:$blen ;
  if ($max<=0) {
    return 0 ;
  }
  my $count = 0 ;
  foreach my $op (@ops) {
    if ($op->{'='}) {
      $count = $count + length($op->{'='}) ;
    }
  }
  return ($count*100)/$max ;
}

=pod

=item * shell_to_regex()

Translate a string that contains shell's wildcards to
its equivalent expressed with regular expressions.
Takes 1 arg:

=over

=item * shell_string (string)

=back

=cut
sub shell_to_regex($) {
  my $shell_string = shift;
  my $regex_string = '';
  while ($shell_string =~ /^(.*?)([*?\[])(.*)$/) {
    my ($prev,$sep,$after) = ($1,$2,$3);
    if ($prev) {
      $prev =~ s/\./\\./g;
      $prev =~ s/\+/\\+/g;
      $prev =~ s/\(/\\(/g;
      $prev =~ s/\)/\\)/g;
      $prev =~ s/\^/\\^/g;
      $prev =~ s/\\/\\\\/g;
      $prev =~ s/\$/\\\$/g;
      $prev =~ s/\|/\\|/g;
      $regex_string .= $prev;
    }
    if ($sep eq '*') {
      $regex_string .= '.*';
    }
    elsif ($sep eq '?') {
      $regex_string .= '.';
    }
    elsif ($sep eq '[') {
      if ($after =~ /^([^\]]+)\](.*)$/) {
        $after = $2;
        $regex_string .= "[$1]";
      }
      else {
        $regex_string .= '[';
      }
    }
    $shell_string = $after;
  }
  if ($shell_string) {
    $shell_string =~ s/\./\\./g;
    $shell_string =~ s/\+/\\+/g;
    $shell_string =~ s/\(/\\(/g;
    $shell_string =~ s/\)/\\)/g;
    $shell_string =~ s/\^/\\^/g;
    $shell_string =~ s/\\/\\\\/g;
    $shell_string =~ s/\$/\\\$/g;
    $shell_string =~ s/\|/\\|/g;
    $regex_string .= $shell_string;
  }
  return '^'.$regex_string.'$';
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
