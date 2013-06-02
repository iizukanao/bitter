# Bitter blog engine

<span style="font-size:80%">[Japanese version（日本語の説明はこちら）](../28/blog_engine_bitter)</span>

_Minimal blog engine for Git and Markdown enthusiasts_

I made a new blog engine "Bitter". The main features are:

- Publish article by "git push"
- Write article in Markdown
- Suitable for text content
- Pure Node.js server
- Simple code base that you can easily hack on

## Source code

The repository is on [GitHub](https://github.com/iizukanao/bitter). Pull requests are welcome.

## Install

On the server side, do as follows. Please replace "blogdir" with your desired directory.

    $ npm install -g bitter
    $ mkdir blogdir
    $ cd blogdir
    $ bitter setup

After setup completed, run the server. Specify listen port with environment variable PORT.

    $ PORT=1341 bitter server

If you're going to use with nginx or Apache, configure them to use reverse proxy.

On the local machine, clone blogdir/notes.git.

    $ git clone user@host:blogdir/notes.git

## To post an entry

In the cloned repository on the local machine, write an article in Markdown, then save it as `year/month/date-slug.md`. Do `git push` to publish it.

    $ mkdir -p 2013/05
    $ echo "# Test\n\nHello World" > 2013/05/27-test.md
    $ git add .
    $ git commit -m "add test entry"
    $ git push origin master

Commit message has no effect on Bitter.

## To edit an existing entry

    $ vim 2013/05/27-test.md
    $ git add -u
    $ git commit -m update
    $ git push origin master

## To delete an entry

    $ git rm 2013/05/27-test.md
    $ git commit -m delete
    $ git push origin master

## To embed static files

Put your static files under the directory that article resides. Those files can be referred to by relative path. For example, to embed 2013/05/images/winter.jpg, write following code in 2013/05/27-test.md.

    ![Winter photo](images/winter.jpg)

If you put static files under "public" directory, those files can be referred to by absolute path. For example, to embed public/images/spring.jpg:

    ![Spring photo](/images/spring.jpg)
