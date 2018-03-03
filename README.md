# MUSIC LIBRARY

## What is it?

A command line interface to interact with your music library.

## Installation

This program assumes a directory structure where your music library is in
```
LIBDIR="${HOME}/share/music/.library"
```
and there exists a text file in
```
LIBFILE="${LIBDIR}/library.txt"
```
that contains the name of your songs in the format
```
<artist> - <song name>.mp3
```

## Uninstall

To uninstall the music library, simply remove your library directory:
```
$ rm -rv "${LIBDIR}"
```
where the location of *LIBDIR* is specified above. If you have changed that
path, then enter the changed path instead.
