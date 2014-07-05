gem 'rails_config'
gem 'whenever'
gem 'kaminari'
gem 'parallel'
gem 'faraday'
gem 'httpclient'
gem 'dalli', :require => 'active_support/cache/dalli_store'
gem 'activeadmin', github: 'gregbell/active_admin'
gem 'kakurenbo'
gem 'nokogiri'

gem_group :deployment do
  # deploy
  gem 'net-ssh', '2.7.0'
  gem 'capistrano', '~> 3.2.0'
  gem 'capistrano-rbenv', '~> 2.0'
  gem 'capistrano-bundler', '~> 1.1.2'
  gem 'capistrano-rails', '~> 1.1'

  # puppet
  gem 'supply_drop', :git => 'git@github.com:thoward/supply_drop.git', :branch => 'cap_3'
  gem 'puppet'
  gem 'librarian-puppet'
end

gem_group :development do
  gem 'seed_dump'
end

gem_group :development, :test do
  gem 'rspec-rails'
  gem 'spring-commands-rspec'
  gem 'pry'
  gem 'pry-coolline'
  gem 'pry-rails'
  gem 'hirb-unicode'
  gem 'database_rewinder'
  gem 'factory_girl_rails'

  if RUBY_VERSION >= '2.0.0'
    gem 'pry-byebug'
  else
    gem 'pry-debugger'
    gem 'pry-remote'
  end

  gem 'webmock'
  gem 'vcr'
  gem 'bullet'
  gem 'bundler-auto-update'
  gem 'metric_fu', :git => 'https://github.com/metricfu/metric_fu.git'
  gem 'rubocop'
  gem 'simplecov'
  gem 'simplecov-rcov-text'
  gem 'compass'
end

git :init
git add: "."
git commit: %Q{ -m 'Initial commit' }

run_bundle

generate 'rails_config:install'
generate 'rspec:install'
generate 'active_admin:install'

run 'bundle binstubs rspec-core'

lib 'slow_query_logger.rb', <<'CODE'
class SlowQueryLogger < Arproxy::Base
  def initialize(slow_ms)
    @slow_ms = slow_ms
  end

  def execute(sql, name=nil)
    result = nil
    ms = Benchmark.ms { result = super(sql, name) }
    if ms >= @slow_ms
      Rails.logger.info "Slow(#{ms.to_i}ms): #{sql}"
    end
    result
  end
end

Arproxy.configure do |config|
  config.use SlowQueryLogger, 1000
end
CODE

environment 'config.cache_store = :dalli_store', env: 'production'

initializer 'session_store.rb', <<-CODE
Rails.application.config.session_store ActionDispatch::Session::CacheStore, :expire_after => 20.minutes
CODE

environment 'WebMock.allow_net_connect!', env: 'test'

environment env: 'test' do
  VCR.configure do |c|
    config.cassette_library_dir = 'spec/vcr'
    config.hook_into :webmock
    config.allow_http_connections_when_no_cassette = true
  end
end
