# _plugins/minify_build.rb
# Minify after render (pages/documents) and after write (entire _site).
# Also removes unwanted files from _site.
#
# _config.yml:
# minify_build:
#   enabled: true
#   remove: ["**/*.map", "**/.DS_Store"]
#   skip: ["**/*.min.*", "**/vendor/**"]
#   html: true
#   css:  true
#   js:   false
#   json: true
#   xml:  true
#   svg:  true
#   html_keep_comments: false
#   log:  true
#   debug: false

require "json"

module Jekyll
  module MinifyUtil
    module_function

    def cfg(site)
      {
        "enabled" => true,
        "remove"  => ["**/*.map", "**/.DS_Store"],
        "skip"    => ["**/*.min.*", "**/vendor/**"],
        "html"    => true,
        "css"     => true,
        "js"      => false,
        "json"    => true,
        "xml"     => true,
        "svg"     => true,
        "html_keep_comments" => false,
        "log"     => true,
        "debug"   => false
      }.merge(site.config.fetch("minify_build", {}))
    end

    def log(site, *args)
      return unless cfg(site)["log"]
      Jekyll.logger.info("MinifyBuild:", args.join(" "))
    end

    def debug(site, *args)
      return unless cfg(site)["debug"]
      Jekyll.logger.info("MinifyBuild[debug]:", args.join(" "))
    end

    # ---------- Safe-ish minifiers ----------
    def html(site, s)
      keep = cfg(site)["html_keep_comments"]
      out = s.dup
      out.gsub!(/\r/, "")
      out.gsub!(/\t+/, " ")
      out.gsub!(/ +/, " ")
      unless keep
        out.gsub!(/<!--(?!\[if|\s*\/?ko|<!|\s*#|\s*noindex)[\s\S]*?-->/, "")
      end
      out.gsub!(/>\s+</, "><")
      out.strip
    end

    def css(_site, s)
      out = s.dup
      out.gsub!(/\/\*(?!\!)[\s\S]*?\*\//, "") # drop comments except /*! ... */
      out.gsub!(/\s+/, " ")
      out.gsub!(/\s*([{:;,}])\s*/, '\1')
      out.gsub!(/;}/, "}")
      out.strip
    end

    def js_light(_site, s)
      out = s.dup
      out.gsub!(/\/\*(?!\!)[\s\S]*?\*\//, "")             # block comments (keep /*! */)
      out.gsub!(/(^|[^\S\r\n])\/\/[^\n\r]*/, '\1')        # line comments (heuristic)
      out.gsub!(/[ \t]+/, " ")
      out.gsub!(/\s*([=\+\-*\/%<>!&|?:;,\{\}\(\)\[\]])\s*/, '\1') # safe punctuators
      out.gsub!(/\s*\n+\s*/, "\n")
      out.strip
    end

    def json(_site, s)
      begin
        obj = JSON.parse(s)
        JSON.generate(obj)
      rescue
        s
      end
    end

    def xml(_site, s)
      out = s.dup
      out.gsub!(/<!--[\s\S]*?-->/, "")
      out.gsub!(/>\s+</, "><")
      out.strip
    end

    def svg(_site, s)
      out = s.dup
      out.gsub!(/<!--[\s\S]*?-->/, "")
      out.gsub!(/<\?xml[\s\S]*?\?>/, "")
      out.gsub!(/<!DOCTYPE[\s\S]*?>/i, "")
      out.gsub!(/\s{2,}/, " ")
      out.gsub!(/>\s+</, "><")
      out.strip
    end

    def should_skip?(site, abs_path_under_site_dest)
      cfg = cfg(site)
      return false if cfg["skip"].nil? || cfg["skip"].empty?
      root = site.dest + File::SEPARATOR
      rel  = abs_path_under_site_dest.start_with?(root) ? abs_path_under_site_dest.sub(root, "") : abs_path_under_site_dest
      cfg["skip"].any? { |g| File.fnmatch?(g, rel, File::FNM_PATHNAME | File::FNM_DOTMATCH | File::FNM_EXTGLOB) }
    end
  end

  # -------- Minify page/document output BEFORE writing --------
  Jekyll::Hooks.register [:pages, :documents], :post_render do |item|
    site = item.site
    cfg  = MinifyUtil.cfg(site)
    next unless cfg["enabled"]

    output_ext = (item.respond_to?(:output_ext) ? item.output_ext : File.extname(item.destination("tmp"))).to_s.downcase
    minified = nil

    case output_ext
    when ".html", ".htm"
      minified = MinifyUtil.html(site, item.output) if cfg["html"]
    when ".xml", ".rss", ".atom"
      minified = MinifyUtil.xml(site, item.output) if cfg["xml"]
    when ".json"
      minified = MinifyUtil.json(site, item.output) if cfg["json"]
    end

    if minified && minified != item.output
      item.output = minified
      MinifyUtil.debug(site, "post_render minified:", "#{item.url} (#{output_ext})")
    end
  end

  # -------- Sweep entire _site AFTER writing --------
  class MinifyBuildSweep
    EXT_MAP = {
      html: %w[.html .htm],
      css:  %w[.css],
      js:   %w[.js],
      json: %w[.json],
      xml:  %w[.xml .rss .atom],
      svg:  %w[.svg]
    }

    def self.run(site)
      cfg = MinifyUtil.cfg(site)
      return unless cfg["enabled"]

      removed = remove_files(site, cfg)
      minified = sweep_minify(site, cfg)
      MinifyUtil.log(site, "removed=#{removed}, minified=#{minified}") if cfg["log"]
    end

    def self.remove_files(site, cfg)
      return 0 if cfg["remove"].nil? || cfg["remove"].empty?
      count = 0
      cfg["remove"].each do |pattern|
        Dir.glob(File.join(site.dest, pattern), File::FNM_DOTMATCH).each do |p|
          next unless File.file?(p)
          begin
            File.delete(p)
            count += 1
          rescue => e
            MinifyUtil.log(site, "failed to remove #{p}: #{e.message}")
          end
        end
      end
      count
    end

    def self.sweep_minify(site, cfg)
      enabled_exts = EXT_MAP.each_with_object({}) { |(k, v), h| h[k] = v if cfg[k.to_s] }
      samples = []
      count = 0

      Dir.glob(File.join(site.dest, "**", "*"), File::FNM_DOTMATCH).each do |path|
        next unless File.file?(path)
        next if MinifyUtil.should_skip?(site, path)

        ext = File.extname(path).downcase
        type = enabled_exts.find { |_k, list| list.include?(ext) }&.first
        next unless type

        original = File.binread(path)
        min = case type
              when :html then MinifyUtil.html(site, original)
              when :css  then MinifyUtil.css(site, original)
              when :js   then MinifyUtil.js_light(site, original)
              when :json then MinifyUtil.json(site, original)
              when :xml  then MinifyUtil.xml(site, original)
              when :svg  then MinifyUtil.svg(site, original)
              end

        next if min.nil? || min == original
        File.open(path, "wb") { |f| f.write(min) }
        count += 1
        if samples.size < 15
          rel = path.sub(site.dest + File::SEPARATOR, "")
          samples << rel
        end
      rescue => e
        MinifyUtil.log(site, "failed to minify #{path}: #{e.message}")
      end

      MinifyUtil.log(site, "changed examples:\n  - " + samples.join("\n  - ")) if cfg["log"] && !samples.empty?
      count
    end
  end

  Jekyll::Hooks.register :site, :post_write do |site|
    MinifyUtil.log(site, "post_write hook active")
    MinifyBuildSweep.run(site)
  end
end
