module Jekyll
  class LiquidFrontMatterRenderer < Generator
	safe true
	priority :high

	def generate(site)
	  site.pages.each { |page| render_liquid_in_front_matter(page, site) }
	  site.posts.docs.each { |post| render_liquid_in_front_matter(post, site) } if site.respond_to?(:posts)
	end

	private

	def render_liquid_in_front_matter(item, site)
	  process_hash(item.data, site)
	end

	def process_hash(hash, site)
	  hash.each_key do |key|
		value = hash[key]
		if value.is_a?(String) && contains_liquid_tags?(value)
		  hash[key] = process_liquid(value, site)
		elsif value.is_a?(Hash)
		  process_hash(value, site)  # Recursively process nested hashes
		end
	  end
	end

	def process_liquid(content, site)
	  Liquid::Template.parse(content).render(site.site_payload, registers: {site: site})
	end

	def contains_liquid_tags?(content)
	  content.include?('{{') || content.include?('{%')
	end
  end
end
