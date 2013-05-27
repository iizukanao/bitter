## Bitter

Minimal blog engine - Waste everything but Git and Markdown

### Requirements

- Node.js v0.10.4 or later
- "git" command

### Install

On the server side:

    $ npm install -g bitter
    $ mkdir blogdir
    $ cd blogdir
    $ bitter setup
    $ PORT=1341 bitter server

On the client side:

    $ git clone user@host:blogdir/notes.git

### To post an entry

On the client side:

    $ mkdir -p 2013/05
    $ echo "# Test\n\nHello World" > 2013/05/27-test.md
    $ git add .
    $ git commit -m "add an entry"
    $ git push

### To edit an entry

    $ vim 2013/05/27-test.md
    $ git add -u
    $ git commit -m update
    $ git push

### To delete an entry

    $ git rm 2013/05/27-test.md
    $ git commit -m delete
    $ git push
