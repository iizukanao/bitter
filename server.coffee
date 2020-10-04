fs      = require 'fs'
path    = require 'path'
http    = require 'http'
events  = require 'events'

ejs          = require 'ejs'
marked       = require 'marked'
compression  = require 'compression'
responseTime = require 'response-time'
express      = require 'express'

# Markdown formatting options
marked.setOptions
  gfm       : true
  tables    : true
  breaks    : true
  pedantic  : false
  sanitize  : false
  smartLists: true
  langPrefix: 'lang-'

class BitterServer extends events.EventEmitter
  constructor: (opts) ->
    @constructorOpts = opts

    # Base directory of entries
    @basedir = opts?.basedir ? path.normalize "#{process.cwd()}/notes"

    # Port to listen (default is 1341)
    @port = opts?.port ? process.env.PORT ? 1341

    # Path to config.json
    @configFilename = opts?.configFilename ? "#{@basedir}/config/config.json"

    # EJS template for formatting pages
    @pageTemplateFilename = "#{@basedir}/config/page.ejs"

    # Existence of this file means that
    # the index is needed to be generated again.
    @reindexCheckFilename = "#{@basedir}/reindex-needed"

    # config.json is loaded to this variable
    @config = null

    # Object for storing index
    @recentInfo = {}

    # EJS Template for each page
    @pageTemplate = null

    # Ensure config.json exists
    if not fs.existsSync @configFilename
      console.log "Error: #{@configFilename} does not exist"
      process.exit 1

    err = @loadConfig()
    if err?
      process.exit 1

    @app = express()
    @httpServer = http.createServer @app

    # Log requests
    #@app.use express.logger()

    # gzip/deflate response
    @app.use compression()

    # Add X-Response-Time to response header
    @app.use responseTime()

    # Serve static files in #{@basedir}/public
    @app.use express.static "#{@basedir}/public"

    # Single entry (e.g. /2013/05/26/how_i_learned_javascript)
    @app.get /^\/(\d{4})\/(\d{2})\/(\d+)(-\d+)?\/(.*)$/, (req, res, next) =>
      year  = req.params[0]
      month = req.params[1]
      date  = req.params[2]
      part  = req.params[3] ? ''
      slug  = req.params[4]
      datepart = date + part
      filepath = "#{@basedir}/#{year}/#{month}/#{datepart}-#{slug}.md"
      fs.exists filepath, (exists) =>
        if not exists
          # Find static file that matches URL
          staticPath = "#{@basedir}/#{year}/#{month}/#{slug}"
          fs.stat staticPath, (err, stats) =>
            if err
              @respondWithNotFound res
            else if stats.isDirectory()
              next()  # Will match the next route
            else
              res.sendFile staticPath
          return
        fs.readFile filepath, {encoding:'utf8'}, (err, markdown) =>
          if err
            @logMessage err
            @respondWithServerError res
            return
          @formatPage {
            markdown: markdown
            link    : "/#{year}/#{month}/#{datepart}/#{slug}"
            year    : year
            month   : month
            date    : date
          }, (err, html) =>
            if err
              @logMessage err
              @respondWithServerError res
              return
            res.set 'Content-Type', 'text/html; charset=utf-8'
            res.send html

    # Redirect /2013/05/27/ to /2013/05/ (after matching against the previous route)
    @app.get /^\/(\d{4})\/(\d{2})\/[\d-]+\/?/, (req, res) ->
      year  = req.params[0]
      month = req.params[1]
      res.redirect "/#{year}/#{month}/"

    # List of years
    @app.get '/archives', (req, res) =>
      years = @listYears()
      markdown = """
      ## Archives

      """
      for year in years
        markdown += "[#{year}](/#{year}/)\n"
      @formatPage {
        markdown   : markdown
        noTitleLink: true
        noAuthor   : true
      }, (err, html) =>
        if err
          @logMessage err
          @respondWithServerError res
          return
        res.set 'Content-Type', 'text/html; charset=utf-8'
        res.send html

    # Archives for a year (e.g. /2013/)
    @app.get /^\/(\d{4})\/?$/, (req, res) =>
      year = req.params[0]
      try
        months = @listMonths year
      catch e
        @respondWithNotFound res
        return
      markdown = """
      ## Archives for #{year}

      """
      for month in months
        markdown += "[#{year}-#{month}](/#{year}/#{month}/)\n"
      @formatPage {
        markdown   : markdown
        noTitleLink: true
        noAuthor   : true
      }, (err, html) =>
        if err
          @logMessage err
          @respondWithServerError res
          return
        res.set 'Content-Type', 'text/html; charset=utf-8'
        res.send html

    # Archives for a month (e.g. /2013/05/)
    @app.get /^\/(\d{4})\/(\d{2})\/?$/, (req, res) =>
      year = req.params[0]
      month = req.params[1]
      try
        files = @listEntries year, month
      catch e
        @respondWithNotFound res
        return
      markdown = """
      ## Archives for [#{year}](/#{year}/)-#{month}

      """
      for file in files
        match = /^(\d+)(-\d+)?-(.*)\.md$/.exec file
        date = match[1]
        part = match[2] ? ''
        slug = match[3]
        datepart = date + part

        filepath = "#{@basedir}/#{year}/#{month}/#{file}"
        content = fs.readFileSync filepath, {encoding:'utf8'}
        lex = marked.Lexer.lex(content)
        title = @findTitleFromLex(lex) ? ''
        markdown += "#{@formatDate year, month, date} " + \
        "[#{title or '(untitled)'}](/#{year}/#{month}/#{datepart}/#{slug})\n"
      @formatPage {
        markdown   : markdown
        title      : "Archives for #{year}-#{month}"
        noTitleLink: true
        noAuthor   : true
      }, (err, html) =>
        if err
          @logMessage err
          @respondWithServerError res
          return
        res.set 'Content-Type', 'text/html; charset=utf-8'
        res.send html

    # Recent entries
    @app.get '/recents', (req, res) =>
      numRecents = @config.numRecents ? @recentInfo.recentFiles.length
      markdown = """
      ## Recent Entries

      """
      for file in @recentInfo.recentFiles[...numRecents]
        entryUrl = "/#{file.year}/#{file.month}/#{file.datepart}/#{file.slug}"
        ymd = @formatDate file.year, file.month, file.date
        markdown += "#{ymd} [#{file.title or '(untitled)'}](#{entryUrl})\n"
      markdown += "\n\n[Archives](/archives)"
      @formatPage {
        markdown   : markdown
        noTitleLink: true
        noAuthor   : true
      }, (err, html) =>
        if err
          @logMessage err
          @respondWithServerError res
          return
        res.set 'Content-Type', 'text/html; charset=utf-8'
        res.send html

    # Atom feed
    @app.get '/index.atom', (req, res) =>
      buf = """
      <?xml version="1.0" encoding="utf-8"?>
      <feed xmlns="http://www.w3.org/2005/Atom">
      <title>#{@config.siteName}</title>
      <link href="#{@config.siteURL}/index.atom" rel="self" />
      <link href="#{@config.siteURL}" />
      <id>#{@escapeTags @config.siteURL + '/'}</id>
      <updated>#{new Date(@recentInfo.generatedTime).toISOString()}</updated>
      """
      numRecents = @config.numRecents ? @recentInfo.recentFiles.length
      for file in @recentInfo.recentFiles[...numRecents]
        html = @convertToAbsoluteLinks file.body, {
          year       : file.year
          month      : file.month
          date       : file.date
          absoluteURL: true
        }
        entryUrl = "#{@config.siteURL}/#{file.year}/#{file.month}/#{file.datepart}/#{file.slug}"
        title = file.title
        if (not title?) or (title is '')
          title = '(untitled)'
        buf += """
      <entry>
        <title>#{@escapeTags title}</title>
        <link href="#{entryUrl}" />
        <id>#{entryUrl}</id>
        <updated>#{new Date(file.time).toISOString()}</updated>
        <content type="html">#{@escapeTags html}</content>
        <author>
          <name>#{@escapeTags @config.authorName}</name>
          <uri>#{@escapeTags @config.authorLink}</uri>

        """
        if @config.authorEmail
          buf += "    <email>#{@config.authorEmail}</email>"
        buf += """

        </author>
      </entry>
        """
      buf += "\n</feed>\n"
      res.set 'Content-Type', 'text/xml; charset=utf-8'
      res.send buf

    # Homepage
    @app.get '/', (req, res) =>
      if @config.homepage is 'recents'
        @serveRecents req, res
      else
        @serveMostRecentEntry req, res

    # Not found
    @app.get '*', (req, res) =>
      @respondWithNotFound res

    # Log unhandled errors
    @app.use (err, req, res, next) ->
      console.error err.stack
      next err

    if opts?.autoStart
      @start()

  start: (callback) ->
    if fs.existsSync @reindexCheckFilename
      fs.unlink @reindexCheckFilename

    # Watch reindex-needed to be created
    fs.watchFile @reindexCheckFilename, (curr, prev) =>
      if curr.nlink > 0
        fs.unlink @reindexCheckFilename, =>
          @createIndex()
          @emit 'updateIndex'

    # Watch config.json to be updated
    fs.watchFile @configFilename, (curr, prev) =>
      err = @loadConfig()
      if not err?
        @logMessage "loaded #{path.basename @configFilename}"
        @createIndex()

    # Load page template and watch it for change
    @pageTemplate = fs.readFileSync @pageTemplateFilename, {encoding:'utf8'}
    fs.watchFile @pageTemplateFilename, (curr, prev) =>
      fs.readFile @pageTemplateFilename, {encoding:'utf8'}, (err, data) =>
        if err
          @logMessage "#{@pageTemplateFilename} read error: #{err}"
          return
        @pageTemplate = data
        @logMessage "loaded #{path.basename @pageTemplateFilename}"

    @createIndex()
    @httpServer.listen @port
    @httpServer.on 'listening', =>
      @logMessage "Server started on port #{@httpServer.address().port}"

  stop: ->
    fs.unwatchFile @reindexCheckFilename
    fs.unwatchFile @configFilename
    fs.unwatchFile @pageTemplateFilename

    @httpServer.close =>
      @logMessage "Server closed"

  # Log message to stdout
  logMessage: (str, opts) ->
    if @constructorOpts?.quiet
      return
    buf = ''
    if not opts?.noTime
      d = new Date
      buf += "[#{d.toDateString()} #{d.toLocaleTimeString()}] "
    buf += str
    if not opts?.noNewline
      buf += "\n"
    process.stdout.write buf

  monthNames: [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ]

  formatDate: (year, month, date) ->
    "#{@monthNames[month-1]} #{parseInt date}, #{year}"

  # Obfuscate email address
  obfuscateEmail: (str) ->
    buf = ''
    for i in [0...str.length]
      buf += "&##{str.charCodeAt i};"
    buf

  # Escape HTML/XML tags
  escapeTags: (str) ->
    str.replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')

  # Load config.json
  loadConfig: ->
    try
      @config = JSON.parse fs.readFileSync @configFilename
    catch e
      @logMessage "#{@configFilename} read error: #{e}"
      return e
    @config.siteURL = @config.siteURL.replace /\/$/, ''
    @config.authorEmail = @obfuscateEmail @config.authorEmail
    null  # no error

  # 500 Server Error
  respondWithServerError: (res) ->
    markdown = """
    ## Server Error

    Please try again later.

    """
    @formatPage {markdown:markdown, noTitleLink:true, noAuthor:true}, (err, html) =>
      if err
        @logMessage err
        res.status(500).send('Server error')
        return
      res.set 'Content-Type', 'text/html; charset=utf-8'
      res.status(500).send(html)

  # 404 Not Found
  respondWithNotFound: (res) ->
    markdown = """
    ## Not Found

    The requested document was not found.

    """
    @formatPage {markdown:markdown, noTitleLink:true, noAuthor:true}, (err, html) =>
      if err
        @logMessage err
        @respondWithServerError res
        return
      res.set 'Content-Type', 'text/html; charset=utf-8'
      res.status(404).send(html)

  # Find first heading from lex object
  findTitleFromLex: (lex) ->
    for component in lex
      if component.type is 'heading'
        return component.text
    null  # not found

  # Convert links in HTML to absolute URL
  #   html (string): HTML
  #   params: {
  #     year  (string): entry's year
  #     month (string): entry's month
  #     date  (string): entry's date
  #     absoluteURL (boolean): If true, prepend @config.siteURL
  #                            If false, start with /
  #   }
  convertToAbsoluteLinks: (html, params) ->
    html = html.replace /(<a href|<img src)="(.*?)"/g, (match, p1, p2) =>
      p2 = p2.replace /^\.\.\/(?!\.\.)/g, "/#{params.year}/#{params.month}/"
      p2 = p2.replace /^\.\.\/\.\.\/(?!\.\.)/g, "/#{params.year}/"
      p2 = p2.replace /^\.\.\/\.\.\/\.\.\/(?!\.\.)/g, "/"
      if p2.indexOf('://') is -1
        if p2[0] isnt '/'
          p2 = "/#{params.year}/#{params.month}/#{params.date}/#{p2}"
        if params.absoluteURL
          p2 = "#{@config.siteURL}#{p2}"
      "#{p1}=\"#{p2}\""
    html

  # Format Markdown content into HTML
  formatPage: (input, callback) ->
    lex = marked.Lexer.lex(input.markdown)

    # Title
    title = input.title ? null
    if not title?
      lexTitle = @findTitleFromLex lex
      if lexTitle?
        title = lexTitle
    if not title?
      title = '(untitled)'

    body = marked.Parser.parse(lex)
    # Convert relative links to absolute
    if input.absolutePath or input.absoluteURL
      body = @convertToAbsoluteLinks body, input

    # Date
    if input.year? and input.month? and input.date?
      buf = "<div class=\"date\">"
      if not input.noTitleLink
        buf += "<a href=\"#{input.link}\">"
      buf += "#{@formatDate input.year, input.month, input.date}"
      if not input.noTitleLink
        buf += "</a>"
      buf += "</div>\n"
      body = buf + body

    # Author
    author = undefined
    if not input.noAuthor
      author = "<div class=\"author\">Posted by " + \
      "<a href=\"#{@config.authorLink}\">#{@config.authorName}</a>"
      if @config.authorEmail
        author += " &lt;<a href=\"mailto:#{@config.authorEmail}\">" + \
        "#{@config.authorEmail}</a>&gt;"
      author += "</div>"

    # Link title
    if not input.noTitleLink
      body = body.replace /<(h\d)([^>]*)>(.*?)<\/\1>/, \
      "<$1$2><a href=\"#{input.link}\">$3</a></$1>"

    # Create anchors for headings
    if input.anchorHeading isnt false
      headingCount = -1
      body = body.replace /<(h\d)([^>]*)>(.*?)<\/\1>/g, (match, p1, p2, p3) ->
        if ++headingCount > 0
          "<#{p1}#{p2} class=\"anchor\" id=\"heading_#{headingCount}\">" + \
          "<a href=\"#heading_#{headingCount}\">#{p3}</a></#{p1}>"
        else
          match
    body = body.replace /<(h\d)([^>]*)>/, "<$1$2 class=\"title\">"
    body = body.replace /(<h\d) id="[^"]*"/g, '$1'

    # Object to be passed to template
    opts =
      title   : title
      body    : body
      author  : author
      siteName: @config.siteName
      siteURL : @config.siteURL
    if input.noTitle
      opts.title = undefined

    # Apply page.ejs to page contents
    html = ejs.render @pageTemplate, opts
    callback null, html

  # List all years
  listYears: ->
    years = fs.readdirSync @basedir
    years = (year for year in years when /\d{4}/.test year)
    years.sort (a, b) -> b - a
    years

  # List all months for the given year
  listMonths: (year) ->
    months = fs.readdirSync "#{@basedir}/#{year}"
    months = (month for month in months when /\d{2}/.test month)
    months.sort (a, b) -> b - a
    months

  # List all entries for the given year/month
  listEntries: (year, month) ->
    files = fs.readdirSync "#{@basedir}/#{year}/#{month}"
    files = (file for file in files when /\.md$/.test file)
    files.sort (a, b) ->
      intA = parseInt a
      intB = parseInt b
      cmp = intB - intA
      if cmp is 0
        subintA = 0
        subintB = 0
        if (match = /^\d+-(\d+)-/.exec a)?
          subintA = parseInt match[1]
        if (match = /^\d+-(\d+)-/.exec b)?
          subintB = parseInt match[1]
        cmp = subintB - subintA
      if cmp is 0
        cmp = b.localeCompare a
      cmp
    files

  # Scan entries and update index
  createIndex: (numRecents) ->
    if not numRecents?
      numRecents = @config.numRecents ? 15
      if @config.numHomepageRecents?
        numRecents = Math.max @config.numHomepageRecents, numRecents
    @logMessage "indexing...", noNewline:true
    startTime = new Date().getTime()
    count = 0
    recentFiles = []
    years = @listYears()
    for year in years
      break if count >= numRecents
      months = @listMonths year
      for month in months
        break if count >= numRecents
        files = @listEntries year, month
        for file in files
          match = /^(\d+)(-\d+)?-(.*)\.md$/.exec file
          if not match?
            continue

          filepath = "#{@basedir}/#{year}/#{month}/#{file}"
          markdown = fs.readFileSync filepath, {encoding:'utf8'}
          lex = marked.Lexer.lex(markdown)
          title = @findTitleFromLex(lex) ? ''
          body = marked.Parser.parse(lex)
          date = match[1]
          part = match[2] ? ''
          slug = match[3]

          recentFiles.push
            time    : new Date("#{year}-#{month}-#{date} 00:00:00").getTime()
            title   : title
            body    : body
            year    : year
            month   : month
            date    : date
            part    : part
            datepart: date + part
            slug    : slug
          if ++count >= numRecents
            break

    # Hold index in recentInfo
    @recentInfo =
      recentFiles: recentFiles
      generatedTime: new Date().getTime()

    elapsedTime = new Date().getTime() - startTime
    @logMessage "done (#{elapsedTime} ms)", noTime:true

  # Serve homepage in recents style
  serveRecents: (req, res) ->
    numRecents = @config.numHomepageRecents ? @config.numRecents ? 5
    markdown = ''
    for file in @recentInfo.recentFiles[...numRecents]
      entryUrl = "/#{file.year}/#{file.month}/#{file.datepart}/#{file.slug}"
      markdown += "[#{file.title or '(untitled)'}](#{entryUrl})\n"
    @formatPage {
      markdown   : markdown
      noTitleLink: true
      noAuthor   : true
      noTitle    : true
    }, (err, html) =>
      if err
        @logMessage err
        @respondWithServerError res
        return
      res.set 'Content-Type', 'text/html; charset=utf-8'
      res.send html

  # Show the most recent entry on homepage
  serveMostRecentEntry: (req, res) ->
    file = @recentInfo.recentFiles[0]
    if not file?
      res.set 'Content-Type', 'text/plain; charset=utf-8'
      # Empty content message
      res.send """
      This is the place where your content will appear.

      Add a first entry like this:

      mkdir -p 2013/05
      echo "# Test\\n\\nHello World" > 2013/05/27-test.md
      git add .
      git commit -m "add test entry"
      git push origin master

      Finished? Then reload this page slowly.
      """
      return
    filepath = "#{@basedir}/#{file.year}/#{file.month}/#{file.datepart}-#{file.slug}.md"
    fs.readFile filepath, {encoding:'utf8'}, (err, markdown) =>
      if err
        @logMessage err
        @respondWithServerError res
        return
      url = "/#{file.year}/#{file.month}/#{file.datepart}/#{file.slug}"
      @formatPage {
        markdown    : markdown
        link        : url
        year        : file.year
        month       : file.month
        date        : file.date
        noTitle     : true
        absolutePath: true
      }, (err, html) =>
        if err
          @logMessage err
          @respondWithServerError res
          return
        res.set 'Content-Type', 'text/html; charset=utf-8'
        res.send html

module.exports = BitterServer

if not module.parent?
  # This script is being run directly
  new BitterServer autoStart:true
