module Jekyll
  class DynamicLiquidFrontMatter < Generator
	safe true
	priority :highest

	def generate(site)
	  # Process each page, post, and document in custom collections
	  (site.pages + site.posts.docs + site.collections.values.flat_map(&:docs)).each do |item|
		process_front_matter_with_liquid(item, site)
	  end
	end

	private

	def process_front_matter_with_liquid(item, site)
	  item.data.each do |key, value|
		# Check if value contains unquoted Liquid tags
		if value.is_a?(String) && contains_unquoted_liquid?(value)
		  # Render Liquid tags without needing quotes around them
		  item.data[key] = Liquid::Template.parse(value).render('site' => site.config)
		end
	  end
	end

	# Check if the content contains unquoted Liquid tags
	def contains_unquoted_liquid?(content)
	  content.include?('{{') || content.include?('{%')
	end
  end
end
