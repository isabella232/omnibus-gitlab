####
# Prometheus server
####

default['monitoring']['prometheus']['enable'] = false
default['monitoring']['prometheus']['monitor_kubernetes'] = true
default['monitoring']['prometheus']['username'] = 'gitlab-prometheus'
default['monitoring']['prometheus']['group'] = 'gitlab-prometheus'
default['monitoring']['prometheus']['uid'] = nil
default['monitoring']['prometheus']['gid'] = nil
default['monitoring']['prometheus']['shell'] = '/bin/sh'
default['monitoring']['prometheus']['home'] = '/var/opt/gitlab/prometheus'
default['monitoring']['prometheus']['log_directory'] = '/var/log/gitlab/prometheus'
default['monitoring']['prometheus']['env_directory'] = '/opt/gitlab/etc/prometheus/env'
default['monitoring']['prometheus']['env'] = {
  'SSL_CERT_DIR' => "#{node['package']['install-dir']}/embedded/ssl/certs/"
}
default['monitoring']['prometheus']['remote_read'] = []
default['monitoring']['prometheus']['remote_write'] = []
default['monitoring']['prometheus']['rules_directory'] = "/var/opt/gitlab/prometheus/rules"
default['monitoring']['prometheus']['scrape_interval'] = 15
default['monitoring']['prometheus']['scrape_timeout'] = 15
default['monitoring']['prometheus']['scrape_configs'] = []
default['monitoring']['prometheus']['external_labels'] = {}
default['monitoring']['prometheus']['listen_address'] = 'localhost:9090'
default['monitoring']['prometheus']['alertmanagers'] = nil
default['monitoring']['prometheus']['consul_service_name'] = 'prometheus'
default['monitoring']['prometheus']['consul_service_meta'] = nil

####
# Prometheus Alertmanager
####

default['monitoring']['alertmanager']['enable'] = false
default['monitoring']['alertmanager']['home'] = '/var/opt/gitlab/alertmanager'
default['monitoring']['alertmanager']['log_directory'] = '/var/log/gitlab/alertmanager'
default['monitoring']['alertmanager']['env_directory'] = '/opt/gitlab/etc/alertmanager/env'
default['monitoring']['alertmanager']['env'] = {
  'SSL_CERT_DIR' => "#{node['package']['install-dir']}/embedded/ssl/certs/"
}
default['monitoring']['alertmanager']['listen_address'] = 'localhost:9093'
default['monitoring']['alertmanager']['admin_email'] = nil
default['monitoring']['alertmanager']['inhibit_rules'] = []
default['monitoring']['alertmanager']['receivers'] = []
default['monitoring']['alertmanager']['routes'] = []
default['monitoring']['alertmanager']['templates'] = []
default['monitoring']['alertmanager']['global'] = {}

####
# Prometheus Node Exporter
####
default['monitoring']['node_exporter']['enable'] = false
default['monitoring']['node_exporter']['home'] = '/var/opt/gitlab/node-exporter'
default['monitoring']['node_exporter']['log_directory'] = '/var/log/gitlab/node-exporter'
default['monitoring']['node_exporter']['env_directory'] = '/opt/gitlab/etc/node-exporter/env'
default['monitoring']['node_exporter']['env'] = {
  'SSL_CERT_DIR' => "#{node['package']['install-dir']}/embedded/ssl/certs/"
}
default['monitoring']['node_exporter']['listen_address'] = 'localhost:9100'
default['monitoring']['node_exporter']['consul_service_name'] = 'node-exporter'
default['monitoring']['node_exporter']['consul_service_meta'] = nil

####
# Redis exporter
###
default['monitoring']['redis_exporter']['enable'] = false
default['monitoring']['redis_exporter']['log_directory'] = "/var/log/gitlab/redis-exporter"
default['monitoring']['redis_exporter']['env_directory'] = '/opt/gitlab/etc/redis-exporter/env'
default['monitoring']['redis_exporter']['env'] = {
  'SSL_CERT_DIR' => "#{node['package']['install-dir']}/embedded/ssl/certs/"
}
default['monitoring']['redis_exporter']['listen_address'] = 'localhost:9121'
default['monitoring']['redis_exporter']['consul_service_name'] = 'redis-exporter'
default['monitoring']['redis_exporter']['consul_service_meta'] = nil

