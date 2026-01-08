# _plugins/jekyll-cdn-assets.rb
require "digest"

module Jekyll
  class CdnAssetsGenerator < Generator
	priority :lowest

	def generate(site)
	  # Config
	  cdn_url = site.config.dig("assets", "cdn", "url") || site.config.dig("cdn", "url")
	  unless cdn_url && !cdn_url.strip.empty?
		Jekyll.logger.warn "CDN Assets Plugin:", "No CDN URL specified in config."
		return
	  end

	  cdn_url        = cdn_url.sub(%r{\/+$}, "")
	  baseurl        = (site.config["baseurl"] || "").to_s
	  site_url       = (site.config["url"] || "").to_s.sub(%r{\/+$}, "")
	  absolute_links = !!(site.config.dig("assets", "cdn", "absolute_links"))

	  Jekyll.logger.info "CDN Assets Plugin:", "Using CDN URL: #{cdn_url}"

	  processed_pages = 0
	  skipped_pages   = 0
	  cache_buster    = generate_cache_buster(site)

	  Jekyll::Hooks.register :pages, :post_render do |page|
		if process_page(page, cdn_url, cache_buster, baseurl, site_url, absolute_links)
		  processed_pages += 1
		else
		  skipped_pages += 1
		end
	  end

	  Jekyll::Hooks.register :documents, :post_render do |doc|
		if process_page(doc, cdn_url, cache_buster, baseurl, site_url, absolute_links)
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

	# Only these extensions will be rewritten to the CDN.
	# You can add/remove extensions here later as needed.
	CDN_ELIGIBLE_EXTS = %w[
	  .png .jpg .jpeg .gif .webp .svg .avif .heic .heif
	  .bmp .tiff
	  .mp4 .webm .mov .m4v .ogg .ogv
	  .mp3 .wav .flac
	  .pdf .zip .rar .7z .tar .gz
	].freeze

	def cdn_eligible?(path)
	  return false if path.nil? || path.empty?

	  clean = path.split("?").first.split("#").first
	  ext   = File.extname(clean).downcase
	  CDN_ELIGIBLE_EXTS.include?(ext)
	end

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

	def process_page(page, cdn_url, cache_buster, baseurl, site_url, absolute_links)
	  return false unless page.output_ext == ".html"
	  html = page.output.to_s
	  return false if html.empty?

	  html = update_asset_paths(html, cdn_url, cache_buster, baseurl, site_url)
	  if absolute_links && !site_url.empty?
		html = absolutize_internal_links(html, site_url, baseurl)
	  end

	  page.output = html
	  true
	end

	# ------------------- CDN rewriting (assets & uploads) -------------------
	def update_asset_paths(content, cdn_url, cache_buster, baseurl = "", site_url = "")
	  out        = content.dup
	  base_clean = baseurl.sub(%r{^/}, "")
	  base_opt   = base_clean.empty? ? "" : "(?:/#{Regexp.escape(base_clean)})?"

	  # Relative "assets|uploads"
	  path_pat = %r{
		(["'(])                       # 1: ' or " or (
		(?!(?:https?:)?//)            # not absolute url
		(\/?#{base_opt}\/?(?:assets|uploads)\/[^"'\s)]+) # 2: path
	  }x

	  out.gsub!(path_pat) do |whole|
		pre  = Regexp.last_match(1)
		path = Regexp.last_match(2)

		# Only rewrite if file extension is CDN-eligible
		unless cdn_eligible?(path)
		  whole
		else
		  normalized = path.sub(%r{^/#{Regexp.escape(base_clean)}\/?}, "").sub(%r{^/}, "")
		  "#{pre}#{cdn_url}/#{normalized}#{cache_buster}"
		end
	  end

	  # Same-origin absolute → CDN
	  unless site_url.empty?
		host    = Regexp.escape(site_url)
		abs_pat = %r{
		  (["'(])
		  (?:#{host})\/
		  ((?:#{Regexp.escape(base_clean)}\/)?(?:assets|uploads)\/[^"'\s)]+)
		}x

		out.gsub!(abs_pat) do |whole|
		  pre  = Regexp.last_match(1)
		  path = Regexp.last_match(2)

		  unless cdn_eligible?(path)
			whole
		  else
			normalized = path.sub(%r{^#{Regexp.escape(base_clean)}\/}, "")
			"#{pre}#{cdn_url}/#{normalized}#{cache_buster}"
		  end
		end
	  end

	  # srcset / imagesrcset (primarily images)
	  out.gsub!(/\b(?:srcset|imagesrcset)\s*=\s*"([^"]+)"/i) do
		list = Regexp.last_match(1)
		rewritten = list.split(",").map(&:strip).map do |item|
		  # same-origin absolute
		  if !site_url.empty? &&
			 item =~ %r{^(?:#{Regexp.escape(site_url)}\/)?((?:#{Regexp.escape(base_clean)}\/)?(?:assets|uploads)\/[^\s]+)(\s+\S+)?$}i
			path = Regexp.last_match(1); desc = Regexp.last_match(2).to_s

			if cdn_eligible?(path)
			  normalized = path.sub(%r{^#{Regexp.escape(base_clean)}\/}, "").sub(%r{^/}, "")
			  "#{cdn_url}/#{normalized}#{cache_buster}#{desc}"
			else
			  item
			end

		  # relative /assets|uploads
		  elsif item =~ %r{^(?!(?:https?:)?//)(\/?(?:#{Regexp.escape(base_clean)}\/)?(?:assets|uploads)\/[^\s]+)(\s+\S+)?$}i
			path = Regexp.last_match(1); desc = Regexp.last_match(2).to_s

			if cdn_eligible?(path)
			  normalized = path.sub(%r{^/#{Regexp.escape(base_clean)}\/?}, "").sub(%r{^/}, "")
			  "#{cdn_url}/#{normalized}#{cache_buster}#{desc}"
			else
			  item
			end
		  else
			item
		  end
		end.join(", ")
		%(srcset="#{rewritten}")
	  end

	  # Inline style url(...) — only rewrite if the referenced file is eligible
	  out.gsub!(/url\(\s*(['"]?)(?!data:|(?:https?:)?\/\/)(\/?(?:#{base_clean}\/)?(?:assets|uploads)\/[^)"']+)\1\s*\)/i) do |whole|
		q = Regexp.last_match(1)
		p = Regexp.last_match(2)

		unless cdn_eligible?(p)
		  whole
		else
		  normalized = p.sub(%r{^/#{Regexp.escape(base_clean)}\/?}, "").sub(%r{^/}, "")
		  %(url(#{q}#{cdn_url}/#{normalized}#{cache_buster}#{q}))
		end
	  end

	  out
	end

	# ------------------- Absolutize internal page links -------------------
	def absolutize_internal_links(content, site_url, baseurl = "")
	  out        = content.dup
	  base_clean = baseurl.sub(%r{^/}, "")

	  # Helper: normalize a page link (avoid assets/uploads)
	  norm = lambda do |path|
		p = path.strip
		return nil if p.empty?
		return nil if p.start_with?("#") ||
					  p.start_with?("mailto:") ||
					  p.start_with?("tel:") ||
					  p.start_with?("javascript:")
		return nil if p =~ %r{^(?:https?:)?//}i
		return nil if p =~ %r{^(?:/?#{Regexp.escape(base_clean)}\/)?(?:assets|uploads)\/}i

		if p.start_with?("/")
		  unless base_clean.empty? || p.start_with?("/#{base_clean}/") || p == "/#{base_clean}"
			p = "/#{base_clean}#{p}"
		  end
		else
		  p = base_clean.empty? ? "/#{p}" : "/#{base_clean}/#{p}"
		end

		p.gsub!(%r{/{2,}}, "/")
		"#{site_url}#{p}"
	  end

	  # href=""
	  out.gsub!(/\bhref\s*=\s*"([^"]+)"/i) do
		orig = Regexp.last_match(1)
		abs  = norm.call(orig)
		%(href="#{abs || orig}")
	  end

	  # action=""
	  out.gsub!(/\baction\s*=\s*"([^"]+)"/i) do
		orig = Regexp.last_match(1)
		abs  = norm.call(orig)
		%(action="#{abs || orig}")
	  end

	  # <link rel="canonical" href="...">
	  out.gsub!(/<link([^>]*?)rel\s*=\s*"(?:canonical)"([^>]*?)href\s*=\s*"([^"]+)"([^>]*)>/i) do
		pre1, pre2, href, post = Regexp.last_match.captures
		abs = norm.call(href)
		%(<link#{pre1}rel="canonical"#{pre2}href="#{abs || href}"#{post}>)
	  end

	  # <meta property="og:url" content="...">
	  out.gsub!(/<meta([^>]*?)property\s*=\s*"(?:og:url)"([^>]*?)content\s*=\s*"([^"]+)"([^>]*)>/i) do
		pre1, pre2, val, post = Regexp.last_match.captures
		abs = norm.call(val)
		%(<meta#{pre1}property="og:url"#{pre2}content="#{abs || val}"#{post}>)
	  end

	  out
	end
  end
end
