module Jekyll
  class EnhanceSitePayload < Generator
	safe true
	priority :high

	def generate(site)
	  # Example data to add
	  custom_data = {
		"custom_message" => "Hello from the custom payload!",
		"another_variable" => 12345
	  }

	  # Method to merge this data into the existing site_payload
	  site.site_payload["custom_data"] = custom_data
	end
  end
end
def process_liquid(content, site)
  begin
	Liquid::Template.parse(content).render(site.site_payload, registers: {site: site})
  rescue => e
	puts "Error processing Liquid in content: #{content}"
	puts e.message
	content  # Return unmodified content in case of error
  end
end
