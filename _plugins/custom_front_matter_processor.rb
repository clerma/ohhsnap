require 'yaml'

module Jekyll
  class CustomFrontMatterProcessor < Generator
	safe true
	priority :highest

	def generate(site)
	  site.pages.each { |page| process_front_matter(page, site) }
	  site.posts.docs.each { |post| process_front_matter(post, site) } if site.respond_to?(:posts)
	  site.collections.each_value do |collection|
		collection.docs.each { |doc| process_front_matter(doc, site) }
	  end
	end

	private

	# Process and render Liquid tags in front matter
	def process_front_matter(item, site)
	  content = File.read(item.path)
	  if content =~ /\A---\s*\n(.*?)\n---\s*\n/m
		front_matter_content = Regexp.last_match(1)
		# Render Liquid tags in the front matter
		rendered_front_matter = Liquid::Template.parse(front_matter_content).render(site.site_payload, registers: { site: site })
		# Parse the rendered front matter as YAML
		parsed_front_matter = YAML.safe_load(rendered_front_matter)
		# Update the item data with the processed front matter
		item.data.merge!(parsed_front_matter)
	  end
	end
  end
end
