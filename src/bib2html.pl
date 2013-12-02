#!/usr/bin/perl -w

# bib2html script to generate an HTML document for BibTeX database
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

use strict ;
use File::Basename ;
use File::Spec ;

#------------------------------------------------------
#
# Initialization code
#
#------------------------------------------------------
my $PERLSCRIPTDIR ;
my $PERLSCRIPTNAME ;
BEGIN{
  # Where is this script?
  $PERLSCRIPTDIR = "$0";
  my $scriptdir = dirname( $PERLSCRIPTDIR );
  while ( -e $PERLSCRIPTDIR && -l $PERLSCRIPTDIR ) {
    $PERLSCRIPTDIR = readlink($PERLSCRIPTDIR);
    if ( substr( $PERLSCRIPTDIR, 0, 1 ) eq '.' ) {
      $PERLSCRIPTDIR = File::Spec->catfile( $scriptdir, "$PERLSCRIPTDIR" ) ;
    }
    $scriptdir = dirname( $PERLSCRIPTDIR );
  }
  $PERLSCRIPTNAME = basename( $PERLSCRIPTDIR ) ;
  $PERLSCRIPTDIR = dirname( $PERLSCRIPTDIR ) ;
  $PERLSCRIPTDIR = File::Spec->rel2abs( "$PERLSCRIPTDIR" );
  # Push the path where the script is to retreive the arakhne.org packages
  push(@INC,"$PERLSCRIPTDIR");

}

use Bib2HTML::Main;

launchBib2HTML("$PERLSCRIPTDIR","$PERLSCRIPTNAME");

__END__
