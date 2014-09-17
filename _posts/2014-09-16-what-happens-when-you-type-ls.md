---
layout: post
title: What Happens When You Type ls
---
What Happens When You Type ls
=============================
In preparation for another season of interviews, I want to write up a more
complete answer to a question I was given over a year ago.

### Starting From The Middle: The Shell
First, let's assume that we're sitting in front of a 32 bit IBM PC-like
machine using some *nix like operating system. We're at the shell and all we
see is this

    $

First we press down on the letter `l`. What happens? The shell is probably
waiting for the next line to process from a call to `fgets`. `fgets` reads from
a file descriptor into a buffer. It returns when either the buffer fills up or
it reaches a newline.

A file descriptor is simply an integer index into the processes file descriptor
table. The file descriptor we pass to `fgets` will probably be `1` which
represents the standard input (stdin). In our case stdin will provide data from
our keyboard.

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

Here is some sample code that might execute the command `/bin/ls`:

    char *argv = {"/bin/ls", NULL};
    if (fork() == 0) {
        execv(argv[0], argv);
    }
    wait();

Because of the semantics of the *nix like processes, the child will share the
parent's file descriptors. The child will end up writing to the same standard
output (stdout) as the shell. The stdout will be written out to the console.

#### Outstanding Questions
- What is ls doing?
- How do the keyboard inputs get to stdin? What is fgets doing?
- How does the stdout get to the console?

### Deeper: Inside ls
`ls` is a relatively simple program. `ls` expects some path to list, but if
`ls` is not given a path it will assume the current working directory (cwd),
also represented by `.`.

Once `ls` knows which path it wants to list, it will `open` and `stat` the
path. It `open`s the file in case it's a directory, and it `stat`s the path to
get some basic info about the path (like whether it's a file or directory).

`ls` typically has two modes, one to handle a file, and one to handle a
directory. Since we just typed `ls`, we'll consider what happens when `ls` runs
on a directory.

When `ls` runs on a directory, it reads each of the directory entries from the
`open`ed path, and it `stat`s each of the directory entries. It prints out some
info about the entry.

Here is some sample code from the xv6 operating system for ls:

    void
    ls(char *path)
    {
      char buf[512], *p;
      int fd;
      struct dirent de;
      struct stat st;

      if((fd = open(path, 0)) < 0){
        printf(2, "ls: cannot open %s\n", path);
        return;
      }

      if(fstat(fd, &st) < 0){
        printf(2, "ls: cannot stat %s\n", path);
        close(fd);
        return;
      }

      switch(st.type){
      case T_FILE:
        printf(1, "%s %d %d %d\n", fmtname(path),
               st.type, st.ino, st.size);
        break;

      case T_DIR:
        if(strlen(path) + 1 + DIRSIZ + 1 > sizeof buf){
          printf(1, "ls: path too long\n");
          break;
        }
        strcpy(buf, path);
        p = buf+strlen(buf);
        *p++ = '/';
        while(read(fd, &de, sizeof(de)) == sizeof(de)){
          if(de.inum == 0)
            continue;
          memmove(p, de.name, DIRSIZ);
          p[DIRSIZ] = 0;
          if(stat(buf, &st) < 0){
            printf(1, "ls: cannot stat %s\n", buf);
            continue;
          }
          printf(1, "%s %d %d %d\n", fmtname(buf),
                 st.type, st.ino, st.size);
        }
        break;
      }
      close(fd);
    }

#### Outstanding Questions
- How do the keyboard inputs get to stdin in the shell? What is fgets doing?
- How does the stdout get to the console?
- Why can we just read a path as an array of directory entries?
- How does stat work?
