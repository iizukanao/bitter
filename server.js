// Generated by CoffeeScript 1.6.2
(function() {
  var PORT, app, basedir, config, configFilename, convertToAbsoluteLinks, createIndex, ejs, err, escapeTags, express, findTitleFromLex, formatDate, formatPage, fs, listEntries, listMonths, listYears, loadConfig, logMessage, marked, monthNames, obfuscateEmail, pageTemplate, pageTemplateFilename, path, recentInfo, reindexCheckFilename, respondWithNotFound, respondWithServerError;

  fs = require('fs');

  path = require('path');

  ejs = require('ejs');

  marked = require('marked');

  express = require('express');

  basedir = path.normalize("" + (process.cwd()) + "/notes");

  PORT = parseInt(process.env.PORT);

  if (isNaN(PORT)) {
    PORT = 1341;
  }

  configFilename = "" + basedir + "/config/config.json";

  pageTemplateFilename = "" + basedir + "/config/page.ejs";

  reindexCheckFilename = "" + basedir + "/reindex-needed";

  monthNames = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];

  formatDate = function(year, month, date) {
    return "" + monthNames[month - 1] + " " + (parseInt(date)) + ", " + year;
  };

  config = null;

  app = express();

  app.use(express.compress());

  app.use(express.responseTime());

  app.use(express["static"]("" + basedir + "/public"));

  if (!fs.existsSync(configFilename)) {
    console.log("" + configFilename + " does not exist");
    process.exit(1);
  }

  logMessage = function(str, opts) {
    var buf, d;

    buf = '';
    if (!(opts != null ? opts.noTime : void 0)) {
      d = new Date;
      buf += "[" + (d.toDateString()) + " " + (d.toLocaleTimeString()) + "] ";
    }
    buf += str;
    if (!(opts != null ? opts.noNewline : void 0)) {
      buf += "\n";
    }
    return process.stdout.write(buf);
  };

  obfuscateEmail = function(str) {
    var buf, i, _i, _ref;

    buf = '';
    for (i = _i = 0, _ref = str.length; 0 <= _ref ? _i < _ref : _i > _ref; i = 0 <= _ref ? ++_i : --_i) {
      buf += "&#" + (str.charCodeAt(i)) + ";";
    }
    return buf;
  };

  loadConfig = function() {
    var e;

    try {
      config = JSON.parse(fs.readFileSync(configFilename));
    } catch (_error) {
      e = _error;
      logMessage("" + configFilename + " read error: " + e);
      return e;
    }
    config.siteURL = config.siteURL.replace(/\/$/, '');
    config.authorEmail = obfuscateEmail(config.authorEmail);
    return null;
  };

  err = loadConfig();

  if (err != null) {
    process.exit(1);
  }

  recentInfo = {};

  marked.setOptions({
    gfm: true,
    tables: true,
    breaks: true,
    pedantic: false,
    sanitize: false,
    smartLists: true,
    langPrefix: 'lang-'
  });

  if (fs.existsSync(reindexCheckFilename)) {
    fs.unlink(reindexCheckFilename);
  }

  fs.watchFile(reindexCheckFilename, function(curr, prev) {
    if (curr.nlink > 0) {
      return fs.unlink(reindexCheckFilename, function() {
        return createIndex();
      });
    }
  });

  fs.watchFile(configFilename, function(curr, prev) {
    err = loadConfig();
    if (err == null) {
      return logMessage("loaded " + (path.basename(configFilename)));
    }
  });

  pageTemplate = fs.readFileSync(pageTemplateFilename, {
    encoding: 'utf8'
  });

  fs.watchFile(pageTemplateFilename, function(curr, prev) {
    return fs.readFile(pageTemplateFilename, {
      encoding: 'utf8'
    }, function(err, data) {
      if (err) {
        logMessage("" + pageTemplateFilename + " read error: " + err);
        return;
      }
      pageTemplate = data;
      return logMessage("loaded " + (path.basename(pageTemplateFilename)));
    });
  });

  escapeTags = function(str) {
    str = str.replace(/&/g, '&amp;');
    str = str.replace(/</g, '&lt;');
    str = str.replace(/>/g, '&gt;');
    str = str.replace(/"/g, '&quot;');
    return str;
  };

  respondWithServerError = function(res) {
    var markdown;

    markdown = "## Server Error\n\nPlease try again later.\n";
    return formatPage({
      markdown: markdown,
      noTitleLink: true,
      noAuthor: true
    }, function(err, html) {
      if (err) {
        logMessage(err);
        res.send(500, 'Server error');
        return;
      }
      res.setHeader('Content-Type', 'text/html; charset=utf-8');
      return res.send(500, html);
    });
  };

  respondWithNotFound = function(res) {
    var markdown;

    markdown = "## Not Found\n\nThe requested document was not found.\n";
    return formatPage({
      markdown: markdown,
      noTitleLink: true,
      noAuthor: true
    }, function(err, html) {
      if (err) {
        logMessage(err);
        respondWithServerError(res);
        return;
      }
      res.setHeader('Content-Type', 'text/html; charset=utf-8');
      return res.send(404, html);
    });
  };

  findTitleFromLex = function(lex) {
    var component, _i, _len;

    for (_i = 0, _len = lex.length; _i < _len; _i++) {
      component = lex[_i];
      if (component.type === 'heading') {
        return component.text;
      }
    }
    return null;
  };

  convertToAbsoluteLinks = function(html, params) {
    html = html.replace(/(<a href|<img src)="(.*?)"/g, function(match, p1, p2) {
      p2 = p2.replace(/^\.\.\/(?!\.\.)/g, "/" + params.year + "/" + params.month + "/");
      p2 = p2.replace(/^\.\.\/\.\.\/(?!\.\.)/g, "/" + params.year + "/");
      p2 = p2.replace(/^\.\.\/\.\.\/\.\.\/(?!\.\.)/g, "/");
      if (p2.indexOf('://') === -1) {
        if (p2[0] !== '/') {
          p2 = "/" + params.year + "/" + params.month + "/" + params.date + "/" + p2;
        }
        if (params.absoluteURL) {
          p2 = "" + config.siteURL + p2;
        }
      }
      return "" + p1 + "=\"" + p2 + "\"";
    });
    return html;
  };

  formatPage = function(input, callback) {
    var author, body, buf, headingCount, html, lex, lexTitle, opts, title, _ref;

    lex = marked.Lexer.lex(input.markdown);
    title = (_ref = input.title) != null ? _ref : null;
    if (title == null) {
      lexTitle = findTitleFromLex(lex);
      if (lexTitle != null) {
        title = lexTitle;
      }
    }
    if (title == null) {
      title = '(untitled)';
    }
    body = marked.Parser.parse(lex);
    if (input.absolutePath || input.absoluteURL) {
      body = convertToAbsoluteLinks(body, input);
    }
    if ((input.year != null) && (input.month != null) && (input.date != null)) {
      buf = "<div class=\"date\">";
      if (!input.noTitleLink) {
        buf += "<a href=\"" + input.link + "\">";
      }
      buf += "" + (formatDate(input.year, input.month, input.date));
      if (!input.noTitleLink) {
        buf += "</a>";
      }
      buf += "</div>\n";
      body = buf + body;
    }
    author = void 0;
    if (!input.noAuthor) {
      author = "<div class=\"author\">Posted by " + ("<a href=\"" + config.authorLink + "\">" + config.authorName + "</a>");
      if (config.authorEmail) {
        author += (" &lt;<a href=\"mailto:" + config.authorEmail + "\">") + ("" + config.authorEmail + "</a>&gt;");
      }
      author += "</div>";
    }
    if (!input.noTitleLink) {
      body = body.replace(/<(h\d)>(.*?)<\/\1>/, "<$1><a href=\"" + input.link + "\">$2</a></$1>");
    }
    if (input.anchorHeading !== false) {
      headingCount = -1;
      body = body.replace(/<(h\d)>(.*?)<\/\1>/g, function(match, p1, p2) {
        if (++headingCount > 0) {
          return ("<" + p1 + " class=\"anchor\" id=\"heading_" + headingCount + "\">") + ("<a href=\"#heading_" + headingCount + "\">" + p2 + "</a></" + p1 + ">");
        } else {
          return match;
        }
      });
    }
    body = body.replace(/<(h\d)>/, "<$1 class=\"title\">");
    opts = {
      title: title,
      body: body,
      author: author,
      siteName: config.siteName,
      siteURL: config.siteURL
    };
    if (input.noTitle) {
      opts.title = void 0;
    }
    html = ejs.render(pageTemplate, opts);
    return callback(null, html);
  };

  listYears = function() {
    var year, years;

    years = fs.readdirSync(basedir);
    years = (function() {
      var _i, _len, _results;

      _results = [];
      for (_i = 0, _len = years.length; _i < _len; _i++) {
        year = years[_i];
        if (/\d{4}/.test(year)) {
          _results.push(year);
        }
      }
      return _results;
    })();
    years.sort(function(a, b) {
      return b - a;
    });
    return years;
  };

  listMonths = function(year) {
    var month, months;

    months = fs.readdirSync("" + basedir + "/" + year);
    months = (function() {
      var _i, _len, _results;

      _results = [];
      for (_i = 0, _len = months.length; _i < _len; _i++) {
        month = months[_i];
        if (/\d{2}/.test(month)) {
          _results.push(month);
        }
      }
      return _results;
    })();
    months.sort(function(a, b) {
      return b - a;
    });
    return months;
  };

  listEntries = function(year, month) {
    var file, files;

    files = fs.readdirSync("" + basedir + "/" + year + "/" + month);
    files = (function() {
      var _i, _len, _results;

      _results = [];
      for (_i = 0, _len = files.length; _i < _len; _i++) {
        file = files[_i];
        if (/\.md$/.test(file)) {
          _results.push(file);
        }
      }
      return _results;
    })();
    files.sort(function(a, b) {
      var cmp, intA, intB, match, subintA, subintB;

      intA = parseInt(a);
      intB = parseInt(b);
      cmp = intB - intA;
      if (cmp === 0) {
        subintA = 0;
        subintB = 0;
        if ((match = /^\d+-(\d+)-/.exec(a)) != null) {
          subintA = parseInt(match[1]);
        }
        if ((match = /^\d+-(\d+)-/.exec(b)) != null) {
          subintB = parseInt(match[1]);
        }
        cmp = subintB - subintA;
      }
      if (cmp === 0) {
        cmp = b.localeCompare(a);
      }
      return cmp;
    });
    return files;
  };

  createIndex = function(numRecents) {
    var body, count, date, elapsedTime, file, filepath, files, lex, markdown, match, month, months, part, recentFiles, slug, startTime, title, year, years, _i, _j, _k, _len, _len1, _len2, _ref, _ref1;

    if (numRecents == null) {
      numRecents = 15;
    }
    logMessage("indexing...", {
      noNewline: true
    });
    startTime = new Date().getTime();
    count = 0;
    recentFiles = [];
    years = listYears();
    for (_i = 0, _len = years.length; _i < _len; _i++) {
      year = years[_i];
      if (count >= numRecents) {
        break;
      }
      months = listMonths(year);
      for (_j = 0, _len1 = months.length; _j < _len1; _j++) {
        month = months[_j];
        if (count >= numRecents) {
          break;
        }
        files = listEntries(year, month);
        for (_k = 0, _len2 = files.length; _k < _len2; _k++) {
          file = files[_k];
          match = /^(\d+)(-\d+)?-(.*)\.md$/.exec(file);
          if (match == null) {
            continue;
          }
          filepath = "" + basedir + "/" + year + "/" + month + "/" + file;
          markdown = fs.readFileSync(filepath, {
            encoding: 'utf8'
          });
          lex = marked.Lexer.lex(markdown);
          title = (_ref = findTitleFromLex(lex)) != null ? _ref : '';
          body = marked.Parser.parse(lex);
          date = match[1];
          part = (_ref1 = match[2]) != null ? _ref1 : '';
          slug = match[3];
          recentFiles.push({
            time: new Date("" + year + "-" + month + "-" + date + " 00:00:00").getTime(),
            title: title,
            body: body,
            year: year,
            month: month,
            date: date,
            part: part,
            datepart: date + part,
            slug: slug
          });
          if (++count >= numRecents) {
            break;
          }
        }
      }
    }
    recentInfo = {
      recentFiles: recentFiles,
      generatedTime: new Date().getTime()
    };
    elapsedTime = new Date().getTime() - startTime;
    return logMessage("done (" + elapsedTime + " ms)", {
      noTime: true
    });
  };

  app.get(/^\/(\d{4})\/(\d{2})\/(\d+)(-\d+)?\/(.*)$/, function(req, res) {
    var date, datepart, filepath, month, part, slug, year, _ref;

    year = req.params[0];
    month = req.params[1];
    date = req.params[2];
    part = (_ref = req.params[3]) != null ? _ref : '';
    slug = req.params[4];
    datepart = date + part;
    filepath = "" + basedir + "/" + year + "/" + month + "/" + datepart + "-" + slug + ".md";
    return fs.exists(filepath, function(exists) {
      var staticPath;

      if (!exists) {
        staticPath = "" + basedir + "/" + year + "/" + month + "/" + slug;
        fs.exists(staticPath, function(exists) {
          if (exists) {
            return res.sendfile(staticPath);
          } else {
            return respondWithNotFound(res);
          }
        });
        return;
      }
      return fs.readFile(filepath, {
        encoding: 'utf8'
      }, function(err, markdown) {
        if (err) {
          logMessage(err);
          respondWithServerError(res);
          return;
        }
        return formatPage({
          markdown: markdown,
          link: "/" + year + "/" + month + "/" + datepart + "/" + slug,
          year: year,
          month: month,
          date: date
        }, function(err, html) {
          if (err) {
            logMessage(err);
            respondWithServerError(res);
            return;
          }
          res.setHeader('Content-Type', 'text/html; charset=utf-8');
          return res.send(html);
        });
      });
    });
  });

  app.get('/archives', function(req, res) {
    var markdown, year, years, _i, _len;

    years = listYears();
    markdown = "## Archives\n";
    for (_i = 0, _len = years.length; _i < _len; _i++) {
      year = years[_i];
      markdown += "[" + year + "](/" + year + "/)\n";
    }
    return formatPage({
      markdown: markdown,
      noTitleLink: true,
      noAuthor: true
    }, function(err, html) {
      if (err) {
        logMessage(err);
        respondWithServerError(res);
        return;
      }
      res.setHeader('Content-Type', 'text/html; charset=utf-8');
      return res.send(html);
    });
  });

  app.get(/^\/(\d{4})\/?$/, function(req, res) {
    var markdown, month, months, year, _i, _len;

    year = req.params[0];
    months = listMonths(year);
    markdown = "## Archives for " + year + "\n";
    for (_i = 0, _len = months.length; _i < _len; _i++) {
      month = months[_i];
      markdown += "[" + year + "-" + month + "](/" + year + "/" + month + "/)\n";
    }
    return formatPage({
      markdown: markdown,
      noTitleLink: true,
      noAuthor: true
    }, function(err, html) {
      if (err) {
        logMessage(err);
        respondWithServerError(res);
        return;
      }
      res.setHeader('Content-Type', 'text/html; charset=utf-8');
      return res.send(html);
    });
  });

  app.get(/^\/(\d{4})\/(\d{2})\/?$/, function(req, res) {
    var content, date, datepart, file, filepath, files, lex, markdown, match, month, part, slug, title, year, _i, _len, _ref, _ref1;

    year = req.params[0];
    month = req.params[1];
    files = listEntries(year, month);
    markdown = "## Archives for [" + year + "](/" + year + "/)-" + month + "\n";
    for (_i = 0, _len = files.length; _i < _len; _i++) {
      file = files[_i];
      match = /^(\d+)(-\d+)?-(.*)\.md$/.exec(file);
      date = match[1];
      part = (_ref = match[2]) != null ? _ref : '';
      slug = match[3];
      datepart = date + part;
      filepath = "" + basedir + "/" + year + "/" + month + "/" + file;
      content = fs.readFileSync(filepath, {
        encoding: 'utf8'
      });
      lex = marked.Lexer.lex(content);
      title = (_ref1 = findTitleFromLex(lex)) != null ? _ref1 : '';
      markdown += ("" + (formatDate(year, month, date)) + " ") + ("[" + (title || '(untitled)') + "](/" + year + "/" + month + "/" + datepart + "/" + slug + ")\n");
    }
    return formatPage({
      markdown: markdown,
      title: "Archives for " + year + "-" + month,
      noTitleLink: true,
      noAuthor: true
    }, function(err, html) {
      if (err) {
        logMessage(err);
        respondWithServerError(res);
        return;
      }
      res.setHeader('Content-Type', 'text/html; charset=utf-8');
      return res.send(html);
    });
  });

  app.get(/^\/(\d{4})\/(\d{2})\/[\d-]+\/?/, function(req, res) {
    var month, year;

    year = req.params[0];
    month = req.params[1];
    return res.redirect("/" + year + "/" + month + "/");
  });

  app.get('/recents', function(req, res) {
    var entryUrl, file, markdown, ymd, _i, _len, _ref;

    markdown = "## Recent Entries\n";
    _ref = recentInfo.recentFiles;
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      file = _ref[_i];
      entryUrl = "/" + file.year + "/" + file.month + "/" + file.datepart + "/" + file.slug;
      ymd = formatDate(file.year, file.month, file.date);
      markdown += "" + ymd + " [" + (file.title || '(untitled)') + "](" + entryUrl + ")\n";
    }
    markdown += "\n\n[Archives](/archives)";
    return formatPage({
      markdown: markdown,
      noTitleLink: true,
      noAuthor: true
    }, function(err, html) {
      if (err) {
        logMessage(err);
        respondWithServerError(res);
        return;
      }
      res.setHeader('Content-Type', 'text/html; charset=utf-8');
      return res.send(html);
    });
  });

  app.get('/index.atom', function(req, res) {
    var buf, entryUrl, file, html, title, _i, _len, _ref;

    buf = "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n<feed xmlns=\"http://www.w3.org/2005/Atom\">\n<title>" + config.siteName + "</title>\n<link href=\"" + config.siteURL + "/index.atom\" rel=\"self\" />\n<link href=\"" + config.siteURL + "\" />\n<id>" + (escapeTags(config.siteURL + '/')) + "</id>\n<updated>" + (new Date(recentInfo.generatedTime).toISOString()) + "</updated>";
    _ref = recentInfo.recentFiles;
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      file = _ref[_i];
      html = convertToAbsoluteLinks(file.body, {
        year: file.year,
        month: file.month,
        date: file.date,
        absoluteURL: true
      });
      entryUrl = "" + config.siteURL + "/" + file.year + "/" + file.month + "/" + file.datepart + "/" + file.slug;
      title = file.title;
      if ((title == null) || (title === '')) {
        title = '(untitled)';
      }
      buf += "<entry>\n  <title>" + (escapeTags(title)) + "</title>\n  <link href=\"" + entryUrl + "\" />\n  <id>" + entryUrl + "</id>\n  <updated>" + (new Date(file.time).toISOString()) + "</updated>\n  <content type=\"html\">" + (escapeTags(html)) + "</content>\n  <author>\n    <name>" + (escapeTags(config.authorName)) + "</name>\n    <uri>" + (escapeTags(config.authorLink)) + "</uri>\n";
      if (config.authorEmail) {
        buf += "    <email>" + config.authorEmail + "</email>";
      }
      buf += "\n  </author>\n</entry>";
    }
    buf += "\n</feed>\n";
    res.setHeader('Content-Type', 'text/xml; charset=utf-8');
    return res.send(buf);
  });

  app.get('/', function(req, res) {
    var file, filepath;

    file = recentInfo.recentFiles[0];
    if (file == null) {
      res.setHeader('Content-Type', 'text/plain; charset=utf-8');
      res.send("This is the place where your content will appear.\n\nAdd a first entry like this:\n\nmkdir -p 2013/05\necho \"# Test\\n\\nHello World\" > 2013/05/27-test.md\ngit add .\ngit commit -m \"add test entry\"\ngit push origin master\n\nFinished? Then reload this page slowly.");
      return;
    }
    filepath = "" + basedir + "/" + file.year + "/" + file.month + "/" + file.datepart + "-" + file.slug + ".md";
    return fs.readFile(filepath, {
      encoding: 'utf8'
    }, function(err, markdown) {
      var url;

      if (err) {
        logMessage(err);
        respondWithServerError(res);
        return;
      }
      url = "/" + file.year + "/" + file.month + "/" + file.datepart + "/" + file.slug;
      return formatPage({
        markdown: markdown,
        link: url,
        year: file.year,
        month: file.month,
        date: file.date,
        noTitle: true,
        absolutePath: true
      }, function(err, html) {
        if (err) {
          logMessage(err);
          respondWithServerError(res);
          return;
        }
        res.setHeader('Content-Type', 'text/html; charset=utf-8');
        return res.send(html);
      });
    });
  });

  app.get('*', function(req, res) {
    return respondWithNotFound(res);
  });

  app.use(function(err, req, res, next) {
    console.error(err.stack);
    return next(err);
  });

  createIndex();

  app.listen(PORT);

  logMessage("Server started on port " + PORT);

}).call(this);
