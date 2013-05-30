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

On the client side, clone blogdir/notes.git.

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
