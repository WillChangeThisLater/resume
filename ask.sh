#!/bin/bash

trap cleanup INT

function cleanup() {
    echo
    echo "ctrl+c received, exiting" >&2
    if [ -z "$pythonPID" ]; then
        kill -9 "$pythonPID"
    fi
    if [ -z "$ngrokPID" ]; then
        kill -9 "$ngrokPID"
    fi
    cat <<EOF >&2
The python server running on 0.0.0.0:8888 and the ngrok
instance tunneling traffic should both be dead.

But it never hurts to check.

\`\`\`bash
pgrep python
pgrep ngrok
\`\`\`
EOF
}

function defaultPrompt() {
    cat <<EOF
You'll notice that this PDF looks a bit ugly.

Read through the resume carefully. Explain what
can be improved. Suggest fixes to the latex code
to fix whatever issues you find. Pay special
attention to obvious bugs (mispellings, weird
font sizes, inconsistent formatting, etc.).

EOF
}

prompt="$(defaultPrompt)"
if [ ! -z "$1" ]; then
    prompt="$1"
fi


# start up python server which will server the image locally
python -m http.server --bind 0.0.0.0 8888 >/dev/null 2>&1 &
if [ $? -ne 0 ]; then
    echo "Failure: python server on 0.0.0.0:8888 failed to start" >&2
    exit 1
fi
pythonPID=$!

# start up ngrok instance which will tunnel some public URL to the python server
pkill ngrok
ngrok http 8888 >/dev/null 2>&1 &
if [ $? -ne 0 ]; then
    echo "Failure: ngrok failed to start" >&2
    kill -9 "$pythonPID"
    exit 1
fi
ngrokPID=$!

# wait a few seconds for ngrok to start up, then figure out the public URL
# if the curl fails, assume that there was some kind of error starting ngrok and exit
sleep 3
tunnelPath=$(curl -s localhost:4040/api/tunnels | jq -r '.tunnels.[].public_url')
if [ -z "$tunnelPath" ]; then
    echo "tunnelPath not set - exiting" >&2
    kill -9 "$pythonPID"
    kill -9 "$ngrokPID"
    exit 1
fi

# FOR DEBUGGING: sleep 10 mins
DEBUG=0
if [ "$DEBUG" -gt 0 ]; then
    echo "tunnelPath=$tunnelPath"
    sleep 600
    cleanup
    exit 1
fi


# build the prompt and get the response
imagePath="$tunnelPath/paul_wendt.png" # Windows users be damned

# if you want to see the prompt, tee out to /dev/stderr
#
# cat <<EOF | tee /dev/stderr | lm --imageURLs "$imagePath" --model gpt-4o
cat <<EOF | lm --imageURLs "$imagePath" --model gpt-4o-mini
I have the following latex file:

\`\`\`cat paul_wendt.tex
$(cat paul_wendt.tex)
\`\`\`

I have compiled this latex file to a PDF (see attached)

$prompt

If you're outputting latex code, please only show the section(s) of
the code relevant to the change(s) you're making. Don't just output
the whole resume.

EOF

# kill the python and ngrok processes
kill -9 "$pythonPID"
kill -9 "$ngrokPID"
exit 0
