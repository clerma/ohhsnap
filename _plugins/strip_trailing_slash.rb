# _plugins/trailing_slash_redirects.rb
# Generates static redirect pages so /path/ → /path.html (or whatever your canonical is).
# Also provides a Liquid filter to strip trailing slashes when printing links.

require "cgi"
require "set"

module Jekyll
  module StripTrailingSlash
    def strip_trailing_slash(input)
      s = input.to_s
      return s if s.empty? || s == "/"
      s.end_with?("/") ? s.chop : s
    end
  end
end
Liquid::Template.register_filter(Jekyll::StripTrailingSlash)

module Jekyll
  class TrailingSlashRedirectPage < Jekyll::PageWithoutAFile
    def initialize(site, dir, target_url)
      super(site, site.source, dir, "index.html")
      self.data = {
        "layout"    => nil,
        "sitemap"   => false,
        "robots"    => "noindex,follow",
        "permalink" => File.join("/", dir, "/")
      }

      escaped = CGI.escapeHTML(target_url)
      self.content = <<~HTML
        <!doctype html>
        <html lang="en">
          <head>
            <meta charset="utf-8">
            <title>Redirecting…</title>
            <link rel="canonical" href="#{escaped}">
            <meta http-equiv="refresh" content="0; url=#{escaped}">
            <meta name="robots" content="noindex,follow">
          </head>
          <body>
            <p>If you are not redirected automatically, <a href="#{escaped}">click here</a>.</p>
            <script>location.replace("#{escaped}");</script>
          </body>
        </html>
      HTML
    end
  end

  class TrailingSlashRedirects < Jekyll::Generator
    safe true
    priority :low

    def generate(site)
      docs = []
      docs.concat(site.pages)
      site.collections.each_value { |c| docs.concat(c.docs) }

      taken = docs.map { |d| d.url.to_s }.to_set

      docs.each do |doc|
        url = doc.url.to_s

        # Only create a stub for file-like outputs (…/*.html)
        next unless url.end_with?(".html")

        # Build the slash twin: /about.html -> /about/
        slash_url = url.sub(/\.html$/, "/")
        next if slash_url == "/" || taken.include?(slash_url)

        # Directory for the stub (e.g. '/about/' -> 'about')
        dir = slash_url.sub(%r!^/!, "").sub(%r!/$!, "")

        site.pages << TrailingSlashRedirectPage.new(site, dir, url)
      end
    end
  end
end
