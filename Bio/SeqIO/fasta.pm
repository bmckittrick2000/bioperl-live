# $Id$
# BioPerl module for Bio::SeqIO::fasta
#
# Cared for by Ewan Birney <birney@ebi.ac.uk>
#          and Lincoln Stein <lstein@cshl.org>
#
# Copyright Ewan Birney & Lincoln Stein
#
# You may distribute this module under the same terms as perl itself
# _history
# October 18, 1999  Largely rewritten by Lincoln Stein

# POD documentation - main docs before the code

=head1 NAME

Bio::SeqIO::fasta - fasta sequence input/output stream

=head1 SYNOPSIS

Do not use this module directly.  Use it via the Bio::SeqIO class.

=head1 DESCRIPTION

This object can transform Bio::Seq objects to and from fasta flat
file databases.

=head1 FEEDBACK

=head2 Mailing Lists

User feedback is an integral part of the evolution of this and other
Bioperl modules. Send your comments and suggestions preferably to one
of the Bioperl mailing lists.  Your participation is much appreciated.

  bioperl-l@bioperl.org            - General discussion
  bioperl-guts-l@bioperl.org       - Technically-oriented discussion
  http://bioperl.org/MailList.shtml - About the mailing lists

=head2 Reporting Bugs

Report bugs to the Bioperl bug tracking system to help us keep track
 the bugs and their resolution.
 Bug reports can be submitted via email or the web:

  bioperl-bugs@bio.perl.org
  http://bio.perl.org/bioperl-bugs/

=head1 AUTHORS - Ewan Birney & Lincoln Stein

Email: birney@ebi.ac.uk
       lstein@cshl.org


=head1 APPENDIX

The rest of the documentation details each of the object
methods. Internal methods are usually preceded with a _

=cut

# Let the code begin...

package Bio::SeqIO::fasta;
use vars qw(@ISA);
use strict;
# Object preamble - inherits from Bio::Root::Object

use Bio::SeqIO;

@ISA = qw(Bio::SeqIO);

=head2 next_seq

 Title   : next_seq
 Usage   : $seq = $stream->next_seq()
 Function: returns the next sequence in the stream
 Returns : Bio::Seq object
 Args    : NONE

=cut

sub next_seq {
    return next_primary_seq( $_[0], 1 );
}

=head2 next_primary_seq

 Title   : next_seq
 Usage   : $seq = $stream->next_seq()
 Function: returns the next sequence in the stream
 Returns : Bio::PrimarySeq object
 Args    : NONE

=cut

sub next_primary_seq {
  my( $self, $as_next_seq ) = @_;
  local $/ = "\n>";

  return unless my $entry = $self->_readline;

  if ($entry eq '>')  {  # very first one
    return unless $entry = $self->_readline;
  }

  #  my $next_rec = $entry;
  #while($next_rec =~ /(^|.)>$/) {
      # HL 05/25/2000
      # a greater sign not preceded by a newline indicates that there is a
      # '>' within the description, so we need more to complete the record
      #return unless defined($next_rec = $self->_readline());
      #$entry .= $next_rec;
  #}

  my ($top,$sequence) = $entry =~ /^(.+?)\n([^>]+)/s
    or $self->throw("Can't parse entry");
  my ($id,$fulldesc) = $top =~ /^\s*(\S+)\s*(.*)/
    or $self->throw("Can't parse fasta header");
  $id =~ s/^>//;
  $sequence =~ s/\s//g; # Remove whitespace

  if ($as_next_seq) {
    # Return a Bio::Seq if asked for
    return Bio::Seq->new(-seq        => $sequence,
		         -id         => $id,
		         -primary_id => $id,
		         -desc       => $fulldesc,
		         );
  } else {
    return Bio::PrimarySeq->new(-seq        => $sequence,
		                -id         => $id,
		                -primary_id => $id,
		                -desc       => $fulldesc,
		                );
  }
}

=head2 write_seq

 Title   : write_seq
 Usage   : $stream->write_seq(@seq)
 Function: writes the $seq object into the stream
 Returns : 1 for success and 0 for error
 Args    : Bio::Seq object


=cut

sub write_seq {
   my ($self,@seq) = @_;
   foreach my $seq (@seq) {
     my $str = $seq->seq;
     my $top = $seq->id();
     if ($seq->can('desc') and my $desc = $seq->desc()) {
	 $desc =~ s/\n//g;
        $top .= " $desc";
     }
     $str =~ s/(.{1,60})/$1\n/g;
     $self->_print (">",$top,"\n",$str) or return;
   }
   return 1;
}

1;
