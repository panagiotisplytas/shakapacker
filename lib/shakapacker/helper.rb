module Shakapacker::Helper
  # Returns the current Shakapacker instance.
  # Could be overridden to use multiple Shakapacker
  # configurations within the same app (e.g. with engines).
  def current_shakapacker_instance
    Shakapacker.instance
  end

  # Computes the relative path for a given Shakapacker asset.
  # Returns the relative path using manifest.json and passes it to path_to_asset helper.
  # This will use path_to_asset internally, so most of their behaviors will be the same.
  #
  # Example:
  #
  #   <%= asset_pack_path 'calendar.css' %> # => "/packs/calendar-1016838bab065ae1e122.css"
  def asset_pack_path(name, **options)
    path_to_asset(current_shakapacker_instance.manifest.lookup!(name), options)
  end

  # Computes the absolute path for a given Shakapacker asset.
  # Returns the absolute path using manifest.json and passes it to url_to_asset helper.
  # This will use url_to_asset internally, so most of their behaviors will be the same.
  #
  # Example:
  #
  #   <%= asset_pack_url 'calendar.css' %> # => "http://example.com/packs/calendar-1016838bab065ae1e122.css"
  def asset_pack_url(name, **options)
    url_to_asset(current_shakapacker_instance.manifest.lookup!(name), options)
  end

  # Computes the relative path for a given Shakapacker image with the same automated processing as image_pack_tag.
  # Returns the relative path using manifest.json and passes it to path_to_asset helper.
  # This will use path_to_asset internally, so most of their behaviors will be the same.
  def image_pack_path(name, **options)
    resolve_path_to_image(name, **options)
  end

  # Computes the absolute path for a given Shakapacker image with the same automated
  # processing as image_pack_tag. Returns the relative path using manifest.json
  # and passes it to path_to_asset helper. This will use path_to_asset internally,
  # so most of their behaviors will be the same.
  def image_pack_url(name, **options)
    resolve_path_to_image(name, **options.merge(protocol: :request))
  end

  # Creates an image tag that references the named pack file.
  #
  # Example:
  #
  #  <%= image_pack_tag 'application.png', size: '16x10', alt: 'Edit Entry' %>
  #  <img alt='Edit Entry' src='/packs/application-k344a6d59eef8632c9d1.png' width='16' height='10' />
  #
  #  <%= image_pack_tag 'picture.png', srcset: { 'picture-2x.png' => '2x' } %>
  #  <img srcset= "/packs/picture-2x-7cca48e6cae66ec07b8e.png 2x" src="/packs/picture-c38deda30895059837cf.png" >
  def image_pack_tag(name, **options)
    if options[:srcset] && !options[:srcset].is_a?(String)
      options[:srcset] = options[:srcset].map do |src_name, size|
        "#{resolve_path_to_image(src_name)} #{size}"
      end.join(", ")
    end

    image_tag(resolve_path_to_image(name), options)
  end

  # Creates a link tag for a favicon that references the named pack file.
  #
  # Example:
  #
  #  <%= favicon_pack_tag 'mb-icon.png', rel: 'apple-touch-icon', type: 'image/png' %>
  #  <link href="/packs/mb-icon-k344a6d59eef8632c9d1.png" rel="apple-touch-icon" type="image/png" />
  def favicon_pack_tag(name, **options)
    favicon_link_tag(resolve_path_to_image(name), options)
  end

  # Creates script tags that reference the js chunks from entrypoints when using split chunks API,
  # as compiled by webpack per the entries list in package/environments/base.js.
  # By default, this list is auto-generated to match everything in
  # app/javascript/entrypoints/*.js and all the dependent chunks. In production mode, the digested reference is automatically looked up.
  # See: https://webpack.js.org/plugins/split-chunks-plugin/
  #
  # Example:
  #
  #   <%= javascript_pack_tag 'calendar', 'map', 'data-turbolinks-track': 'reload' %> # =>
  #   <script src="/packs/vendor-16838bab065ae1e314.chunk.js" data-turbolinks-track="reload" defer="true"></script>
  #   <script src="/packs/calendar~runtime-16838bab065ae1e314.chunk.js" data-turbolinks-track="reload" defer="true"></script>
  #   <script src="/packs/calendar-1016838bab065ae1e314.chunk.js" data-turbolinks-track="reload" defer="true"></script>
  #   <script src="/packs/map~runtime-16838bab065ae1e314.chunk.js" data-turbolinks-track="reload" defer="true"></script>
  #   <script src="/packs/map-16838bab065ae1e314.chunk.js" data-turbolinks-track="reload" defer="true"></script>
  #
  # DO:
  #
  #   <%= javascript_pack_tag 'calendar', 'map' %>
  #
  # DON'T:
  #
  #   <%= javascript_pack_tag 'calendar' %>
  #   <%= javascript_pack_tag 'map' %>
  def javascript_pack_tag(*names, defer: true, async: false, **options)
    if @javascript_pack_tag_loaded
      raise "To prevent duplicated chunks on the page, you should call javascript_pack_tag only once on the page. " \
      "Please refer to https://github.com/shakacode/shakapacker/blob/main/README.md#view-helpers-javascript_pack_tag-and-stylesheet_pack_tag for the usage guide"
    end

    append_javascript_pack_tag(*names, defer: defer, async: async)
    sync = sources_from_manifest_entrypoints(javascript_pack_tag_queue[:sync], type: :javascript)
    async = sources_from_manifest_entrypoints(javascript_pack_tag_queue[:async], type: :javascript) - sync
    deferred = sources_from_manifest_entrypoints(javascript_pack_tag_queue[:deferred], type: :javascript) - sync - async

    @javascript_pack_tag_loaded = true

    capture do
      concat javascript_include_tag(*async, **options.dup.tap { |o| o[:async] = true })
      concat "\n" if async.any? && deferred.any?
      concat javascript_include_tag(*deferred, **options.dup.tap { |o| o[:defer] = true })
      concat "\n" if sync.any? && deferred.any?
      concat javascript_include_tag(*sync, **options)
    end
  end

  # Creates a link tag, for preloading, that references a given Shakapacker asset.
  # In production mode, the digested reference is automatically looked up.
  # See: https://developer.mozilla.org/en-US/docs/Web/HTML/Preloading_content
  #
  # Example:
  #
  #   <%= preload_pack_asset 'fonts/fa-regular-400.woff2' %> # =>
  #   <link rel="preload" href="/packs/fonts/fa-regular-400-944fb546bd7018b07190a32244f67dc9.woff2" as="font" type="font/woff2" crossorigin="anonymous">
  def preload_pack_asset(name, **options)
    if self.class.method_defined?(:preload_link_tag)
      preload_link_tag(current_shakapacker_instance.manifest.lookup!(name), options)
    else
      raise "You need Rails >= 5.2 to use this tag."
    end
  end

  # Creates link tags that reference the css chunks from entrypoints when using split chunks API,
  # as compiled by webpack per the entries list in package/environments/base.js.
  # By default, this list is auto-generated to match everything in
  # app/javascript/entrypoints/*.js and all the dependent chunks. In production mode, the digested reference is automatically looked up.
  # See: https://webpack.js.org/plugins/split-chunks-plugin/
  #
  # Examples:
  #
  #   <%= stylesheet_pack_tag 'calendar', 'map' %> # =>
  #   <link rel="stylesheet" media="screen" href="/packs/3-8c7ce31a.chunk.css" />
  #   <link rel="stylesheet" media="screen" href="/packs/calendar-8c7ce31a.chunk.css" />
  #   <link rel="stylesheet" media="screen" href="/packs/map-8c7ce31a.chunk.css" />
  #
  #   When using the webpack-dev-server, CSS is inlined so HMR can be turned on for CSS,
  #   including CSS modules
  #   <%= stylesheet_pack_tag 'calendar', 'map' %> # => nil
  #
  # DO:
  #
  #   <%= stylesheet_pack_tag 'calendar', 'map' %>
  #
  # DON'T:
  #
  #   <%= stylesheet_pack_tag 'calendar' %>
  #   <%= stylesheet_pack_tag 'map' %>
  def stylesheet_pack_tag(*names, **options)
    return "" if Shakapacker.inlining_css?

    requested_packs = sources_from_manifest_entrypoints(names, type: :stylesheet)
    appended_packs = available_sources_from_manifest_entrypoints(@stylesheet_pack_tag_queue || [], type: :stylesheet)

    @stylesheet_pack_tag_loaded = true

    stylesheet_link_tag(*(requested_packs | appended_packs), **options)
  end

  def append_stylesheet_pack_tag(*names)
    if @stylesheet_pack_tag_loaded
      raise "You can only call append_stylesheet_pack_tag before stylesheet_pack_tag helper. " \
      "Please refer to https://github.com/shakacode/shakapacker/blob/main/README.md#view-helper-append_javascript_pack_tag-prepend_javascript_pack_tag-and-append_stylesheet_pack_tag for the usage guide"
    end

    @stylesheet_pack_tag_queue ||= []
    @stylesheet_pack_tag_queue.concat names

    # prevent rendering Array#to_s representation when used with <%= … %> syntax
    nil
  end

  def append_javascript_pack_tag(*names, defer: true, async: false)
    update_javascript_pack_tag_queue(defer: defer, async: async) do |hash_key|
      javascript_pack_tag_queue[hash_key] |= names
    end
  end

  def prepend_javascript_pack_tag(*names, defer: true, async: false)
    update_javascript_pack_tag_queue(defer: defer, async: async) do |hash_key|
      javascript_pack_tag_queue[hash_key].unshift(*names)
    end
  end

  private

    def update_javascript_pack_tag_queue(defer:, async:)
      if @javascript_pack_tag_loaded
        raise "You can only call #{caller_locations(1..1).first.base_label} before javascript_pack_tag helper. " \
        "Please refer to https://github.com/shakacode/shakapacker/blob/main/README.md#view-helper-append_javascript_pack_tag-prepend_javascript_pack_tag-and-append_stylesheet_pack_tag for the usage guide"
      end

      # When both async and defer are specified, async takes precedence per HTML5 spec
      hash_key = if async
        :async
      elsif defer
        :deferred
      else
        :sync
      end
      yield(hash_key)

      # prevent rendering Array#to_s representation when used with <%= … %> syntax
      nil
    end

    def javascript_pack_tag_queue
      @javascript_pack_tag_queue ||= {
        async: [],
        deferred: [],
        sync: []
      }
    end

    def sources_from_manifest_entrypoints(names, type:)
      names.map { |name| current_shakapacker_instance.manifest.lookup_pack_with_chunks!(name.to_s, type: type) }.flatten.uniq
    end

    def available_sources_from_manifest_entrypoints(names, type:)
      names.map { |name| current_shakapacker_instance.manifest.lookup_pack_with_chunks(name.to_s, type: type) }.flatten.compact.uniq
    end

    def resolve_path_to_image(name, **options)
      path = name.starts_with?("static/") ? name : "static/#{name}"
      path_to_asset(current_shakapacker_instance.manifest.lookup!(path), options)
    rescue
      path_to_asset(current_shakapacker_instance.manifest.lookup!(name), options)
    end
end
