### What is this
A resume template. Written in LaTeX, compiled to PDF

Thanks to [Sourabh Bajaja](https://github.com/sb2nov/resume) for providing 95% of this code.


### My workflow
I'm pretty bad at LaTeX and pretty ornery about formatting.
So I wrote a custom bash script to interact with an LLM, `./ask.sh`
My workflow has basically been:

1. Run `./run.sh` to compile the resume and see what it looks like
2. Take a look and figure out what I don't like
3. Run `./ask.sh` to fix my problem. For instance, if I didn't like
   the spacing between the accomplishment and project sections, I'd
   probably write

   ```bash
   ./ask.sh "Decrease the spacing between the accomplishment and project sections"
   ```

### Building
```bash
docker build -t latex .
```

### Running
```bash
./run.sh
```

`run.sh` assumes `pdftoppm` and `mupdf` are both installed

### More info on `ask.sh`
High level, `ask.sh` is a script which calls out to OpenAI's gpt-4o-mini model.
The call includes a prompt (with the contents of paul_wendt.tex injected in)
as well as an image URL pointing to the paul_wendt.png image on my local machine.

There's a default prompt asking it some generic bullshit. You can override that
by providing a custom prompt via arg 1. See above for an example

The script assumes a couple programs are installed on your local system:

  - `python`, for creating a local HTTP server that will expose `paul_wendt.png`
  - `ngrok`, for creating a tunnel from the internet to that local python server
  - `go-llm`, [a tool](https://github.com/WillChangeThisLater/go-llm) I created for querying LLMs on the CLI

When the script runs, it kicks up a python HTTP server on 0.0.0.0:8888. It then spins up
ngrok to tunnel traffic to the server. It does this rather violently (e.g. if ngrok
is running elsewhere it `pkill`s it. I have the free plan so I find this behavior reasonable)

Once this is all set up, the script generates the prompt and calls lm (internally `go-llm`,
I just aliased this to `lm` on my system). In the best case, there are no errors and
the model returns a smart sounding suggestion.
