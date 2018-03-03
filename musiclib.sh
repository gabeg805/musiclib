#!/bin/bash
# ------------------------------------------------------------------------------
# 
# Name:    musiclib.sh
# Author:  Gabriel Gonzalez
# Email:   gabeg@bu.edu
# License: The MIT License (MIT)
# 
# Syntax: ./musiclib [options]
# 
# Description: A command line interface to interact with your music library.
# 
# Notes: None.
# 
# ------------------------------------------------------------------------------

# Globals
PROGRAM="${0##*/}"
PROGDIR=$(dirname "$(readlink -f "${0}")")
LIBDIR="${HOME}/share/music/.library"
LIBFILE="${LIBDIR}/library.txt"
YOUTUBE="https://www.youtube.com"
RESULTPAGE="result.html"

# Options
VERBOSE=
SYNC=
TEST=
IGNOREOFFICIAL=
PROMPTRESULTS=

# Source utility
. "${PROGDIR}/../lib/bash/util.sh"

# ------------------------------------------------------------------------------
# Main
main()
{
    # Setup options
    if [ $# -eq 0 ]; then
        usage
        exit 0
    fi
    short="hvSdflq:ipt"
    long="help,verbose,sync,download,find,list,query:,ignore-official,prompt-results,test"
    args=$(getopt -o "${short}" --long "${long}" --name "${PROGRAM}" -- "${@}")
    if [ $? -ne 0 ]; then
        usage
        exit 1
    fi
    eval set -- "${args}"

    # Define options
    local PARSED=
    local DOWNLOAD=
    local FIND=
    local LIST=
    local QUERY=()

    # Parse options
    while true; do
        case "${1}" in
            # Usage
            -h|--help)
                usage
                exit 0
                ;;

            # Verbose output
            -v|--verbose)
                VERBOSE=true
                ;;

            # Sync library to the library config file
            -S|--sync)
                SYNC=true
                ;;

            # Download the desired query
            -d|--download)
                DOWNLOAD=true
                ;;

            # Find the desired query in the library
            -f|--find)
                FIND=true
                ;;

            # List contents of library. If query is specified, list the matches
            -l|--list)
                LIST=true
                ;;

            # Query
            -q|--query)
                shift
                QUERY+=("${1}")
                ;;

            # Official flag
            -i,--ignore-official)
                IGNOREOFFICIAL=true;
                ;;

            # Prompt user when displays results
            -p|--prompt-results)
                shift
                PROMPTRESULTS=true
                ;;

            # Test flag
            --test)
                TEST=true
                ;;

            # End of options
            --)
                break
                ;;

            *)
                break
                ;;
        esac
        shift
        PARSED=true
    done

    # Run options
    if [ -z "${PARSED}" ]; then
        print_err "No options specified. See '--help' for more information."
        exit ${EARG}
    elif [ -n "${SYNC}" ]; then
        sync_music_library
    elif [ -n "${DOWNLOAD}" ]; then
        download_music "${QUERY[@]}"
    elif [ -n "${FIND}" ]; then
        find_music_in_library "${QUERY[@]}"
    elif [ -n "${LIST}" ]; then
        list_music_library "${QUERY[@]}"
    else
        exit ${EARG}
    fi
}

# ------------------------------------------------------------------------------
# Print program usage
usage()
{
    echo "Usage: ${PROGRAM} [options] [args]"
    echo
    echo "Options:"
    echo "    -h, --help"
    echo "        Print program usage."
    echo
    echo "    -v, --verbose"
    echo "        Verbose output."
    echo
    echo "    -S, --sync"
    echo "        Sync music library."
    echo
    echo "    -d, --download"
    echo "        Download music."
    echo
    echo "    -f, --find"
    echo "        Find music in library."
    echo
    echo "    -l, --list"
    echo "        List music in library. If used along with '-q' then query"
    echo "        is case sensitive."
    echo
    echo "    -q, --query <name>"
    echo "        Search query for '-d', '-f', and '-l'. For multiple queries,"
    echo "        use this option more than once."
    echo
    echo "    -i, --ignore-official"
    echo "        The default behavior is to append 'official' to the search"
    echo "        criteria to find official music audio. This flag ignores this"
    echo "        default behavior."
    echo
    echo "    -p, --prompt-results"
    echo "        Prompt the user to select a video whose audio will be"
    echo "        downloaded."
    echo
    echo "    --test"
    echo "        Test out a '--sync' but do not create or download any songs."
    echo
    echo "Arguments:"
    echo "    <name>"
    echo "        Name of song or artist to query. This is case insensitive"
    echo "        unless specified in an option above."
    echo
    echo "    <number>"
    echo "        Resut number to use [Default: 1]."
}

