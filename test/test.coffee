fs         = require 'fs'
assert     = require 'assert'
request    = require 'request'
FeedParser = require 'feedparser'

basedir = "#{__dirname}/notes"

server = require('../server')
  port: 0
  basedir: basedir
  quiet: true  # suppress all output

httpServer = null
baseurl = null

assertSameContent = (got, filename) ->
  expected = fs.readFileSync "#{__dirname}/expected/#{filename}", encoding:'utf8'
  assert.strictEqual got, expected, 'Same content'

describe 'server', ->
  before (done) ->
    httpServer = server.start()
    httpServer.on 'error', (err) ->
      throw err
    httpServer.on 'listening', ->
      baseurl = "http://127.0.0.1:#{httpServer.address().port}"
      done()

  after (done) ->
    server.stop()
    done()

  describe '/', ->
    it 'should return homepage', (done) ->
      request "#{baseurl}/", (err, resp, body) ->
        assert.strictEqual err, null, 'No errors'
        assert.strictEqual resp.statusCode, 200, 'Status code is 200'
        assert.strictEqual resp.headers['content-type'], 'text/html; charset=utf-8', 'content-type'
        assertSameContent body, 'homepage'
        done()

  describe '/recents', ->
    it 'should return recent entries', (done) ->
      request "#{baseurl}/recents", (err, resp, body) ->
        assert.strictEqual err, null, 'No errors'
        assert.strictEqual resp.statusCode, 200, 'Status code is 200'
        assert.strictEqual resp.headers['content-type'], 'text/html; charset=utf-8', 'content-type'
        assertSameContent body, 'recents'
        done()

  describe '/2013/05/29/introducing_bitter_blog_engine', ->
    it 'should return an entry', (done) ->
      request "#{baseurl}/2013/05/29/introducing_bitter_blog_engine", (err, resp, body) ->
        assert.strictEqual err, null, 'No errors'
        assert.strictEqual resp.statusCode, 200, 'Status code is 200'
        assert.strictEqual resp.headers['content-type'], 'text/html; charset=utf-8', 'content-type'
        assertSameContent body, 'introducing_bitter_blog_engine'
        done()

  describe '/2013/05/28/blog_engine_bitter', ->
    it 'should return an entry', (done) ->
      request "#{baseurl}/2013/05/28/blog_engine_bitter", (err, resp, body) ->
        assert.strictEqual err, null, 'No errors'
        assert.strictEqual resp.statusCode, 200, 'Status code is 200'
        assert.strictEqual resp.headers['content-type'], 'text/html; charset=utf-8', 'content-type'
        assertSameContent body, 'blog_engine_bitter'
        done()

  describe '/2013/05/27/markdown_example', ->
    it 'should return an entry', (done) ->
      request "#{baseurl}/2013/05/27/markdown_example", (err, resp, body) ->
        assert.strictEqual err, null, 'No errors'
        assert.strictEqual resp.statusCode, 200, 'Status code is 200'
        assert.strictEqual resp.headers['content-type'], 'text/html; charset=utf-8', 'content-type'
        assertSameContent body, 'markdown_example'
        done()

  describe '/2013/05/26-10/zucchini-bread', ->
    it 'should return an entry', (done) ->
      request "#{baseurl}/2013/05/26-10/zucchini-bread", (err, resp, body) ->
        assert.strictEqual err, null, 'No errors'
        assert.strictEqual resp.statusCode, 200, 'Status code is 200'
        assert.strictEqual resp.headers['content-type'], 'text/html; charset=utf-8', 'content-type'
        assertSameContent body, 'zucchini-bread'
        done()

  describe '/2013/05/26-2/cake_box', ->
    it 'should return an entry', (done) ->
      request "#{baseurl}/2013/05/26-2/cake_box", (err, resp, body) ->
        assert.strictEqual err, null, 'No errors'
        assert.strictEqual resp.statusCode, 200, 'Status code is 200'
        assert.strictEqual resp.headers['content-type'], 'text/html; charset=utf-8', 'content-type'
        assertSameContent body, 'cake_box'
        done()

  describe '/2013/05/26-1/', ->
    it 'should return an entry', (done) ->
      request "#{baseurl}/2013/05/26-1/", (err, resp, body) ->
        assert.strictEqual err, null, 'No errors'
        assert.strictEqual resp.statusCode, 200, 'Status code is 200'
        assert.strictEqual resp.headers['content-type'], 'text/html; charset=utf-8', 'content-type'
        assertSameContent body, 'banana'
        done()

  describe '/2013/05/26/apple', ->
    it 'should return an entry', (done) ->
      request "#{baseurl}/2013/05/26/apple", (err, resp, body) ->
        assert.strictEqual err, null, 'No errors'
        assert.strictEqual resp.statusCode, 200, 'Status code is 200'
        assert.strictEqual resp.headers['content-type'], 'text/html; charset=utf-8', 'content-type'
        assertSameContent body, 'apple'
        done()

  describe '/2013/05/26/', ->
    it 'should return an entry', (done) ->
      request
        url: "#{baseurl}/2013/05/26/"
        followRedirect: false
      , (err, resp, body) ->
        assert.strictEqual err, null, 'No errors'
        assert.strictEqual resp.statusCode, 200, 'Status code is 200'
        assert.strictEqual resp.headers['content-type'], 'text/html; charset=utf-8', 'content-type'
        assertSameContent body, 'day_26'
        done()

  describe '/2013/05/27/', ->
    it 'should redirect to /2013/05/', (done) ->
      request
        url: "#{baseurl}/2013/05/27/"
        followRedirect: false
      , (err, resp, body) ->
        assert.strictEqual err, null, 'No errors'
        assert.strictEqual resp.statusCode, 302, 'Status code is 302'
        assert.strictEqual resp.headers['location'], '/2013/05/', 'content-type'
        done()

  describe '/2013/05/27/abc', ->
    it 'should return 404', (done) ->
      request "#{baseurl}/2013/05/27/abc", (err, resp, body) ->
        assert.strictEqual err, null, 'No errors'
        assert.strictEqual resp.statusCode, 404, 'Status code is 404'
        assert.strictEqual resp.headers['content-type'], 'text/html; charset=utf-8', 'content-type'
        done()

  describe '/archives', ->
    it 'should return a list of years', (done) ->
      request "#{baseurl}/archives", (err, resp, body) ->
        assert.strictEqual err, null, 'No errors'
        assert.strictEqual resp.statusCode, 200, 'Status code is 200'
        assert.strictEqual resp.headers['content-type'], 'text/html; charset=utf-8', 'content-type'
        assertSameContent body, 'archives'
        done()

  describe '/2013/', ->
    it 'should return entries for 2013', (done) ->
      request "#{baseurl}/2013/", (err, resp, body) ->
        assert.strictEqual err, null, 'No errors'
        assert.strictEqual resp.statusCode, 200, 'Status code is 200'
        assert.strictEqual resp.headers['content-type'], 'text/html; charset=utf-8', 'content-type'
        assertSameContent body, '2013'
        done()

  describe '/2013/05/', ->
    it 'should return entries for 2013-05', (done) ->
      request "#{baseurl}/2013/05/", (err, resp, body) ->
        assert.strictEqual err, null, 'No errors'
        assert.strictEqual resp.statusCode, 200, 'Status code is 200'
        assert.strictEqual resp.headers['content-type'], 'text/html; charset=utf-8', 'content-type'
        assertSameContent body, '201305'
        done()

  describe '/2013/05/27/images/winter.jpg', ->
    it 'should return a jpg file', (done) ->
      request
        url: "#{baseurl}/2013/05/27/images/winter.jpg"
        encoding: null
      , (err, resp, body) ->
        assert.strictEqual err, null, 'No errors'
        assert.strictEqual resp.statusCode, 200, 'Status code is 200'
        assert.strictEqual resp.headers['content-type'], 'image/jpeg', 'image/jpeg'
        expected = fs.readFileSync "#{basedir}/2013/05/images/winter.jpg"
        assert.deepEqual body, expected, 'jpg image'
        done()

  describe '/images/fall.png', ->
    it 'should return a png file', (done) ->
      request
        url: "#{baseurl}/images/fall.png"
        encoding: null
      , (err, resp, body) ->
        assert.strictEqual err, null, 'No errors'
        assert.strictEqual resp.statusCode, 200, 'Status code is 200'
        assert.strictEqual resp.headers['content-type'], 'image/png', 'image/png'
        expected = fs.readFileSync "#{basedir}/public/images/fall.png"
        assert.deepEqual body, expected, 'png image'
        done()

  describe '/images/beach.gif', ->
    it 'should return a gif file', (done) ->
      request
        url: "#{baseurl}/images/beach.gif"
        encoding: null
      , (err, resp, body) ->
        assert.strictEqual err, null, 'No errors'
        assert.strictEqual resp.statusCode, 200, 'Status code is 200'
        assert.strictEqual resp.headers['content-type'], 'image/gif', 'image/gif'
        expected = fs.readFileSync "#{basedir}/public/images/beach.gif"
        assert.deepEqual body, expected, 'gif image'
        done()

  describe '/a', ->
    it 'should return 404', (done) ->
      request "#{baseurl}/a", (err, resp, body) ->
        assert.strictEqual err, null, 'No errors'
        assert.strictEqual resp.statusCode, 404, 'Status code is 404'
        assert.strictEqual resp.headers['content-type'], 'text/html; charset=utf-8', 'content-type'
        done()

  describe '/index.atom', ->
    it 'should return Atom feed', (done) ->
      meta = {}
      articles = []
      request "#{baseurl}/index.atom", (err, resp, body) ->
        assert.strictEqual err, null, 'No errors'
        assert.strictEqual resp.statusCode, 200, 'Status code is 200'
        assert.strictEqual resp.headers['content-type'], 'text/xml; charset=utf-8', 'content-type'
        FeedParser.parseString(body)
        .on('error', (err) ->
          assert.fail err, null, 'Error on parsing Atom feed'
        ).on('meta', (m) ->
          meta = m
        ).on('article', (article) ->
          articles.push article
        ).on('end', ->
          assert.strictEqual meta.title, 'MyLittleNotes', 'meta.title'
          assert.strictEqual meta['atom:link'][0]['@'].href,
            'http://notes.kyu-mu.net/index.atom', 'atom:link'
          assert.strictEqual meta['atom:@'].xmlns, 'http://www.w3.org/2005/Atom', 'xmlns'
          assert.strictEqual articles.length, 8, '8 articles'
          assert.strictEqual articles[0].title, 'Bitter blog engine', 'articles[0].title'
          assert (articles[0].description.indexOf('<h1>Bitter blog engine</h1>') isnt -1),
            'articles[0].description'
          assert.strictEqual articles[0].date.getTime(),
            new Date('2013-05-29 00:00:00').getTime(),
            'date'
          assert.strictEqual articles[0].link,
            'http://notes.kyu-mu.net/2013/05/29/introducing_bitter_blog_engine',
            'articles[0].link'
          assert.strictEqual articles[0].author, 'Nao Iizuka'
          assert.strictEqual articles[1].title, 'ブログエンジンBitter'
          assert.strictEqual articles[2].title, 'Markdown Example'
          assert.strictEqual articles[3].title, 'Zucchini Bread'
          assert.strictEqual articles[4].title, 'Cake Box'
          assert.strictEqual articles[5].title, 'Banana'
          assert.strictEqual articles[6].title, 'Apple'
          assert.strictEqual articles[7].title, 'Day 26'
          done()
        )
