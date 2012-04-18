# Photo manager

This project is a photo management application built on top of
[MarkLogic Server 5](http://www.marklogic.com/product/marklogic-server.html).
(It uses external binaries, so porting to 4.x isn't practical.)
You can see it in operation at
[photos.nwalsh.com](http://photos.nwalsh.com/).

## Installation

1. Install MarkLogic Server 5 if you haven't already.
1. Download the project and put it with your other MarkLogic projects. I put
   it in `/MarkLogic/photoman`. If you put it elsewhere, make sure you update
   the paths accordingly.
2. I'm using the [Fico](http://fico.lensco.be) font for the "icons" in lists.
   You'll have to edit things a bit if you don't want to buy a license for
   Fico.
3. Make sure you've got [ExifTool](http://en.wikipedia.org/wiki/ExifTool) and
   the Perl `Image::ExifTool` libraries.
4. Make sure you've got [ImageMagick](http://en.wikipedia.org/wiki/ImageMagick)

## Setup

1. Login to the server as `admin` and run [QConsole](http://localhost:8000/qconsole/).
2. Open `setup/initialize.xqy` and paste it into a QConsole panel. Look at the
   variables at the top and assure yourself that you're comfortable with them.
   The initialize script:
   1. Creates a database named `$DATABASE-NAME` (photoman) with a single
      forest named `$FOREST-NAME` (photoman).
   2. Creates an appserver named `$APPSERVER-NAME` (photoman) on port
      `$APPSERVER-PORT` (7070). This will be the server for ordinary users.
   3. Creates an appserver named `$ADMIN-APPSERVER-NAME` (photoman-admin) on port
      `$ADMIN-APPSERVER-PORT` (7071). This will be the server for administration.
      *Do not allow public access to this server*
   4. Creates `$WEBLOG-READER` (weblog-reader) and `$WEBLOG-UPDATE` (weblog-update) privileges
   5. Creates `$WEBLOG-READER` and `$WEBLOG-EDITOR` (weblog-editor) roles.
   5. Creates a `$WEBLOG-READER` (weblog-reader) user.
3. Copy `setup/amped.xqy` to `nwalsh/photoman/amped.xqy` in the `Modules` directory
   of the server (often `/opt/MarkLogic/Modules`).
4. In the MarkLogic Server Admin UI, port 8001, in the `Security` section,
   create an "amp" named "update-views" with the namespace
   "http://nwalsh.com/ns/modules/photoman/amped" and the URI
   "/nwalsh/photoman/amped.xqy". Give it the `$WEBLOG-EDITOR` role.
5. Open `/MLS/admin/setup.xqy` and change the top-level variables as necessary.
   Run `/admin/setup.xqy` on your admin server (e.g., `http://localhost:7071/admin/setup.xqy`).

## Adding images

The process for adding images is a little clumsy. I elected to use
ExifTool for extracting metadata because it does a good job and
produces robust metadata. I decided to scale the images and store them
as external binaries because that seemed a good tradeoff of speed vs.
space. It's
[possible](http://blog.davidcassel.net/2012/01/sneak-peak-imagemagick-in-marklogic/)
to get the server to do the ImageMagick piece, but it means processing
horsepower over and over again.

1. Create the photos directory and decide how you're
   going to organize the images physically. I do it by date, so I create directories
   like `/MarkLogic/photoman/photos/2012/04/17` and put the images in there.
2. Copy an image (or images) into the photo directory or directories.
3. Run `bin/imgsize` on those directories. That'll create all the scaled images.
4. Run `bin/upload-photo` on those directories. Check the defaults in there first.
5. That should upload the first images. Now you should see the fruits of your
   efforts on port 7070 and 7071.

## WTF!?

Problem? Drop me a note or create an issue. I'll do what I can, when I can.

## Bounty

[My offer](https://twitter.com/#!/ndw/status/182284997493919744) still stands.


