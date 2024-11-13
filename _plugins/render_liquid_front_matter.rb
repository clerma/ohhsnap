module Jekyll
  class LiquidInFrontMatter < Generator
	safe true
	priority :highest

	def generate(site)
	  # Process each page, post, and collection document in memory
	  (site.pages + site.posts.docs + site.collections.values.flat_map(&:docs)).each do |item|
		render_liquid_tags(item, site)
	  end
	end

	private

	# Method to render Liquid tags in the front matter after YAML parsing
	def render_liquid_tags(item, site)
	  process_hash(item.data, site)
	end

	# Recursively process each front matter key-value pair
	def process_hash(hash, site)
	  hash.each_key do |key|
		value = hash[key]
		if value.is_a?(String) && contains_liquid_tags?(value)
		  # Render Liquid tags
		  hash[key] = Liquid::Template.parse(value).render(site.site_payload, registers: { site: site })
		elsif value.is_a?(Hash)
		  process_hash(value, site)  # Recursive call for nested hashes
		end
	  end
	end

	# Check if a string contains Liquid syntax
	def contains_liquid_tags?(content)
	  content.include?('{{') || content.include?('{%')
	end
  end
end
