# _plugins/generate_service_areas.rb
# Generates /locations/<city>/ pages from `_config.yml` -> local_keywords
# Pages use layout: default and render a single include (no duplicate head/nav/footer).

require "jekyll/utils"

module Jekyll
  class ServiceAreaPage < Jekyll::Page
    def initialize(site, city, base_segment, defaults)
      @site = site
      @base = site.source

      slug = Jekyll::Utils.slugify(city.to_s)
      @dir  = File.join(base_segment, slug)
      @name = "index.html"

      process(@name)
      read_yaml(File.join(@base, "_layouts"), "default.html")

      # --------------------------
      # Front matter / data (match your event-type pattern)
      # --------------------------
      self.data["layout"]      = "default"
      self.data["city"]        = city
      self.data["city_slug"]   = slug

      site_title = site.config["title"] || "Ohh Snap Photo Booth"
      # Title uses site.location like your event-type pages
      self.data["title"]       ||= "#{city} Photo Booth Rental"
      self.data["description"] ||= "Photo booth rentals for events in #{city}."
      self.data["keywords"]    ||= "photo booth, #{city} photo booth rental, 360 booth, glam booth"

      # OG/hero image key your templates expect
      d = defaults || {}
      self.data["image"]       ||= (d["page_image_1"] || "/assets/img/booth/IMG_9578.jpg")

      # TYPE block (safe defaults — you can override later per city in CloudCannon)
      self.data["type"] ||= {
        "name"        => "#{city} Photo Booths",
        "description" => "Portrait, 360, glam, roaming, and social experiences for events in #{city}.",
        "subtext"     => "Memories for every moment",
        "icon"        => "fas fa-camera",
        "featured"    => "enabled"
      }

      # Page images used by your sections/grids
      self.data["page-image-1"] ||= d["page_image_1"] || "/assets/img/booth/IMG_9578.jpg"
      self.data["page-image-2"] ||= d["page_image_2"] || "/assets/img/ohhsnap/2.jpg"
      self.data["page-image-3"] ||= d["page_image_3"] || "/assets/img/social-booth/I367-FYY0QWTF4GY2X4BX.jpeg"

      # Optional booth image override map (ensure "360" is quoted in YAML)
      self.data["booth-image"] ||= d["booth_image_map"]

      # Banner block (mirrors your event-type usage)
      self.data["banner"] ||= {}
      self.data["banner"]["image"]     ||= d["hero_image"] || "/assets/img/booth/IMG_9578.jpg"
      self.data["banner"]["video"]     ||= nil
      self.data["banner"]["preheading"] ||= "Ohh Snap"
      self.data["banner"]["title"]      ||= "#{city} Photo Booths"
      self.data["banner"]["subtext"]    ||= "Interactive photo & video experiences for unforgettable events."
      self.data["banner"]["cta_link"]   ||= "/contact-ohh-snap-photobooth"
      self.data["banner"]["cta_text"]   ||= "Contact Us"

      # Permalink under /locations/<city>/
      base_segment = base_segment.to_s.strip.empty? ? "locations" : base_segment
      self.data["permalink"] = "/#{base_segment}/#{slug}/"

      # CONTENT: render a single include (inner sections only; no head/nav/footer here)
      partial = d["content_partial"] || "service-area-sections.html"
      self.content = "{% include #{partial} %}"
    end
  end

  class ServiceAreasGenerator < Jekyll::Generator
    safe true
    priority :low

    def generate(site)
      cfg = site.config
      raw = cfg["local_keywords"]
      return if raw.nil?

      # Accept Array or comma-separated String
      cities =
        if raw.is_a?(Array)
          raw
        else
          raw.to_s.split(/\s*,\s*/)
        end

      cities = cities.map { |c| c.to_s.strip }.reject(&:empty?)

      seen = {}
      base_segment = cfg["local_keywords_base"] || "locations"
      defaults     = cfg["local_keywords_defaults"] || {}

      cities.each do |city|
        slug = Jekyll::Utils.slugify(city)
        next if seen[slug]
        seen[slug] = true
        site.pages << ServiceAreaPage.new(site, city, base_segment, defaults)
      end
    end
  end
end
