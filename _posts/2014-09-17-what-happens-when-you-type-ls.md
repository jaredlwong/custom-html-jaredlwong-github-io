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
table. The file descriptor we pass to `fgets` will probably be `0` which
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
- How do the keyboard inputs get to stdin?
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
- How do the keyboard inputs get to stdin in the shell?
- How does the stdout get to the console?
- Why can we just read a path as an array of directory entries?
- How does stat work?

### Up Above: The Console
Now we'll address two of our outstanding questions:
- When the shell reads `stdin` using `fgets`, how is it getting input from the
  keyboard?
- How does the stdout get to the console?

When an operating system typically starts up it initializes an `init` process
which hooks up some basic features. In xv6, it hooks up the console.

Here is the init code from xv6:

    char *argv[] = { "sh", 0 };

    int
    main(void)
    {
      int pid, wpid;

      if(open("console", O_RDWR) < 0){
        mknod("console", 1, 1);
        open("console", O_RDWR);
      }
      dup(0);  // stdout
      dup(0);  // stderr

      for(;;){
        printf(1, "init: starting sh\n");
        pid = fork();
        if(pid < 0){
          printf(1, "init: fork failed\n");
          exit();
        }
        if(pid == 0){
          exec("sh", argv);
          printf(1, "init: exec sh failed\n");
          exit();
        }
        while((wpid=wait()) >= 0 && wpid != pid)
          printf(1, "zombie!\n");
      }
    }

The init code creates a special device file `console` (if it doesn't exist) and
sets it to file descriptors 0, 1, and 2 (stdin, stdout, and stderr).

All other processes are typically the child of the init process, so they all
inherit these special file descriptors which point to the `console` device
file.

Reading and writing to the device file is just like reading and writing to any
other file. Using the inode's major and minor device number, the operating
system can figure out which read and write functions to call. These device
specific read and write functions are the drivers that actually interface with
the hardware.

#### Outstanding Questions
- Why can we just read a path as an array of directory entries?
- How does stat work?

### Down Below: The File System
Now we'll answer our last two questions by exploring a typical *nix filesystem.

First, both files and directories have an associated inode and data. An inode
is simply the metadata for the file or directory. The data inside a file is the
file's contents. The data for a directory is an array of directory entries.
Each directory entry holds the name of a file inside that directory and the
file's corresponding inode number.

In xv6, this is the definition for a directory entry:

    struct dirent {
      ushort inum;
      char name[DIRSIZ];
    };

As long as we know the root `/` inode of the file system, we can recursively
traverse directory entries to find the inode for a specific file.

`stat` simply looks up a path using this mechanism, and returns the inode
information in a more presentable manner.

The operating system is in charge of organizing the inodes on disk so that it
can access them easily. The os will use the same types of device files as
described in the previous section to read and write from the disk.

### Conclusion
This is only a brief explorating into what happens when you type `ls`. There's
still a whole ton more that happens. Here is a non-exhaustive list of some more
things that happen, that aren't really covered here:

- How do hardware interrupts work?
- How does a disk seek?
- We're working with virtual addresses, how are those translated to physical
  memory addresses?
- How does the console render our output?
