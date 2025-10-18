# _plugins/jekyll-cdn-assets.rb
require "digest"

module Jekyll
  class CdnAssetsGenerator < Generator
	priority :lowest

	def generate(site)
	  # Allow either assets.cdn.url or cdn.url
	  cdn_url = site.config.dig("assets", "cdn", "url") || site.config.dig("cdn", "url")
	  unless cdn_url && !cdn_url.strip.empty?
		Jekyll.logger.warn "CDN Assets Plugin:", "No CDN URL specified in config."
		return
	  end
	  cdn_url  = cdn_url.sub(%r{\/+$}, "")                    # strip trailing slash
	  baseurl  = (site.config["baseurl"] || "").to_s          # e.g. "/blog" or ""
	  site_url = (site.config["url"] || "").to_s.sub(%r{\/+$}, "") # e.g. "https://ohhsnapbooth.com"

	  Jekyll.logger.info "CDN Assets Plugin:", "Using CDN URL: #{cdn_url}"

	  processed_pages = 0
	  skipped_pages   = 0

	  cache_buster = generate_cache_buster(site)

	  # Process rendered HTML for both pages and documents
	  Jekyll::Hooks.register :pages, :post_render do |page|
		if process_page(page, cdn_url, cache_buster, baseurl, site_url)
		  processed_pages += 1
		else
		  skipped_pages += 1
		end
	  end
	  Jekyll::Hooks.register :documents, :post_render do |doc|
		if process_page(doc, cdn_url, cache_buster, baseurl, site_url)
		  processed_pages += 1
		else
		  skipped_pages += 1
		end
	  end

	  Jekyll::Hooks.register :site, :post_write do |_|
		Jekyll.logger.info "CDN Assets Plugin:", "Processed #{processed_pages} pages/documents."
		Jekyll.logger.info "CDN Assets Plugin:", "Skipped #{skipped_pages} pages/documents."
	  end
	end

	private

	# Option 2: content hash of static files for cache key
	def generate_cache_buster(site)
	  digest = Digest::MD5.new
	  site.static_files.each do |file|
		next unless File.file?(file.path)
		begin
		  digest.update(File.read(file.path, mode: "rb"))
		rescue
		  # ignore unreadable files
		end
	  end
	  "?v=#{digest.hexdigest}"
	end

	def process_page(page, cdn_url, cache_buster, baseurl, site_url)
	  return false unless page.output_ext == ".html"
	  html = page.output.to_s
	  return false if html.empty?
	  page.output = update_asset_paths(html, cdn_url, cache_buster, baseurl, site_url)
	  true
	end

	# Rewrites:
	#  - "assets/...","/assets/..." and "uploads/...","/uploads/..." (with optional baseurl)
	#  - same-origin absolute URLs: https://site.url/(baseurl/)?(assets|uploads)/...
	#  - srcset / imagesrcset lists
	#  - url(...) inside styles/inline style attributes
	def update_asset_paths(content, cdn_url, cache_buster, baseurl = "", site_url = "")
	  return content unless content.is_a?(String) && !content.empty?

	  out        = content.dup
	  base_clean = baseurl.sub(%r{^/}, "") # "/blog" -> "blog"
	  base_opt   = base_clean.empty? ? "" : "(?:/#{Regexp.escape(base_clean)})?"

	  # 1) Generic quoted or paren-wrapped relative paths (assets|uploads)
	  #    Avoid protocol/host with negative lookahead.
	  path_pat = %r{
		(["'(])                       # 1: opening quote or '('
		(?!(?:https?:)?//)            # not protocol or protocol-relative
		(\/?#{base_opt}\/?(?:assets|uploads)\/[^"'\s)]+) # 2: path
	  }x
	  out.gsub!(path_pat) do
		pre  = Regexp.last_match(1)
		path = Regexp.last_match(2)
		normalized = path
					  .sub(%r{^/#{Regexp.escape(base_clean)}\/?}, "")
					  .sub(%r{^/}, "")
		"#{pre}#{cdn_url}/#{normalized}#{cache_buster}"
	  end

	  # 2) Same-origin absolute URLs -> CDN
	  unless site_url.empty?
		host = Regexp.escape(site_url)
		abs_pat = %r{
		  (["'(])                       # 1: opening quote or '('
		  (?:#{host})\/                 # absolute same-origin
		  ((?:#{Regexp.escape(base_clean)}\/)?(?:assets|uploads)\/[^"'\s)]+) # 2: path after host
		}x
		out.gsub!(abs_pat) do
		  pre  = Regexp.last_match(1)
		  path = Regexp.last_match(2)
		  normalized = path.sub(%r{^#{Regexp.escape(base_clean)}\/}, "")
		  "#{pre}#{cdn_url}/#{normalized}#{cache_buster}"
		end
	  end

	  # 3) srcset / imagesrcset rewriting (comma-delimited with descriptors)
	  out.gsub!(/\b(?:srcset|imagesrcset)\s*=\s*"([^"]+)"/i) do
		list = Regexp.last_match(1)
		rewritten = list.split(",").map(&:strip).map do |item|
		  # same-origin absolute?
		  if !site_url.empty? && item =~ %r{^(?:#{Regexp.escape(site_url)}\/)?((?:#{Regexp.escape(base_clean)}\/)?(?:assets|uploads)\/[^\s]+)(\s+\S+)?$}i
			path = Regexp.last_match(1)
			desc = Regexp.last_match(2).to_s
			normalized = path.sub(%r{^#{Regexp.escape(base_clean)}\/}, "").sub(%r{^/}, "")
			"#{cdn_url}/#{normalized}#{cache_buster}#{desc}"
		  # relative
		  elsif item =~ %r{^(?!(?:https?:)?//)(\/?(?:#{Regexp.escape(base_clean)}\/)?(?:assets|uploads)\/[^\s]+)(\s+\S+)?$}i
			path = Regexp.last_match(1)
			desc = Regexp.last_match(2).to_s
			normalized = path.sub(%r{^/#{Regexp.escape(base_clean)}\/?}, "").sub(%r{^/}, "")
			"#{cdn_url}/#{normalized}#{cache_buster}#{desc}"
		  else
			item
		  end
		end.join(", ")
		%(srcset="#{rewritten}")
	  end

	  # 4) Inline style url(...) occurrences
	  out.gsub!(/url\(\s*(['"]?)(?!data:|(?:https?:)?\/\/)(\/?#{base_opt}\/?(?:assets|uploads)\/[^)"']+)\1\s*\)/i) do
		quote = Regexp.last_match(1)
		path  = Regexp.last_match(2)
		normalized = path.sub(%r{^/#{Regexp.escape(base_clean)}\/?}, "").sub(%r{^/}, "")
		%(url(#{quote}#{cdn_url}/#{normalized}#{cache_buster}#{quote}))
	  end

	  out
	end
  end
end
