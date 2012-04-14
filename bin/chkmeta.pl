#!/usr/bin/perl -- # -*- Perl -*-

use strict;
use English;
use Cwd 'abs_path';
use Getopt::Std;
use vars qw($opt_c $opt_u);
use Digest::SHA qw(sha1_hex);
use Image::ExifTool;

my $usage = "$0 imageDir\n";

die $usage if ! getopts('');

my $file = shift @ARGV || die $usage;
$file = abs_path($file);
die $usage unless $file =~ /^\//;

my $BASE = abs_path($0);
$BASE =~ s/\/bin\/.*$//;
$BASE .= "/photos";

my $tmp = "/tmp/photoman-upload.$$.xml";
chkmeta($file);
unlink $tmp;

sub chkmeta {
    my $file = shift;
    chop $file if $file =~ /\/$/;
    if (-d $file) {
        my @files = ();
        opendir (DIR, $file);
        while (my $name = readdir(DIR)) {
            next if $name =~ /^\.\.?$/;
            my $path = $file . "/" . $name;
            next if -d $path && ($name eq '64' || $name eq '150' || $name eq '500');
            push (@files, $path);
        }
        closedir (DIR);
        foreach my $file (@files) {
            chkmeta($file);
        }
    } else {
        my $baseuri = substr($file, length($BASE)+1);
        $baseuri =~ s/\.[^\.]+$//;

        my $exif = new Image::ExifTool;
        $exif->Options(IgnoreMinorErrors => '1');
        $exif->ExtractInfo($file);

        my @subj = $exif->GetValue('Subject');

        warn "$file: no title\n" unless $exif->GetValue('Title') ne '';
        warn "$file: no tags\n" unless $#subj >= 0;
        warn "$file: no country\n" unless $exif->GetValue('Country') ne '';
        if ($exif->GetValue('City') eq '' && $exif->GetValue('State') eq '') {
            warn "$file: no city/state\n";
        }
    }
}
