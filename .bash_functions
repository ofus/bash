# Simple calculator
function calc() {
	local result=""
	result="$(printf "scale=10;$*\n" | bc --mathlib | tr -d '\\\n')"
	#                       └─ default (when `--mathlib` is used) is 20
	#
	if [[ "$result" == *.* ]]; then
		# improve the output for decimal numbers
		printf "$result" |
		sed -e 's/^\./0./'        `# add "0" for cases like ".5"` \
		    -e 's/^-\./-0./'      `# add "0" for cases like "-.5"`\
		    -e 's/0*$//;s/\.$//'   # remove trailing zeros
	else
		printf "$result"
	fi
	printf "\n"
}

# Create a new directory and enter it
function mkd() {
	mkdir -p "$@" && cd "$@"
}

# Determine size of a file or total size of a directory
function fs() {
	if du -b /dev/null > /dev/null 2>&1; then
		local arg=-sbh
	else
		local arg=-sh
	fi
	if [[ -n "$@" ]]; then
		du $arg -- "$@"
	else
		du $arg .[^.]* *
	fi
}

# Use Git’s colored diff when available
hash git &>/dev/null
if [ $? -eq 0 ]; then
	function diff() {
		git diff --no-index --color-words "$@"
	}
fi

# Create a data URL from a file
function dataurl() {
	local mimeType=$(file -b --mime-type "$1")
	if [[ $mimeType == text/* ]]; then
		mimeType="${mimeType};charset=utf-8"
	fi
	echo "data:${mimeType};base64,$(openssl base64 -in "$1" | tr -d '\n')"
}

# Start an HTTP server from a directory, optionally specifying the port
function server() {
	local port="${1:-8000}"
	sleep 1 && open "http://localhost:${port}/" &
	# Set the default Content-Type to `text/plain` instead of `application/octet-stream`
	# And serve everything as UTF-8 (although not technically correct, this doesn’t break anything for binary files)
	python -c $'import SimpleHTTPServer;\nmap = SimpleHTTPServer.SimpleHTTPRequestHandler.extensions_map;\nmap[""] = "text/plain";\nfor key, value in map.items():\n\tmap[key] = value + ";charset=UTF-8";\nSimpleHTTPServer.test();' "$port"
}

# Start a PHP server from a directory, optionally specifying the port
# (Requires PHP 5.4.0+.)
function phpserver() {
	local port="${1:-4000}"
	local ip=$(ipconfig getifaddr en1)
	sleep 1 && open "http://${ip}:${port}/" &
	php -S "${ip}:${port}"
}

# Compare original and gzipped file size
function gz() {
	local origsize=$(wc -c < "$1")
	local gzipsize=$(gzip -c "$1" | wc -c)
	local ratio=$(echo "$gzipsize * 100/ $origsize" | bc -l)
	printf "orig: %d bytes\n" "$origsize"
	printf "gzip: %d bytes (%2.2f%%)\n" "$gzipsize" "$ratio"
}

# Test if HTTP compression (RFC 2616 + SDCH) is enabled for a given URL.
# Send a fake UA string for sites that sniff it instead of using the Accept-Encoding header. (Looking at you, ajax.googleapis.com!)
function httpcompression() {
	local encoding="$(curl -LIs -H 'User-Agent: Mozilla/5 Gecko' -H 'Accept-Encoding: gzip,deflate,compress,sdch' "$1" | grep '^Content-Encoding:')" && echo "$1 is encoded using ${encoding#* }" || echo "$1 is not using any encoding"
}

# Syntax-highlight JSON strings or files
# Usage: `json '{"foo":42}'` or `echo '{"foo":42}' | json`
function json() {
	if [ -t 0 ]; then # argument
		python -mjson.tool <<< "$*" | pygmentize -l javascript
	else # pipe
		python -mjson.tool | pygmentize -l javascript
	fi
}

# All the dig info
function digga() {
	dig +nocmd "$1" any +multiline +noall +answer
}

# Escape UTF-8 characters into their 3-byte format
function escape() {
	printf "\\\x%s" $(printf "$@" | xxd -p -c1 -u)
	echo # newline
}

# Decode \x{ABCD}-style Unicode escape sequences
function unidecode() {
	perl -e "binmode(STDOUT, ':utf8'); print \"$@\""
	echo # newline
}

# Get a character’s Unicode code point
function codepoint() {
	perl -e "use utf8; print sprintf('U+%04X', ord(\"$@\"))"
	echo # newline
}

# Show all the names (CNs and SANs) listed in the SSL certificate
# for a given domain
function getcertnames() {
	if [ -z "${1}" ]; then
		echo "ERROR: No domain specified."
		return 1
	fi

	local domain="${1}"
	echo "Testing ${domain}…"
	echo # newline

	local tmp=$(echo -e "GET / HTTP/1.0\nEOT" \
		| openssl s_client -connect "${domain}:443" 2>&1);

	if [[ "${tmp}" = *"-----BEGIN CERTIFICATE-----"* ]]; then
		local certText=$(echo "${tmp}" \
			| openssl x509 -text -certopt "no_header, no_serial, no_version, \
			no_signame, no_validity, no_issuer, no_pubkey, no_sigdump, no_aux");
			echo "Common Name:"
			echo # newline
			echo "${certText}" | grep "Subject:" | sed -e "s/^.*CN=//";
			echo # newline
			echo "Subject Alternative Name(s):"
			echo # newline
			echo "${certText}" | grep -A 1 "Subject Alternative Name:" \
				| sed -e "2s/DNS://g" -e "s/ //g" | tr "," "\n" | tail -n +2
			return 0
	else
		echo "ERROR: Certificate not found.";
		return 1
	fi
}

function parse_bzr_dirty() {
        [[ $(bzr status 2> /dev/null | wc -l) != 0 ]] && echo "*"
}

function parse_bzr_changes() {
        BZR_CHANGES=$(bzr status 2> /dev/null | wc -l)
        [[ $BZR_CHANGES != 0 ]] && echo "[$BZR_CHANGES]"
}

function parse_git_dirty() {
        [[ $(git status 2> /dev/null | tail -n1) != *"working directory clean"* ]] && echo "*"
}

function parse_git_branch() {
        git branch --no-color 2> /dev/null | sed -e '/^[^*]/d' -e "s/* \(.*\)/\1$(parse_git_dirty)/"
}

function show_group_not_default() {
    local u=$(whoami)
    local curgrp=$(id -gn)
    local defaultgrp=$(grep ":$(cat /etc/passwd | grep $u | cut -d: -f4):" /etc/group |  cut -d: -f41)
    if [ "$curgrp" != "$defaultgrp" ]; then
        echo "($curgrp)"
    fi
}

function aqg() {
    if [ -z "${1}" ]; then
        echo "E: You must give at least one search pattern"
        return 1
    fi

    local aq="${1}"
    #apt-cache search $aq | grep -v lib | grep -i --color $aq
    apt-cache search $aq | grep -i --color $aq
}

function aiv() {
    if [ -z "${1}" ]; then
        echo "E: You must give at least one search pattern"
        return 1
    fi

    local aq="${1}"
    apt-cache show $aq | grep Version
}

function psgrep() {
    if [ -z "${1}" ]; then
        echo "E: You must give at least one search pattern"
        return 1
    fi

    local psquery="${1}"
    ps aux | head -n1
    ps aux | grep -v 'grep' | grep -i --color $psquery
}

function cq() {
    if [ -z "${1}" ]; then
        echo "E: You must give at least one search pattern"
        return 1
    fi

    local foo="${@}"
    local cipherquery=$(echo $foo 2>/dev/null| sed 's/\ /\:/g' )
    local bar="$cipherquery:!eNULL:!aNULL:!ADH:!EXP:!PSK:!SRP:!DSS:!ECDSA"
    cqn $bar | grep -v "PSK"
}

function cqn() {
    if [ -z "${1}" ]; then
        echo "E: You must give at least one search pattern"
        return 1
    fi

    local foo="${@}"
    local cipherquery=$(echo $foo 2>/dev/null| sed 's/\ /\:/g' )
    local bar="$cipherquery"
    openssl ciphers -v "$bar" | column -t | grep -v ECDSA | grep -v "DH-"
}

function comptest() {
    if [ -z "${1}" ]; then
        echo "E: You must give at least one search pattern"
        return 1
    fi
    local foo="${@}"
    echo foo=\"$foo\"
}

function wp() {
    if [ -z "${1}" ]; then
        echo "E: You must give a hostname"
        return 1
    fi
    local host="${1}"
    wikipedia2text $host | $MANPAGER
}

function ssl3test() {
    if [ -z "${1}" ]; then
        echo "E: You must give a hostname"
        return 1
    fi
    local foo="${1}"
    echo "attempting to connect via ssl3 to $foo ..."
    openssl s_client -ssl3 -connect $foo:443
}

function psgrep() {
    if [ -z "${1}" ]; then
        echo "E: You must give at least one search pattern"
        return 1
    fi

    local psquery="${1}"
    ps aux | head -n1
    ps aux | grep -v 'grep' | grep -i --color $psquery
}

function ssl3test() {
    if [ -z "${1}" ]; then
        echo "E: You must give a hostname"
        return 1
    fi
    local foo="${1}"
}

function parse_svn_dirty() {
 [[ $(svn info 2> /dev/null | wc -l) >1 ]] && echo "*"
}

function svn_test() {
    if [ -d ".svn" ]; then
        echo "svn!"
    fi
}

function svn_check_for_remote_updates() {
    if [ -d ".svn" ]; then
        REMOTE_REVISION=$(svn info -r HEAD | grep -i "Last Changed Rev" | awk {' print $4 '} )
        MY_REVISION=$(svn info | grep -i "Last Changed Rev" | awk {' print $4 '} )
        [[ $REMOTE_REVISION == $MY_REVISION ]] && return
        SVN_REVISION_COUNT=$(calc $REMOTE_REVISION-$MY_REVISION)
        echo * $SVN_REVISION_COUNT CHANGES *
    fi
}