####
# Postgres exporter
###
default['monitoring']['postgres_exporter']['enable'] = false
default['monitoring']['postgres_exporter']['home'] = '/var/opt/gitlab/postgres-exporter'
default['monitoring']['postgres_exporter']['log_directory'] = "/var/log/gitlab/postgres-exporter"
default['monitoring']['postgres_exporter']['listen_address'] = 'localhost:9187'
default['monitoring']['postgres_exporter']['env_directory'] = '/opt/gitlab/etc/postgres-exporter/env'
default['monitoring']['postgres_exporter']['env'] = {
  'SSL_CERT_DIR' => "#{node['package']['install-dir']}/embedded/ssl/certs/"
}
default['monitoring']['postgres_exporter']['sslmode'] = nil
default['monitoring']['postgres_exporter']['per_table_stats'] = false
default['monitoring']['postgres_exporter']['consul_service_name'] = 'postgres-exporter'
default['monitoring']['postgres_exporter']['consul_service_meta'] = nil

####
# PgBouncer exporter
###
default['monitoring']['pgbouncer_exporter']['enable'] = false
default['monitoring']['pgbouncer_exporter']['log_directory'] = "/var/log/gitlab/pgbouncer-exporter"
default['monitoring']['pgbouncer_exporter']['listen_address'] = 'localhost:9188'
default['monitoring']['pgbouncer_exporter']['env_directory'] = '/opt/gitlab/etc/pgbouncer-exporter/env'
default['monitoring']['pgbouncer_exporter']['env'] = {
  'SSL_CERT_DIR' => "#{node['package']['install-dir']}/embedded/ssl/certs/"
}

####
# Gitlab exporter
###
default['monitoring']['gitlab_exporter']['enable'] = false
default['monitoring']['gitlab_exporter']['log_directory'] = '/var/log/gitlab/gitlab-exporter'
default['monitoring']['gitlab_exporter']['env_directory'] = '/opt/gitlab/etc/gitlab-exporter/env'
default['monitoring']['gitlab_exporter']['home'] = "/var/opt/gitlab/gitlab-exporter"
default['monitoring']['gitlab_exporter']['server_name'] = 'webrick'
default['monitoring']['gitlab_exporter']['listen_address'] = 'localhost'
default['monitoring']['gitlab_exporter']['listen_port'] = '9168'
default['monitoring']['gitlab_exporter']['probe_sidekiq'] = true
default['monitoring']['gitlab_exporter']['probe_elasticsearch'] = false
default['monitoring']['gitlab_exporter']['elasticsearch_url'] = nil
default['monitoring']['gitlab_exporter']['elasticsearch_authorization'] = nil
default['monitoring']['gitlab_exporter']['env'] = {
  'MALLOC_CONF' => 'dirty_decay_ms:0,muzzy_decay_ms:0',
  'RUBY_GC_HEAP_INIT_SLOTS' => 80000,
  'RUBY_GC_HEAP_FREE_SLOTS_MIN_RATIO' => 0.055,
  'RUBY_GC_HEAP_FREE_SLOTS_MAX_RATIO' => 0.111,
  'SSL_CERT_DIR' => "#{node['package']['install-dir']}/embedded/ssl/certs/",
  'SSL_CERT_FILE' => "#{node['package']['install-dir']}/embedded/ssl/cert.pem"
}
default['monitoring']['gitlab_exporter']['consul_service_name'] = 'gitlab-exporter'
default['monitoring']['gitlab_exporter']['consul_service_meta'] = nil
default['monitoring']['gitlab_exporter']['tls_enabled'] = false
default['monitoring']['gitlab_exporter']['tls_cert_path'] = nil
default['monitoring']['gitlab_exporter']['tls_key_path'] = nil
default['monitoring']['gitlab_exporter']['prometheus_scrape_scheme'] = 'http'
default['monitoring']['gitlab_exporter']['prometheus_scrape_tls_server_name'] = nil
default['monitoring']['gitlab_exporter']['prometheus_scrape_tls_skip_verification'] = false

