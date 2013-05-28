## Bitter - a minimal blog engine

Waste everything but Git and Markdown

[Example](http://notes.kyu-mu.net/2013/05/27/markdown_example)

### Requirements

- Node.js v0.10.4 or later
- "git" command

### Install

On the server side:

    $ npm install -g bitter
    $ mkdir blogdir
    $ cd blogdir
    $ bitter setup

Then start the server.

    $ PORT=1341 bitter server

On the client side:

    $ git clone user@host:blogdir/notes.git

### To post an entry

In the cloned repository on the client side:

    $ mkdir -p 2013/05
    $ echo "# Test\n\nHello World" > 2013/05/27-test.md
    $ git add .
    $ git commit -m "add test entry"
    $ git push

### To edit an existing entry

    $ vim 2013/05/27-test.md
    $ git add -u
    $ git commit -m update
    $ git push

### To delete an entry

    $ git rm 2013/05/27-test.md
    $ git commit -m delete
    $ git push
