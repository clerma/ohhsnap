# _plugins/jekyll-cdn-assets.rb
module Jekyll
  class CdnAssetsGenerator < Generator
	priority :lowest # Run at the very end of the build process

	def generate(site)
	  # Fetch the CDN URL from the config
	  cdn_url = site.config.dig("assets", "cdn", "url")
	  unless cdn_url
		Jekyll.logger.warn "CDN Assets Plugin:", "No CDN URL specified in config."
		return
	  end

	  Jekyll.logger.info "CDN Assets Plugin:", "Using CDN URL: #{cdn_url}"

	  processed_pages = 0
	  skipped_pages = 0

	  # Hook into the post-render stage to process output
	  Jekyll::Hooks.register :pages, :post_render do |page|
		result = process_page(page, cdn_url)
		processed_pages += 1 if result
		skipped_pages += 1 unless result
	  end

	  Jekyll::Hooks.register :documents, :post_render do |document|
		result = process_page(document, cdn_url)
		processed_pages += 1 if result
		skipped_pages += 1 unless result
	  end

	  # Summarize changes at the end of the build
	  Jekyll::Hooks.register :site, :post_write do |_site|
		Jekyll.logger.info "CDN Assets Plugin:", "Processed #{processed_pages} pages/documents."
		Jekyll.logger.info "CDN Assets Plugin:", "Skipped #{skipped_pages} pages/documents."
	  end
	end

	private

	def process_page(page, cdn_url)
	  return false unless page.output_ext == ".html" # Only process HTML pages

	  # Ensure the page has content to process
	  page_output = page.output || ""
	  return false if page_output.empty?

	  # Update asset paths in the page's output
	  page.output = update_asset_paths(page_output, cdn_url)
	  true
	end

	# Replace asset paths in the HTML with the CDN URL prepended
	def update_asset_paths(content, cdn_url)
	  # Ensure content is a string
	  return content unless content.is_a?(String) && !content.empty?

	  # Update all /assets/... paths
	  content.gsub(/(["'(])\/(assets\/[^"')\s]+)/, "\\1#{cdn_url}/\\2")
	end
  end
end
