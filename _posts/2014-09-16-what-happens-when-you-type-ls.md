---
layout: post
title: What Happens When You Type ls
---
What Happens When You Type `ls`
===============================
In preparation for another season of interviews, I want to write up a more
complete answer to a question I was given over a year ago.

Starting From The Middle: The Shell
-----------------------------------
First, let's assume that we're sitting in front of a 32 bit IBM PC-like
machine using some *nix like operating system. We're at the shell and all we
see is this

    $

First we press down on the letter `l`. What happens? The shell is probably
waiting for the next line to process from a call to `readline`. `readline` in
turn is going to capture inputs from the keyboard and store them into some sort
of buffer until a newline is reached.

When we press `s` still nothing happens because readline hasn't reached the end
of a line. When we press `ENTER` it gets converted to a `\n`, and readline
returns the command back to the shell.

Now the shell needs to interpret the line `ls`. First it must break apart `ls`
into its actual parts. Fortunately, there is only one part and that is the
string `ls`.

Now, in order to do execute `ls` the shell needs to know which executable to
execute. The common method of doing this on *nix like systems is to look in the
`PATH` environment variable. It iterates through portions of the `PATH` trying
to `stat` a file called `ls` in order to find the executable.

Once the shell finds the executable for `ls`, say at `/bin/ls`, it `fork`s a
child process and `exec`s the executable.

Because of the semantics of the *nix like processes, the child will share the
parent's file descriptors. The child will end up writing to the same stdout as
the shell. The stdout will be put out to the console.

Deeper: Inside `ls`
-------------------
`ls` is a relatively simple program. `ls` expects some path to list, but if
`ls` is not given a path it will assume the current working directory (cwd),
also represented by `.`.

Once `ls` knows which path it wants to list, it will `stat` the path.

`ls` typically has two modes, one to handle a file, and one to handle a
directory. Since we just typed `ls`, we'll consider what happens when `ls` runs
on a directory.