# To completely disable prometheus, and all of it's exporters, set to false
default['gitlab']['prometheus-monitoring']['enable'] = true

####
# Grafana
###
default['monitoring']['grafana']['enable'] = false
default['monitoring']['grafana']['log_directory'] = '/var/log/gitlab/grafana'
default['monitoring']['grafana']['home'] = '/var/opt/gitlab/grafana'
default['monitoring']['grafana']['http_addr'] = 'localhost'
default['monitoring']['grafana']['http_port'] = 3000
default['monitoring']['grafana']['admin_password'] = nil
default['monitoring']['grafana']['basic_auth_enabled'] = false
default['monitoring']['grafana']['disable_login_form'] = true
default['monitoring']['grafana']['allow_user_sign_up'] = false
default['monitoring']['grafana']['gitlab_application_id'] = nil
default['monitoring']['grafana']['gitlab_secret'] = nil
default['monitoring']['grafana']['allowed_groups'] = []
default['monitoring']['grafana']['gitlab_auth_sign_up'] = true
default['monitoring']['grafana']['dashboards'] = [
  {
    'name' => 'GitLab Omnibus',
    'orgId' => 1,
    'folder' => 'GitLab Omnibus',
    'type' => 'file',
    'disableDeletion' => true,
    'updateIntervalSeconds' => 600,
    'options' => {
      'path' => '/opt/gitlab/embedded/service/grafana-dashboards',
    },
  }
]
default['monitoring']['grafana']['datasources'] = nil
default['monitoring']['grafana']['env_directory'] = '/opt/gitlab/etc/grafana/env'
default['monitoring']['grafana']['env'] = {
  'SSL_CERT_DIR' => "#{node['package']['install-dir']}/embedded/ssl/certs/"
}
default['monitoring']['grafana']['metrics_enabled'] = false
default['monitoring']['grafana']['metrics_basic_auth_username'] = nil
default['monitoring']['grafana']['metrics_basic_auth_password'] = nil
default['monitoring']['grafana']['alerting_enabled'] = false
default['monitoring']['grafana']['reporting_enabled'] = true
default['monitoring']['grafana']['smtp'] = {
  'enabled' => false,
  'host' => 'localhost:25',
  'user' => nil,
  'password' => nil,
  'cert_file' => nil,
  'key_file' => nil,
  'skip_verify' => false,
  'from_address' => 'admin@grafana.localhost',
  'from_name' => 'Grafana',
  'ehlo_identity' => 'dashboard.example.com',
  'startTLS_policy' => nil
}
default['monitoring']['grafana']['register_as_oauth_app'] = true

# Temporarily retain support for `node['monitoring']['*-exporter'][*]` usage in
# `/etc/gitlab/gitlab.rb`
# TODO: Remove support in 16.0
default['monitoring']['node-exporter'] = Gitlab::Deprecations::NodeAttribute.new(proc { node['monitoring']['node_exporter'].to_h }, "node['monitoring']['node-exporter']", "node['monitoring']['node_exporter']")
default['monitoring']['redis-exporter'] = Gitlab::Deprecations::NodeAttribute.new(proc { node['monitoring']['redis_exporter'].to_h }, "node['monitoring']['redis-exporter']", "node['monitoring']['redis_exporter']")
default['monitoring']['postgres-exporter'] = Gitlab::Deprecations::NodeAttribute.new(proc { node['monitoring']['postgres_exporter'].to_h }, "node['monitoring']['postgres-exporter']", "node['monitoring']['postgres_exporter']")
default['monitoring']['pgbouncer-exporter'] = Gitlab::Deprecations::NodeAttribute.new(proc { node['monitoring']['pgbouncer_exporter'].to_h }, "node['monitoring']['pgbouncer-exporter']", "node['monitoring']['pgbouncer_exporter']")
default['monitoring']['gitlab-exporter'] = Gitlab::Deprecations::NodeAttribute.new(proc { node['monitoring']['gitlab_exporter'].to_h }, "node['monitoring']['gitlab-exporter']", "node['monitoring']['gitlab_exporter']")
