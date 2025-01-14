require 'chef_helper'
RSpec.describe 'praefect' do
  let(:chef_run) { ChefSpec::SoloRunner.new(step_into: %w(runit_service env_dir)).converge('gitlab::default') }
  let(:prometheus_grpc_latency_buckets) do
    '[0.001, 0.005, 0.025, 0.1, 0.5, 1.0, 10.0, 30.0, 60.0, 300.0, 1500.0]'
  end

  before do
    allow(Gitlab).to receive(:[]).and_call_original
  end

  context 'when the defaults are used' do
    it_behaves_like 'disabled runit service', 'praefect'
  end

  context 'when praefect is enabled' do
    let(:config_path) { '/var/opt/gitlab/praefect/config.toml' }
    let(:env_dir) { '/opt/gitlab/etc/praefect/env' }
    let(:auth_transitioning) { false }

    before do
      stub_gitlab_rb(praefect: {
                       enable: true,
                       auth_transitioning: auth_transitioning,
                     })
    end

    it 'creates expected directories with correct permissions' do
      expect(chef_run).to create_directory('/var/opt/gitlab/praefect').with(user: 'git', mode: '0700')
    end

    it 'creates a default VERSION file and sends hup to service' do
      expect(chef_run).to create_version_file('Create Praefect version file').with(
        version_file_path: '/var/opt/gitlab/praefect/VERSION',
        version_check_cmd: '/opt/gitlab/embedded/bin/praefect --version'
      )

      expect(chef_run.version_file('Create Praefect version file')).to notify('runit_service[praefect]').to(:hup)
    end

    it 'renders the config.toml' do
      rendered = {
        'auth' => { 'transitioning' => false },
        'listen_addr' => 'localhost:2305',
        'logging' => { 'format' => 'json' },
        'prometheus_listen_addr' => 'localhost:9652',
        'prometheus_exclude_database_from_default_metrics' => true,
        'failover' => { 'enabled' => true },
      }

      expect(chef_run).to render_file(config_path).with_content { |content|
        expect(Tomlrb.parse(content)).to eq(rendered)
      }
      expect(chef_run).not_to render_file(config_path)
      .with_content(%r{\[prometheus\]\s+grpc_latency_buckets =})
    end

    it 'renders the env dir files' do
      expect(chef_run).to render_file(File.join(env_dir, "GITALY_PID_FILE"))
        .with_content('/var/opt/gitlab/praefect/praefect.pid')
      expect(chef_run).to render_file(File.join(env_dir, "WRAPPER_JSON_LOGGING"))
        .with_content('true')
      expect(chef_run).to render_file(File.join(env_dir, "SSL_CERT_DIR"))
        .with_content('/opt/gitlab/embedded/ssl/certs/')
    end

    it 'renders the service run file with wrapper' do
      expect(chef_run).to render_file('/opt/gitlab/sv/praefect/run')
        .with_content('/opt/gitlab/embedded/bin/gitaly-wrapper /opt/gitlab/embedded/bin/praefect')
        .with_content('exec chpst -e /opt/gitlab/etc/praefect/env')
    end

    context 'with defaults overridden with custom configuration' do
      before do
        stub_gitlab_rb(
          {
            praefect: {
              enable: true,
              configuration: {
                listen_addr: 'custom_listen_addr:5432',
                prometheus_listen_addr: 'custom_prometheus_listen_addr:5432',
                logging: {
                  format: 'custom_format',
                  has_no_default: 'should get output'
                },
                prometheus_exclude_database_from_default_metrics: false,
                auth: {
                  transitioning: true
                },
                failover: {
                  enabled: false
                },
                virtual_storage: [
                  {
                    name: 'default',
                    node: [
                      {
                        storage: 'praefect1',
                        address: 'tcp://node2.internal',
                        token: 'praefect2-token'
                      },
                      {
                        storage: 'praefect2',
                        address: 'tcp://node2.internal',
                        token: 'praefect2-token'
                      }
                    ]
                  },
                  {
                    name: 'virtual-storage-2',
                    node: [
                      {
                        storage: 'praefect3',
                        address: 'tcp://node3.internal',
                        token: 'praefect3-token'
                      },
                      {
                        storage: 'praefect4',
                        address: 'tcp://node4.internal',
                        token: 'praefect4-token'
                      }
                    ]
                  }
                ]
              }
            }
          }
        )
      end

      it 'renders config.toml' do
        expect(chef_run).to render_file(config_path).with_content { |content|
          expect(Tomlrb.parse(content)).to eq(
            {
              'auth' => {
                'transitioning' => true
              },
              'failover' => {
                'enabled' => false
              },
              'listen_addr' => 'custom_listen_addr:5432',
              'logging' => {
                'format' => 'custom_format',
                'has_no_default' => 'should get output'
              },
              'prometheus_exclude_database_from_default_metrics' => false,
              'prometheus_listen_addr' => 'custom_prometheus_listen_addr:5432',
              'virtual_storage' => [
                {
                  'name' => 'default',
                  'node' => [
                    {
                      'storage' => 'praefect1',
                      'address' => 'tcp://node2.internal',
                      'token' => 'praefect2-token'
                    },
                    {
                      'storage' => 'praefect2',
                      'address' => 'tcp://node2.internal',
                      'token' => 'praefect2-token'
                    }
                  ]
                },
                {
                  'name' => 'virtual-storage-2',
                  'node' => [
                    {
                      'storage' => 'praefect3',
                      'address' => 'tcp://node3.internal',
                      'token' => 'praefect3-token'
                    },
                    {
                      'storage' => 'praefect4',
                      'address' => 'tcp://node4.internal',
                      'token' => 'praefect4-token'
                    }
                  ]
                }
              ]
            }
          )
        }
      end
    end

    context 'with old key and its new key set' do
      it 'raises an error in the generic case' do
        stub_gitlab_rb(
          {
            praefect: {
              enable: true,
              database_direct_host: 'database_direct_host_legacy',
              configuration: {
                database: {
                  session_pooled: {
                    host: 'database_direct_host_new'
                  }
                }
              }
            }
          }
        )

        expect { chef_run }.to raise_error("Legacy configuration key 'database_direct_host' can't be set when its new key 'configuration.database.session_pooled.host' is set.")
      end

      it 'raises an error with prometheus_grpc_latency_buckets' do
        stub_gitlab_rb(
          {
            praefect: {
              enable: true,
              prometheus_grpc_latency_buckets: '[0, 1, 2]',
              configuration: {
                prometheus: {
                  grpc_latency_buckets: [0, 1, 2]
                }
              }
            }
          }
        )

        expect { chef_run }.to raise_error("Legacy configuration key 'prometheus_grpc_latency_buckets' can't be set when its new key 'configuration.prometheus.grpc_latency_buckets' is set.")
      end

      it 'raises an error with reconciliation_histogram_buckets' do
        stub_gitlab_rb(
          {
            praefect: {
              enable: true,
              reconciliation_histogram_buckets: '[0, 1, 2]',
              configuration: {
                reconciliation: {
                  histogram_buckets: [0, 1, 2]
                }
              }
            }
          }
        )

        expect { chef_run }.to raise_error("Legacy configuration key 'reconciliation_histogram_buckets' can't be set when its new key 'configuration.reconciliation.histogram_buckets' is set.")
      end
    end

    context 'with old virtual_storages and new virtual_storage set' do
      before do
        stub_gitlab_rb(
          {
            praefect: {
              enable: true,
              virtual_storages: {
                default: {
                  nodes: {
                    praefect1: {
                      address: 'tcp://node1.internal',
                      token: "praefect1-token"
                    }
                  }
                }
              },
              configuration: {
                virtual_storage: [
                  {
                    name: 'default',
                    node: [
                      {
                        storage: 'praefect2',
                        address: 'tcp://node2.internal',
                        token: 'praefect2-token'
                      }
                    ]
                  }
                ]
              }
            }
          }
        )
      end

      it 'raises an error' do
        expect { chef_run }.to raise_error("Legacy configuration key 'virtual_storages' can't be set when its new key 'configuration.virtual_storage' is set.")
      end
    end

    context 'with array configured as string' do
      it 'raises an error with reconciliation histogram buckets' do
        stub_gitlab_rb(
          {
            praefect: {
              enable: true,
              configuration: {
                reconciliation: {
                  histogram_buckets: '[0, 1, 2]'
                }
              }
            }
          }
        )

        expect { chef_run }.to raise_error("praefect['configuration'][:reconciliation][:histogram_buckets] must be an array, not a string")
      end

      it 'raises an error with prometheus grpc latency buckets' do
        stub_gitlab_rb(
          {
            praefect: {
              enable: true,
              configuration: {
                prometheus: {
                  grpc_latency_buckets: '[0, 1, 2]'
                }
              }
            }
          }
        )

        expect { chef_run }.to raise_error("praefect['configuration'][:prometheus][:grpc_latency_buckets] must be an array, not a string")
      end
    end

    context 'with custom settings' do
      let(:dir) { nil }
      let(:socket_path) { '/var/opt/gitlab/praefect/praefect.socket' }
      let(:auth_token) { 'secrettoken123' }
      let(:auth_transitioning) { false }
      let(:sentry_dsn) { 'https://my_key:my_secret@sentry.io/test_project' }
      let(:sentry_environment) { 'production' }
      let(:listen_addr) { 'localhost:4444' }
      let(:tls_listen_addr) { 'localhost:5555' }
      let(:certificate_path) { '/path/to/cert.pem' }
      let(:key_path) { '/path/to/key.pem' }
      let(:prom_addr) { 'localhost:1234' }
      let(:separate_database_metrics) { false }
      let(:log_level) { 'debug' }
      let(:log_format) { 'text' }
      let(:primaries) { %w[praefect1 praefect2] }
      let(:virtual_storages) do
        {
          'default' => {
            'default_replication_factor' => 2,
            'nodes' => {
              'praefect1' => { address: 'tcp://node1.internal', token: "praefect1-token" },
              'praefect2' => { address: 'tcp://node2.internal', token: "praefect2-token" },
              'praefect3' => { address: 'tcp://node3.internal', token: "praefect3-token" },
              'praefect4' => { address: 'tcp://node4.internal', token: "praefect4-token" }
            }
          }
        }
      end
      let(:failover_enabled) { true }
      let(:database_host) { 'pg.external' }
      let(:database_port) { 2234 }
      let(:database_user) { 'praefect-pg' }
      let(:database_password) { 'praefect-pg-pass' }
      let(:database_dbname) { 'praefect_production' }
      let(:database_sslmode) { 'require' }
      let(:database_sslcert) { '/path/to/client-cert' }
      let(:database_sslkey) { '/path/to/client-key' }
      let(:database_sslrootcert) { '/path/to/rootcert' }
      let(:database_direct_host) { 'pg.internal' }
      let(:database_direct_port) { 1234 }
      let(:reconciliation_scheduling_interval) { '1m' }
      let(:reconciliation_histogram_buckets) { '[1.0, 2.0]' }
      let(:user) { 'user123' }
      let(:password) { 'password321' }
      let(:ca_file) { '/path/to/ca_file' }
      let(:ca_path) { '/path/to/ca_path' }
      let(:read_timeout) { 123 }
      let(:graceful_stop_timeout) { '3m' }

      before do
        stub_gitlab_rb(praefect: {
                         enable: true,
                         dir: dir,
                         socket_path: socket_path,
                         auth_token: auth_token,
                         auth_transitioning: auth_transitioning,
                         sentry_dsn: sentry_dsn,
                         sentry_environment: sentry_environment,
                         listen_addr: listen_addr,
                         tls_listen_addr: tls_listen_addr,
                         certificate_path: certificate_path,
                         key_path: key_path,
                         prometheus_listen_addr: prom_addr,
                         prometheus_grpc_latency_buckets: prometheus_grpc_latency_buckets,
                         separate_database_metrics: separate_database_metrics,
                         logging_level: log_level,
                         logging_format: log_format,
                         failover_enabled: failover_enabled,
                         virtual_storages: virtual_storages,
                         database_host: database_host,
                         database_port: database_port,
                         database_user: database_user,
                         database_password: database_password,
                         database_dbname: database_dbname,
                         database_sslmode: database_sslmode,
                         database_sslcert: database_sslcert,
                         database_sslkey: database_sslkey,
                         database_sslrootcert: database_sslrootcert,
                         database_direct_host: database_direct_host,
                         database_direct_port: database_direct_port,
                         reconciliation_scheduling_interval: reconciliation_scheduling_interval,
                         reconciliation_histogram_buckets: reconciliation_histogram_buckets,
                         background_verification_verification_interval: '168h',
                         background_verification_delete_invalid_records: true,
                         graceful_stop_timeout: graceful_stop_timeout,
                         # Sanity check that the configuration values get templated out as TOML.
                         configuration: {
                           string_value: 'value',
                           subsection: {
                             array_value: [1, 2]
                           },
                         }
                       }
                      )
      end

      it 'renders the config.toml' do
        expect(chef_run).to render_file(config_path).with_content { |content|
          expect(Tomlrb.parse(content)).to eq(
            {
              'auth' => {
                'token' => 'secrettoken123',
                'transitioning' => false
              },
              'database' => {
                'dbname' => 'praefect_production',
                'host' => 'pg.external',
                'password' => 'praefect-pg-pass',
                'port' => 2234,
                'sslcert' => '/path/to/client-cert',
                'sslkey' => '/path/to/client-key',
                'sslmode' => 'require',
                'sslrootcert' => '/path/to/rootcert',
                'user' => 'praefect-pg',
                'session_pooled' => {
                  'host' => 'pg.internal',
                  'port' => 1234,
                }
              },
              'failover' => {
                'enabled' => true,
              },
              'logging' => {
                'format' => 'text',
                'level' => 'debug'
              },
              'listen_addr' => 'localhost:4444',
              'prometheus' => {
                'grpc_latency_buckets' => [0.001, 0.005, 0.025, 0.1, 0.5, 1.0, 10.0, 30.0, 60.0, 300.0, 1500.0]
              },
              'reconciliation' => {
                'histogram_buckets' => [1.0, 2.0],
                'scheduling_interval' => '1m'
              },
              'background_verification' => {
                'verification_interval' => '168h',
                'delete_invalid_records' => true
              },
              'sentry' => {
                'sentry_dsn' => 'https://my_key:my_secret@sentry.io/test_project',
                'sentry_environment' => 'production'
              },
              'prometheus_listen_addr' => 'localhost:1234',
              'prometheus_exclude_database_from_default_metrics' => false,
              'socket_path' => '/var/opt/gitlab/praefect/praefect.socket',
              'string_value' => 'value',
              'subsection' => {
                'array_value' => [1, 2]
              },
              'tls' => {
                'certificate_path' => '/path/to/cert.pem',
                'key_path' => '/path/to/key.pem'
              },
              'tls_listen_addr' => 'localhost:5555',
              'virtual_storage' => [
                {
                  'name' => 'default',
                  'default_replication_factor' => 2,
                  'node' => [
                    {
                      'address' => 'tcp://node1.internal',
                      'storage' => 'praefect1',
                      'token' => 'praefect1-token'
                    },
                    {
                      'address' => 'tcp://node2.internal',
                      'storage' => 'praefect2',
                      'token' => 'praefect2-token'
                    },
                    {
                      'address' => 'tcp://node3.internal',
                      'storage' => 'praefect3',
                      'token' => 'praefect3-token'
                    },
                    {
                      'address' => 'tcp://node4.internal',
                      'storage' => 'praefect4',
                      'token' => 'praefect4-token'
                    }
                  ]
                }
              ],
              'graceful_stop_timeout' => graceful_stop_timeout
            }
          )
        }
      end

      it 'renders the env dir files correctly' do
        expect(chef_run).to render_file(File.join(env_dir, "WRAPPER_JSON_LOGGING"))
          .with_content('false')
      end

      context 'with virtual_storages as an array' do
        let(:virtual_storages) { [{ name: 'default', 'nodes' => [{ storage: 'praefect1', address: 'tcp://node1.internal', token: "praefect1-token" }] }] }

        it 'raises an error' do
          expect { chef_run }.to raise_error("Praefect virtual_storages must be a hash")
        end
      end

      context 'with nodes of virtual storage as an array' do
        let(:virtual_storages) do
          {
            'default' => {
              'nodes' => {
                'node-1' => {
                  'address' => 'tcp://node1.internal',
                  'token' => 'praefect1-token'
                }
              }
            },
            'external' => {
              'nodes' => [
                {
                  'storage' => 'node-2',
                  'address' => 'tcp://node2.external',
                  'token' => 'praefect2-token'
                }
              ]
            }
          }
        end

        it 'raises an error' do
          expect { chef_run }.to raise_error('Nodes of Praefect virtual storage `external` must be a hash')
        end
      end
    end

    describe 'database migrations' do
      it 'runs the migrations' do
        expect(chef_run).to run_bash('migrate praefect database')
      end

      context 'with auto_migrate off' do
        before { stub_gitlab_rb(praefect: { auto_migrate: false }) }

        it 'skips running the migrations' do
          expect(chef_run).not_to run_bash('migrate praefect database')
        end
      end
    end

    include_examples "consul service discovery", "praefect", "praefect"
  end
end
