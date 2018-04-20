# Music Library

## Introduction

A command line interface to interact with your music library.

## Install

To install the Music Library, run:

```
musiclib --install
```

Note: This does not put this script in your *PATH*.

## Sync

To sync the Music Library with the your *library.txt* file, run:

```
musiclib --sync
```

Click [here](#directory-and-file-structure) for more information on the
*library.txt* file.

## Uninstall

To uninstall the Music Library, run:

```
musiclib --uninstall
```

## Directory and File Structure

The user is prompted as to where the Playlist and Library directories are
located.

Within the Library directory, there should be a file called *library.txt* which
contains a list of songs that should be in the library.  These songs must be
named in the following format:

```
<artist> - <song name>.mp3
```
