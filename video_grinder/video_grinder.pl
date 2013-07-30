#!/usr/bin/perl -w

use strict;
use warnings;

sub parse_time {
  my $str = shift;

  if ($str =~ /(-)?(?:(?:(\d+):)?(\d+):)?(\d+(?:\.\d+)?)/) {
    my $t = $4;
    $t +=   60*$3 if (defined $3);
    $t += 3600*$2 if (defined $2);
    $t = -$t      if (defined $1);
    return $t;
  } else {
    die "Line $.: couldn’t parse time string “$str”.\n";
  }
}

sub human_time {
  my $t = shift;
  my $human = '';
  if ($t < 0) {
    $human .= '-';
    $t = -$t;
  }
  my $m = int($t/60);
  my $s = int($t)%60;
  my $ms = int($t*100%100);
  $human .= sprintf("%02dm%02d", $m, $s);
  $human .= sprintf(".%d", $ms) if ($ms > 0);
  return $human;
}

sub find_file {
  my ($file, $search_dir) = @_;
  opendir(my $dh, $search_dir) || warn "Couldn't open directory $search_dir: $!\n";
  while(readdir $dh) {
    next if($_ eq '.' || $_ eq '..');
    my $probe = "$search_dir/$_";
    my $res;
    if (-d "$probe") {
      $res = find_file($file, $probe);
    } elsif ($_ eq $file) {
      $res = $probe;
    }
    return $res if defined($res);
  }
  closedir $dh;
  return undef;
}

sub read_timestamps {
  my ($filename, $videos_dir) = @_;
  my @todo;
  my $n = 0;
  my $infile;

  open(TIMES, "<$filename") or die "Couldn't open $filename: $!\n";
  while (<TIMES>) {
    chomp;
    if (/^[^\t]+/) {
      $infile = $_;
      unless (-e $infile) {
        $infile = find_file($infile, $videos_dir);
        die "Couldn't find file \`$infile' in directory \`$videos_dir' nor any of its subdirectories\n" unless(defined($infile));
      }
      $n++;
    } else {
      my (undef, $from, $to) = split(/\t/);
      next unless (defined($from) && defined($to));
      push(@todo, { 'from' => $from, 'to' => $to, 'infile' => $infile, 'n' => $n });
    }
  }
  close(TIMES);
  return $n, @todo;
}

my $outfile_ext = 'mp3';
my $outfile_prefmt = '%%s_%%0%dd_%%s-%%s.'.$outfile_ext;

if (@ARGV < 3) {
  die "Usage: $0 timestamps.txt /path/to/input/videos/ /path/to/output/audios/ [ffmpeg extra opts]\n"
}

my $timestamps_file = shift(@ARGV);
my $videos_dir = shift(@ARGV);
$videos_dir =~ s/\/$//g;
my $working_dir = shift(@ARGV);
$working_dir =~ s/\/$//g;
my $ffmpeg_args = join(' ', @ARGV);
my ($audio_basename) = reverse(split(/\//, $working_dir));

opendir(WD, $working_dir) || die "Couldn't open directory $working_dir: $!\n";
my %existing_outfiles = map { $_ => undef } grep { $_ =~ /\.$outfile_ext$/ } readdir(WD);
closedir(WD);

my ($nfiles, @todo) = read_timestamps($timestamps_file, $videos_dir); 

my $outfile_fmt = sprintf($outfile_prefmt, length($nfiles));
foreach my $todo (@todo) {
  my $from = parse_time($todo->{from});
  my $to   = parse_time($todo->{to  });
  my $human_to = human_time($to);
  my $human_from = human_time($from);

  my $outfile = sprintf($outfile_fmt, $audio_basename, $todo->{'n'}, $human_from, $human_to);
  delete($existing_outfiles{$outfile});
  if (-e $working_dir.'/'.$outfile) {
    print "Skipping existing file $outfile.\n";
    next;
  }

  my $duration = $to - $from;

  my $cmd = ("ffmpeg -i '$todo->{infile}' -ss $from -t $duration '$working_dir/$outfile' $ffmpeg_args");
  system($cmd." </dev/null");
  if ($? == -1) {
    print "failed to execute ffmpeg: $!\n";
  }
  elsif ($? & 127) {
    printf "ffmpeg died with signal %d\n", ($? & 127);
  }
  else {
    my $exit_value = $? >> 8;
    if ($exit_value == 255) { # FFmpeg return value when it received a term/quit signal
      # It's likely that the user pressed ctrl-c or something
      # So stop ourself too
      exit;
    }
  }
}

foreach (keys(%existing_outfiles)) {
  print "Remove remaining file $_? ";
  unlink("$working_dir/$_") if (<STDIN> =~ /^y/);
}

