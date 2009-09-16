activate :i18n, mount_at_root: false
activate :directory_indexes
activate :autoprefixer
activate :sprockets

if defined?(RailsAssets)
  RailsAssets.load_paths.each do |path|
    sprockets.append_path path
  end
end

activate :cdn do |cdn|
  cdn.filter      = /\.(html|txt|xml)\z/i
  cdn.cloudflare  = {
    client_api_key: ENV.fetch('CLOUDFLARE_API_KEY'),
    email:          'manuel@krautcomputing.com',
    zone:           'fhpeople.org',
    base_urls:      %w(https://fhpeople.org)
  }
end

activate :sitemap_ping do |config|
  config.host        = 'https://fhpeople.org'
  config.after_build = false
end

I18n.exception_handler = ->(exception, locale, key, options) {
  raise "Missing translation key: #{key}, locale: #{locale}, options: #{options}"
}

helpers do
  def current_language
    @current_language ||= current_page.url.match(%r(^/(en|de)/))[1] rescue 'en'
  end

  def en_de(en, de)
    current_language == 'en' ? en : de
  end

  def menu_items
    {
      en_de('Welcome',  'Willkommen') => '',
      en_de('About Us', 'Über Uns')   => 'about-us',
      en_de('Projects', 'Projekte')   => 'projects',
      en_de('Help',     'Helfen')     => 'help',
      en_de('Contact',  'Kontakt')    => 'contact'
    }
  end

  def footer_menu_items
    {
      en_de('Partners',       'Partner')     => 'partners',
      en_de('Legal Notice',   'Impressum')   => 'legal-notice',
      en_de('Privacy Policy', 'Datenschutz') => 'privacy-policy'
    }
  end

  def absolute_or_relative_image_path(image)
    absolute_or_relative_path image_path(image)
  end

  def absolute_or_relative_path(path)
    if build?
      "http://fhpeople.org#{path}"
    else
      path
    end
  end

  def images(path)
    images = Dir[File.expand_path("../source/images/#{path}/*-l.*", __FILE__)].sort

    content_tag :div, class: 'images' do
      [].tap do |elements|
        images.each_with_index do |image, i|
          small_image = image.sub(%r(/(\w+)-l\.), '/\1-s.')
          path_to_image, path_to_small_image = [image, small_image].map do |image|
            image.sub(%r(\A.+/images/), '')
          end
          classes = %w(fancybox)
          classes << 'center' if i % 3 == 1
          file = MiniMagick::Image.open(small_image)
          margin = (200 - file[:width]) / 2
          elements << link_to(image_tag(path_to_small_image), image_path(path_to_image), rel: path, class: classes.join(' '), style: "margin: 0 #{margin}px;")
          elements << '<br>' if i % 3 == 2
        end
      end.join(' ')
    end
  end
end

page '/sitemap.xml', layout: false

set :css_dir,    'stylesheets'
set :js_dir,     'javascripts'
set :images_dir, 'images'

configure :development do
  activate :livereload

  set :debug_assets, true
  set :host,         'http://localhost:4567'
end

configure :build do
  activate :gzip
  activate :asset_hash
  activate :minify_css
  activate :minify_javascript
  activate :imageoptim

  set :host, 'https://fhpeople.org'
end