# ------------------------------------------------------------------------------
# Sync music library
sync_music_library()
{
    local line=

    while IFS= read -r line; do
        if [ ! -n "${line}" ]; then
            continue
        fi

        download_music "${line}"
    done < "${LIBFILE}"
}

# ------------------------------------------------------------------------------
# Download music
download_music()
{
    if [ -z "${1}" ]; then
        print_err "Unable to download music: No search query found."
        exit 1
    fi

    local queries=("${@}")
    local artist=
    local song=

    for q in "${queries[@]}"; do
        builtin cd "${LIBDIR}"

        artist="$(get_artist "${q}")"
        song="$(get_song "${q}")"

        # Check parameters and ensure file does not already exist
        if ! check_artist "${artist}" || ! check_song "${song}" \
                || ! check_music_file "${artist}" "${song}"
        then
            continue
        fi

        # Download music query
        youtube_download "${q}"

        if [ "${q}" != "${queries[-1]}" ] || [ -n "${SYNC}" ]; then
            echo
        fi
    done
}

# ------------------------------------------------------------------------------
# Find music in the library
find_music_in_library()
{
    if [ -z "${1}" ]; then
        print_err "Unable to find music: No search query ('-q') entered."
        exit 1
    fi

    builtin cd "${LIBDIR}"

    local queries=("${@}")
    local artist=
    local song=
    local q=
    local i=
    local f=
    local name=
    local IFS=$'\n'

    # Search library
    for q in "${queries[@]}"; do
        i=0

        # Display matches
        for f in $(find . -iname "*${q}*"); do
            name=$(basename "${f}")
            artist="$(get_artist "${name}")"
            song="$(get_song "${name}")"
            i=$[ ${i} + 1 ]

            echo "Artist : ${artist}"
            echo "Song   : ${song}"
            echo
        done

        # Unable to find a match
        if [ ${i} -eq 0 ]; then
            print_err "Unable to find a match for query '${q}'."
            continue
        fi
    done
}

# ------------------------------------------------------------------------------
# List music library
list_music_library()
{
    local queries=("${@}")
    local listall=false
    local song=
    local q=
    local d=
    local f=
    local IFS=$'\n'

    # Determine what to list: User input or all artists
    if [ -z "${queries}" ]; then
        queries=(*)
        listall=true
    fi

    # List library
    for q in "${queries[@]}"; do
        builtin cd "${LIBDIR}"

        # Check if artist dir and song file exist
        if [ ! -d "${q}" ]; then
            if ! ${listall} && [ ! -f "${q}" ]; then
                print_err "Unable to list '${q}'."
            fi
            continue
        fi

        # Display all songs from artist
        builtin cd "${q}"
        echo "${q}"

        for f in *; do
            song="$(get_song "${f}")"
            echo "    ${song}"
        done

        if [ "${q}" != "${queries[-1]}" ]; then
            echo
        fi
    done
}

# ------------------------------------------------------------------------------
# Download music
youtube_download()
{
    local query="${1}"
    local artist="$(get_artist "${query}")"
    local song="$(get_song "${query}")"

    echo "Downloading..."
    echo "Artist : ${artist}"
    echo "Song   : ${song}"

    if [ -n "${TEST}" ]; then
        return 0
    fi

    mkdir -pv "${artist}"
    builtin cd "${artist}"

    # Download the song
    download_search_results_page "${query}"

    local result=$(get_search_result "${result}")
    local title=$(echo "${result}" | cut -f 1 -d ';')
    local href=$(echo "${result}" | cut -f 2 -d ';')

    youtube-dl-mp3 --no-playlist -x --audio-format mp3 "${YOUTUBE}${href}" \
                   > /dev/null

    # Rename the song to the appropriate name
    if [ -n "${title}" ]; then
        mv "${title}.mp3" "${artist} - ${song}.mp3"
    fi

    rm -f "${RESULTPAGE}"
}

# ------------------------------------------------------------------------------
# Download search results page
download_search_results_page()
{
    # Determine URL of song to search
    local query="${1}"
    local search=$(echo "${query}" | sed -e 's/ /\+/g' -e 's/,/%2c/g' -e "s/'/%27/g")
    local searchurl="${YOUTUBE}/results?search_query=${search}"

    if [ -z "${IGNOREOFFICIAL}" ]; then
        searchurl="${searchurl}+official+video"
    fi

    # Download youtube search page
    wget -q "${searchurl}" -O "${RESULTPAGE}"
}

