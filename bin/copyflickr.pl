#!/usr/bin/perl -- # -*- Perl -*-

use strict;
use English;
use Image::ExifTool;

my $usage = "$0 metadata\n";
my $FLOCL = "/Volumes/PortableData/Aux/flocl/flickr";

my $file = shift @ARGV || die $usage;

open (F, $file) || die $usage;

my $file = undef;
my $copy = undef;
my $title = undef;
my %tags = ();
my $exif = new Image::ExifTool;
$exif->Options(IgnoreMinorErrors => '1');

while (<F>) {
    chop;

    if (/^$/) {
        tag($copy, %tags);
        $file = undef;
        $copy = undef;
        $title = undef;
        %tags = ();
        $exif = new Image::ExifTool;
        $exif->Options(IgnoreMinorErrors => '1');
        next;
    }

    if (!defined($file)) {
        $file = $_;
    } elsif (!defined($copy)) {
        $copy = $_;

        if ($copy =~ /\//) {
            my $path = $copy;
            $path =~ s/^(.*)\/[^\/]+$/$1/;
            if (! -d $path) {
                system("mkdir -p $path");
            }
            if (! -d $path) {
                die "Failed to create $path.\n";
            }
        }

        if (-f "$copy") {
            print "Skipping copy: $copy\n";
        } else {
            print "Copying: $copy\n";
            if ($file =~ /\.jpe?g$/) {
                system("cp $FLOCL/$file $copy");
            } else {
                system("convert $FLOCL/$file $copy");
            }
        }

        $exif->ExtractInfo($copy);
    } elsif (!defined($title)) {
        $title = $_;
        $title =~ s/\"/\\\"/g;
        $exif->SetNewValue('Comment', "");
        $exif->SetNewValue('Title', $title);
        update($exif);
    } else {
        my $tag = $_;
        $tag =~ s/\"/\\\"/g;
        $tags{$tag} = 1;
    }
}
close (F);

tag($copy, %tags);

################################################################################

sub tag {
    my $copy = shift;
    my %tags = @_;

    my $lat = undef;
    my $lng = undef;
    my $alt = undef;

    my @del = ();
    foreach $_ (keys %tags) {
        $alt = $1 if /^geo:alt=(.+)$/;
        $lat = $1 if /^geo:lat=(.+)$/;
        $lng = $1 if /^geo:long=(.+)$/;
        push (@del, $_) if /^geo:/ || ($_ eq 'geotagged') || ($_ eq 'm');
    }

    foreach my $tag (@del) {
        delete $tags{$tag};
    }

    my $ns = $lat < 0.0 ? "S" : "N";
    my $ew = $lng < 0.0 ? "W" : "E";

    $exif->SetNewValue('GPSLatitude', $lat) if defined($lat);
    $exif->SetNewValue('GPSLatitudeRef', $ns) if defined($lat);
    $exif->SetNewValue('GPSLongitude', $lng) if defined($lng);
    $exif->SetNewValue('GPSLongitudeRef', $ew) if defined($lng);
    $exif->SetNewValue('GPSAltitude', $alt) if defined($alt);

    my @tags := keys %tags;

    if (@tags) {
        $exif->SetNewValue('Subject', \@tags);
        $exif->SetNewValue('Keywords', \@tags);
    } else {
        $exif->SetNewValue('Subject');
        $exif->SetNewValue('Keywords');
    }

    update($exif);
}

sub update {
    my $exif = shift;

    return if ! -f $copy;

    my $rc = $exif->WriteInfo($copy);
    if ($rc == 0) {
        my $errorMessage = $exif->GetValue('Error');
        my $warningMessage = $exif->GetValue('Warning');
        print STDERR "$copy: $errorMessage\n";
        print STDERR "\t$warningMessage\n";
        print STDERR "\tRemoving $copy\n";
        unlink $copy;
    }
}
