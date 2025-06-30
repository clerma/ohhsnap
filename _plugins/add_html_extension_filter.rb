Jekyll::Hooks.register [:pages, :documents], :pre_render do |doc|
  if doc.url &&
     doc.output_ext == ".html" &&
     !doc.url.end_with?(".html") &&
     !doc.url.end_with?("/") &&
     !doc.url.end_with?(".xml") &&
     !doc.url.end_with?(".json")
    doc.data["permalink"] = "#{doc.url}.html"
  end
end

Jekyll::Hooks.register [:pages, :documents], :post_render do |doc|
  next unless doc.output_ext == ".html"

  doc.output.gsub!(/(href|action)=["'](\/[^"'\s?#]+?)["']/) do |match|
    attr = Regexp.last_match(1)
    path = Regexp.last_match(2)

    # Skip if:
    # - already ends with .html, /
    # - is a file (like .css, .js, .png, etc)
    # - is an external URL
    if path =~ /\.(html?|xml|json|css|js|png|jpe?g|webp|svg|gif|ico|woff2?|ttf|eot|otf|mp4|webm|pdf)$/ ||
       path.end_with?("/") ||
       path.start_with?("//") ||
       path.start_with?("http")
      match
    else
      "#{attr}=\"#{path}.html\""
    end
  end
end