# ------------------------------------------------------------------------------
# Get href of desired search from results page. Will prompt user if option is
# specified
get_search_result()
{
    local IFS=$'\n'
    local _result="${1}"
    local allref=()
    local alltitle=()
    local ref=
    local title=
    # local response=0
    local i=1

    if [ -n "${PROMPTRESULTS}" ]; then
        echo "Which song would you like to download?" 1>&2
    fi

    # Populate list of all hrefs in search page
    for line in $(grep 'href="/watch?v=' "${RESULTPAGE}" | grep 'title='); do
        ref=$(get_search_result_href "${line}")
        allref+=("${ref}")

        # Do something with the title
        if [ "${ref/list=}" == "${ref}" ]; then
            title=$(get_search_result_title "${line}")
            alltitle+=("${title}")

            # Stop after one search if prompt not specified
            if [ -z "${PROMPTRESULTS}" ]; then
                break
            else
                echo "${i}: ${title}" 1>&2
                i=$[ ${i} + 1 ]
            fi
        fi
    done

    # Prompt user if specified
    if [ -n "${PROMPTRESULTS}" ]; then
        echo -n "> " 1>&2
        read response </dev/tty

        if ! is_integer "${response}" \
                || [ ${response} -lt 1 -o ${response} -gt ${i} ]
        then
            return 1
        fi

        response=$[ ${response} - 1 ]
    else
        response=0
    fi

    echo "${alltitle[${response}]};${allref[${response}]}"
}

# ------------------------------------------------------------------------------
# Return href from a line in the search result page
get_search_result_href()
{
    echo "${1}" \
        | grep -E -o 'href="/watch\?v=[^"]*' \
        | head -n 1 \
        | sed 's/href="//'
}

# ------------------------------------------------------------------------------
# Return title from a line in the search result page
get_search_result_title()
{
    echo "${1}" \
        | grep -E -o 'title="[^"]*' \
        | head -n 1 \
        | sed 's/title="//; s/\&quot\;/"/g'
}

# ------------------------------------------------------------------------------
# Print any discrepancies between the music library file and the library itself
check_music_library()
{
    local artist=
    local song=

    while IFS= read -r line; do
        if [ ! -n "${line}" ]; then
            continue;
        fi

        artist=$(get_artist "${line}")
        song=$(get_song "${line}")

        # Check for existence of artist directory
        if [ ! -d "${LIBDIR}/${artist}" ]; then
            print_warn "Unable to find artist '${artist}' for song '${song}'."
            continue
        fi

        # Check for existence of song file
        if [ ! -f "${LIBDIR}/${artist}/${line}" -o ! -f "${LIBDIR}/${artist}/${song}" ]; then
            print_warn "Unable to find song '${song}' for artist '${artist}'."
            continue
        fi

        printf "%40s %40s %s\n" "'${artist}'" "'${song}'" "${line}"
    done < "${LIBFILE}"
}

# ------------------------------------------------------------------------------
# Return artist name
get_artist()
{
    local line="${1}"
    local artist=
    local i=

    # Artist name is everything before ' - '
    for (( i=0; i < ${#line}; i++ )); do
        if [ "${line:${i}:3}" == " - " ]; then
            echo "${line:0:${i}}"
            return 0
        fi
    done
}

# ------------------------------------------------------------------------------
# Return song name
get_song()
{
    local line="${1}"
    local song=
    local len=
    local i=
    local j=

    # Song name is everything after ' - '
    for (( i=0; i < ${#line}; i++ )); do
        if [ "${line:${i}:3}" == " - " ]; then
            j=$[ ${i} + 3 ]
            len=$[ ${#line} - ${j} ]

            echo "${line:${j}:${len}}"

            return 0
        fi
    done
}

# ------------------------------------------------------------------------------
# Check artist name
check_artist()
{
    if [ -z "${artist}" ]; then
        print_err "Artist could not be found for query: '${q}'"
        return 1
    fi

    return 0
}

# ------------------------------------------------------------------------------
# Check song name
check_song()
{
    if [ -z "${song}" ]; then
        print_err "Song name could not be found for query: '${q}'"
        return 1
    fi

    return 0
}

# ------------------------------------------------------------------------------
# Check artist name
check_music_file()
{
    if [ -f "${artist}/${artist} - ${song}".* ]; then
        return 1
    fi

    return 0
}

# ------------------------------------------------------------------------------
# Run script
main "${@}"
