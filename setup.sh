#!/bin/sh

if [ -e ../notes.git/config ]; then
  echo "It appears you already have set up"
  exit 1
fi

echo "setting up..."

cd ..
mkdir notes notes.git

# Prepare notes.git
cd notes.git
git --bare init
git config core.bare false
git config core.worktree ../notes
git config receive.denycurrentbranch ignore

# Arrange hook for post-receive event
if [ ! -e hooks/post-receive ]; then
  echo "#!/bin/sh" > hooks/post-receive
fi
cat >> hooks/post-receive <<EOF

# Bitter
git checkout -f
touch ../engine/reindex-needed
EOF
chmod +x hooks/post-receive

# Create default files
cd ../notes
mkdir config public

cat > config/config.json <<EOF
{
  "siteName"   : "MyLittleBlog",
  "siteURL"    : "http://blog.example.com",
  "authorName" : "Nanashino Bombay",
  "authorLink" : "http://example.com/",
  "authorEmail": ""
}
EOF

cat > config/page.ejs <<EOF
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width">
  <title><% if (title) { %><%= title %> | <% } %><%= siteName %></title>
  <link rel="alternate" type="application/atom+xml" href="<%= siteURL %>/feed.atom">
  <link rel="stylesheet" href="/base.css">
</head>
<body>
<div id="header">
  <a href="/"><%= siteName %></a>
  <a href="/recents">Recent entries</a>
  <a href="/feed.atom">Feed</a>
</div>
<div id="content">
<%- body -%>
</div>
<%- author -%>
<div class="powered-by">
Powered by <a href="https://github.com/iizukanao/bitter">Bitter</a>
</div>
</body>
</html>
EOF

cat > public/base.css <<EOF
@charset "UTF-8";

body {
  margin: 1em auto 2em auto;
  width: 70%;
  max-width: 700px;
  color: #000;
  font-size: 20px;
  font-family: Times, "Times New Roman", "Hiragino Mincho ProN", "IPAPMincho", serif;
  line-height: 1.6;
}

h1, h2, h3, h4, h5, h6 {
  margin: 0 auto 1.2em auto;
  padding-top: 1.2em;
}

h1 {
  font-size: 140%;
}

h2 {
  font-size: 120%;
}

h3 {
  font-size: 100%;
}

h4 {
  font-size: 90%;
}

h5 {
  font-size: 80%;
}

h6 {
  font-size: 70%;
}

a {
  color: #4040c4;
  text-decoration: none;
}

a:hover {
  text-decoration: underline;
}

ul {
  margin-bottom: 0;
  list-style-type: square;
}

pre {
  background-color: #f5f5f5;
  padding: 16px;
  width: 95%;
  overflow: auto;
  font-family: Consolas, "Courier New", Monaco, monospace;
  font-size: 18px;
}

code {
  margin: 0 .1em;
  background-color: #f5f5f5;
  padding: .1em .4em;
}

pre code {
  margin: 0;
  padding: 0;
}

blockquote {
  font-style: italic;
}

table {
  margin: 1.2em auto;
  width: 70%;
  border-collapse: collapse;
}

th, td {
  border: 1px solid #999;
  padding: 6px 10px;
  color: #333;
}

p {
  margin-bottom: 0;
}

div#header {
  margin-bottom: 1em;
  font-size: 14px;
}

div#header a {
  margin-right: .5em;
}

div.date a {
  margin-top: 1.5em;
  color: #505050;
  font-size: 14px;
}

.title {
  margin: .6em auto;
  padding-top: 0;
}

.title a {
  color: #000;
}

.anchor a {
  color: #000;
}

div#content {
  margin-bottom: 2.3em;
}

div#content img {
  max-width: 100%;
}

div.author {
  color: #505050;
  font-style: italic;
  font-size: 14px;
}

div.powered-by {
  color: #505050;
  font-style: italic;
  font-size: 14px;
}

@media only screen and (max-width: 640px) {
  body {
    margin: .5em .5em 2em .5em;
    width: 95%;
  }

  table {
    width: 80%;
  }

  pre {
    width: 90%;
  }
}
EOF

# Commit them
cd ../notes.git
git add .
git commit -m "Setup"

echo "\nsetup completed"
