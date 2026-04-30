# _plugins/purge_css_light.rb
# Ruby-only, conservative CSS “purge” after Jekyll writes _site/.
# - Scans _site/**/*.html to collect used .classes and #ids
# - Rewrites configured CSS files under _site/, removing selectors not used
# Notes:
# - VERY conservative: keeps tag-only selectors, @font-face, @keyframes, @supports
# - @media blocks are processed normally; unknown @-rules are kept
# - Comma selectors are filtered (keeps only the parts that are used)
#
# _config.yml:
# purge_css_light:
#   enabled: true
#   html_globs: ["**/*.html"]
#   css_globs:  ["assets/css/*.css"]   # paths are relative to _site/
#   safelist:
#     - "^fa-"         # Font Awesome
#     - "^jarallax"
#     - "^flickity-"
#     - "^swiper-"
#     - "^collapse$"   # Bootstrap
#     - "^show$"
#     - "^modal"
#     - "^dropdown"
#   id_safelist: []     # optional: regexes for IDs
#   log: true

module Jekyll
  class PurgeCssLight
    def initialize(site)
      @site = site
      @cfg = {
        "enabled" => true,
        "html_globs" => ["**/*.html"],
        "css_globs"  => ["assets/css/*.css"],
        "safelist" => ["^fa-", "^jarallax", "^flickity-", "^swiper-"],
        "id_safelist" => [],
        "log" => true
      }.merge(site.config.fetch("purge_css_light", {}))

      @root = site.dest
      @class_set = Set.new
      @id_set    = Set.new
      @class_safelist = (@cfg["safelist"] || []).map { |r| Regexp.new(r) }
      @id_safelist    = (@cfg["id_safelist"] || []).map { |r| Regexp.new(r) }
    end

    def run
      return unless @cfg["enabled"]
      require "set"

      scan_html_for_usage
      changed = purge_css_files
      log "purged_css=#{changed}"
    rescue => e
      log "error: #{e.class} - #{e.message}"
    end

    private

    def log(msg)
      Jekyll.logger.info "PurgeCssLight:", msg if @cfg["log"]
    end

    def html_paths
      @cfg["html_globs"].flat_map { |g| Dir.glob(File.join(@root, g), File::FNM_DOTMATCH) }.uniq.select { |p| File.file?(p) }
    end

    def css_paths
      @cfg["css_globs"].flat_map { |g| Dir.glob(File.join(@root, g), File::FNM_DOTMATCH) }.uniq.select { |p| File.file?(p) }
    end

    # Super-fast class/id extraction (regex), no Nokogiri dependency
    def scan_html_for_usage
      count = 0
      html_paths.each do |p|
        src = File.read(p, mode: "r:bom|utf-8") rescue next
        # class="a b c" or class='a b'
        src.scan(/class\s*=\s*["']([^"']+)["']/i) do |m|
          m.first.split(/\s+/).each { |cls| @class_set << cls.strip unless cls.strip.empty? }
        end
        # id="foo" / id='bar'
        src.scan(/id\s*=\s*["']([^"']+)["']/i) do |m|
          id = m.first.strip
          @id_set << id unless id.empty?
        end
        count += 1
      end
      log "scanned_html=#{count} classes=#{@class_set.size} ids=#{@id_set.size}"
    end

    def class_used?(cls)
      return true if @class_set.include?(cls)
      return true if @class_safelist.any? { |re| cls.match?(re) }
      false
    end

    def id_used?(idv)
      return true if @id_set.include?(idv)
      return true if @id_safelist.any? { |re| idv.match?(re) }
      false
    end

    # Decide if a single selector (no commas) should be kept
    # Keep tag-only selectors conservatively (e.g., body, h1, a:hover)
    def keep_selector?(selector)
      s = selector.strip
      return true if s.start_with?("@") # not expected here, but safe

      # Extract classes & ids in selector
      classes = s.scan(/\.([A-Za-z0-9_-]+)/).flatten
      ids     = s.scan(/#([A-Za-z0-9_-]+)/).flatten

      if classes.empty? && ids.empty?
        # Tag-only (or attribute/pseudo) selector — KEEP conservatively
        return true
      end

      # If ANY referenced class/id is used/safelisted, keep selector
      return true if classes.any? { |c| class_used?(c) }
      return true if ids.any?     { |i| id_used?(i) }

      false
    end

    # Split a selector list by commas, respecting parens (e.g., :not(.x, .y))
    def split_selector_list(sel_text)
      parts = []
      buf = +""
      depth = 0
      sel_text.each_char do |ch|
        if ch == "("
          depth += 1
          buf << ch
        elsif ch == ")"
          depth -= 1 if depth > 0
          buf << ch
        elsif ch == "," && depth == 0
          parts << buf.strip
          buf = +""
        else
          buf << ch
        end
      end
      parts << buf.strip unless buf.strip.empty?
      parts
    end

    def purge_css_files
      changed = 0
      css_paths.each do |path|
        original = File.read(path, mode: "r:bom|utf-8") rescue next
        min = purge_css_text(original)
        next if min.nil? || min == original
        File.open(path, "w") { |f| f.write(min) }
        changed += 1
        log "purged: #{path.sub(@root + File::SEPARATOR, "")}"
      end
      changed
    end

    # Minimal CSS block parser: handles @media nesting and standard rules
    def purge_css_text(css)
      i = 0
      n = css.length
      out = +""
      while i < n
        # Skip whitespace/comments quickly
        if css[i] == "/" && css[i+1] == "*"
          j = css.index("*/", i+2) || n-2
          i = j + 2
          next
        end

        # @-rules
        if css[i] == "@"
          j = css.index("{", i) || n
          head = css[i...j].strip
          if head =~ /\A@media\b/i
            # Parse nested block
            blk, new_i = read_block(css, j)
            filtered = purge_css_text(blk) # recurse inside @media
            out << head << "{" << filtered << "}" unless filtered.strip.empty?
            i = new_i
          else
            # Keep other @-rules whole (@font-face, @keyframes, @supports, etc.)
            blk, new_i = read_block(css, j)
            out << head << "{" << blk << "}"
            i = new_i
          end
          next
        end

        # Normal rule: selector { block }
        j = css.index("{", i)
        break unless j
        sel = css[i...j].strip
        blk, new_i = read_block(css, j)

        # Filter comma-separated selectors
        selectors = split_selector_list(sel)
        kept = selectors.select { |s| keep_selector?(s) }
        unless kept.empty?
          out << kept.join(",") << "{" << blk << "}"
        end

        i = new_i
      end
      out
    end

    # Read balanced { ... } block starting at the '{' index
    def read_block(css, brace_idx)
      depth = 0
      i = brace_idx
      n = css.length
      i += 1 # skip initial '{'
      start = i
      while i < n
        ch = css[i]
        if ch == "/" && css[i+1] == "*"
          j = css.index("*/", i+2) || n-2
          i = j + 2
          next
        elsif ch == "{"
          depth += 1
        elsif ch == "}"
          if depth == 0
            return [css[start...i], i+1]
          else
            depth -= 1
          end
        end
        i += 1
      end
      [css[start...n], n]
    end
  end
end

Jekyll::Hooks.register :site, :post_write do |site|
  Jekyll::PurgeCssLight.new(site).run
end
