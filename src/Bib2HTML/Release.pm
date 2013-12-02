# Copyright (C) 2002-09  Stephane Galland <galland@arakhne.org>
# Copyright (C) 2011  Stephane Galland <galland@arakhne.org>
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

package Bib2HTML::Release;
@ISA = ('Exporter');
@EXPORT = qw( &getVersionNumber &getVersionDate &getBugReportURL
	      &getAuthorName &getAuthorEmail &getMainURL 
	      &getContributors ) ;
@EXPORT_OK = qw();
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $VERSION);
my $VERSION = "6.7" ;

#------------------------------------------------------
#
# DEFINITIONS
#
#------------------------------------------------------

my $BIB2HTML_VERSION      = $VERSION ;
my $BIB2HTML_DATE         = '2011/07/31' ;
my $BIB2HTML_BUG_URL      = 'mailto:bugreport@arakhne.org' ;
my $BIB2HTML_AUTHOR       = 'Stephane GALLAND' ;
my $BIB2HTML_AUTHOR_EMAIL = 'galland@arakhne.org' ;
my $BIB2HTML_URL          = 'http://www.arakhne.org/bib2ml/' ;
my %BIB2HTML_CONTRIBS     = ( 'zinser@zinser.no-ip.info' => "Martin P.J. ZINSER",
			      'preining@logic.at' => "Norbert PREINING",
			      'sebastian.rodriguez@utbm.fr' => "Sebastian RODRIGUEZ",
			      'michail@mpi-sb.mpg.de' => "Dimitris MICHAIL",
			      'joao.lourenco@di.fct.unl.pt' => "Joao LOURENCO",
			      'paolini@di.unito.it' => "Luca PAOLINI",
			      'cri@linux.it' => "Cristian RIGAMONTI",
			      'loew@mathematik.tu-darmstadt.de' => "Tobias LOEW",
			      'loew@mathematik.tu-darmstadt.de' => "Tobias LOEW",
			      'gasper.jaklic@fmf.uni-lj.si' => "Gasper JAKLIC",
                              'olivier.hugues@gmail.com' => "Olivier HUGUES",
			    ) ;

#------------------------------------------------------
#
# Functions
#
#------------------------------------------------------

sub getVersionNumber() {
  return $BIB2HTML_VERSION ;
}

sub getVersionDate() {
  return $BIB2HTML_DATE ;
}

sub getBugReportURL() {
  return $BIB2HTML_BUG_URL ;
}

sub getAuthorName() {
  return $BIB2HTML_AUTHOR ;
}

sub getAuthorEmail() {
  return $BIB2HTML_AUTHOR_EMAIL ;
}

sub getMainURL() {
  return $BIB2HTML_URL ;
}

sub getContributors() {
  return %BIB2HTML_CONTRIBS ;
}

1;
__END__
