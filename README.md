## Bitter - a minimal blog engine

_Waste everything but Git and Markdown_

[Demo](http://notes.kyu-mu.net/2013/05/27/markdown_example) (in other words, my blog)

### Features

- Publish entry by "git push"
- Write entry in Markdown
- Suitable for text content
- Pure Node.js server
- Simple code base that you can easily hack on

### Requirements

- Node.js v0.10.4 or later
- "git" command

### Install

On the server side, do as follows. Replace "blogdir" with your desired directory.

    $ npm install -g bitter
    $ mkdir blogdir
    $ cd blogdir
    $ bitter setup

Then start the server. Specify listen port with environment variable PORT.

    $ PORT=1341 bitter server

On the local machine, clone blogdir/notes.git.

    $ git clone user@host:blogdir/notes.git

### To post an entry

In the cloned repository on the local machine, write an entry in Markdown with your favorite editor, then save it as `year/month/date-slug.md`. Do `git push` to publish it.

    $ mkdir -p 2013/05
    $ echo "# Test\n\nHello World" > 2013/05/27-test.md
    $ git add .
    $ git commit -m "add test entry"
    $ git push origin master

### To edit an existing entry

On the local machine:

    $ vim 2013/05/27-test.md
    $ git add -u
    $ git commit -m update
    $ git push origin master

### To delete an entry

On the local machine:

    $ git rm 2013/05/27-test.md
    $ git commit -m delete
    $ git push origin master

### To embed static files

Put your static files under the directory that entry resides. Those files can be referred to by relative path. For example, to embed 2013/05/images/winter.jpg, write following code in 2013/05/27-test.md.

    ![Winter photo](images/winter.jpg)

If you put static files under "public" directory, those files can be referred to by absolute path. For example, to embed public/images/spring.jpg:

    ![Spring photo](/images/spring.jpg)

### To view entry on your local machine

First, install Bitter on your local machine.

    $ npm install -g bitter

Then clone notes.git from server as bare repository.

    $ mkdir localblogdir
    $ cd localblogdir
    $ git clone --bare user@host:blogdir/notes.git

cd to notes.git, and do "bitter gitconfig".

    $ cd notes.git
    $ bitter gitconfig
    created ../notes for worktree
    successfully configured

Now notes directory has set up automatically.

    $ cd ..
    $ ls
    $ notes notes.git

Run the server.

    $ PORT=1341 bitter server

Visit http://localhost:1341/ with browser.
