require 'digest/md5'

require 'rack/cache'

MemeCaptainWeb::Application.configure do
  heroku = !ENV['HEROKU'].blank?
  # Settings specified here will take precedence over those in config/application.rb

  # Code is not reloaded between requests
  config.cache_classes = true

  # Full error reports are disabled and caching is turned on
  config.consider_all_requests_local = false
  config.action_controller.perform_caching = true

  config.middleware.insert_before(Rack::Cache, Rack::Rewrite) do
    r301 %r{/([a-f0-9]+\.(?:gif|jpg|png))$}, 'http://v1.memecaptain.com/$1'
    r301 %r{/((?:g|i)\?.+)}, 'http://v1.memecaptain.com/$1'
  end

  if heroku
    config.serve_static_assets = true
    config.middleware.insert_before ActionDispatch::Static, Rack::Deflater
    config.static_cache_control = "public, max-age=31536000"
  else
    config.serve_static_assets = false
  end

  # Compress JavaScripts and CSS
  config.assets.compress = true

  # Don't fallback to assets pipeline if a precompiled asset is missed
  config.assets.compile = false

  # Generate digests for assets URLs
  config.assets.digest = true

  # Defaults to nil and saved in location specified by config.assets.prefix
  # config.assets.manifest = YOUR_PATH

  # Specifies the header that your server uses for sending files
  # config.action_dispatch.x_sendfile_header = "X-Sendfile" # for apache
  # config.action_dispatch.x_sendfile_header = 'X-Accel-Redirect' # for nginx

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  # config.force_ssl = true

  # See everything in the log (default is :info)
  # config.log_level = :debug

  # Prepend all log lines with the following tags
  # config.log_tags = [ :subdomain, :uuid ]

  # Use a different logger for distributed setups
  # config.logger = ActiveSupport::TaggedLogging.new(SyslogLogger.new)

  # Use a different cache store in production
  # config.cache_store = :mem_cache_store

  # Enable serving of images, stylesheets, and JavaScripts from an asset server
  config.action_controller.asset_host = proc { |asset|
    "http://a#{Digest::MD5.hexdigest(asset).to_i(16) % 3}.memecaptain.com"
  }

  # Precompile additional assets (application.js, application.css, and all non-JS/CSS are already added)
  # config.assets.precompile += %w( search.js )

  # Disable delivery errors, bad email addresses will be ignored
  # config.action_mailer.raise_delivery_errors = false

  # Enable threaded mode
  # config.threadsafe!

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation can not be found)
  config.i18n.fallbacks = true

  # Send deprecation notices to registered listeners
  config.active_support.deprecation = :notify

  # Log the query plan for queries taking more than this (works
  # with SQLite, MySQL, and PostgreSQL)
  # config.active_record.auto_explain_threshold_in_seconds = 0.5

  if ENV['MEMCACHE_SERVERS']
    config.cache_store = :dalli_store

    config.action_dispatch.rack_cache = {
        :metastore => Dalli::Client.new,
        :entitystore => 'file:tmp/cache/rack/body',
        :allow_reload => false
    }
  end

end
