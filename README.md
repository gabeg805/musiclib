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

See [Directory and File Structure](#directory-and-file-structure) for more
information on the *library.txt* file.

## Uninstall

To uninstall the Music Library, run:

```
musiclib --uninstall
```

## Directory and File Structure

When running [Install](#install), the user is prompted as to where the Playlist
and Library directories are located.

Within the Library directory, there should be a file called *library.txt* which
contains a list of songs that should be in the library.

The songs have a specific naming format of:

```
<artist> - <song name>
```

So each line in the *library.txt* file should coincide with this. When running
[Sync](#sync), the files are saved with a *.mp3* extension.