require 'spec_helper'
require 'gitlab/build/info'
require 'gitlab/build/gitlab_image'

RSpec.describe Build::Info do
  before do
    stub_default_package_version
    stub_env_var('GITLAB_ALTERNATIVE_REPO', nil)
    stub_env_var('ALTERNATIVE_PRIVATE_TOKEN', nil)
  end

  describe '.package' do
    describe 'shows EE' do
      it 'when ee=true' do
        stub_is_ee_env(true)
        expect(described_class.package).to eq('gitlab-ee')
      end

      it 'when env var is not present, checks VERSION file' do
        stub_is_ee_version(true)
        expect(described_class.package).to eq('gitlab-ee')
      end
    end

    describe 'shows CE' do
      it 'by default' do
        stub_is_ee(false)
        expect(described_class.package).to eq('gitlab-ce')
      end
    end
  end

  describe '.release_version' do
    before do
      allow(Build::Check).to receive(:on_tag?).and_return(true)
      allow_any_instance_of(Omnibus::BuildVersion).to receive(:semver).and_return('12.121.12')
      allow_any_instance_of(Gitlab::BuildIteration).to receive(:build_iteration).and_return('ce.1')
    end

    it 'returns build version and iteration' do
      expect(described_class.release_version).to eq('12.121.12-ce.1')
    end

    it 'defaults to an initial build version when there are no matching tags' do
      allow(Build::Check).to receive(:on_tag?).and_return(false)
      allow(Build::Check).to receive(:is_nightly?).and_return(false)
      allow(Build::Info).to receive(:latest_tag).and_return('')
      allow(Build::Info).to receive(:commit_sha).and_return('ffffffff')
      stub_env_var('CI_PIPELINE_ID', '5555')

      expect(described_class.release_version).to eq('0.0.1+rfbranch.5555.ffffffff-ce.1')
    end

    describe 'with env variables' do
      it 'returns build version and iteration with env variable' do
        stub_env_var('USE_S3_CACHE', 'false')
        stub_env_var('CACHE_AWS_ACCESS_KEY_ID', 'NOT-KEY')
        stub_env_var('CACHE_AWS_SECRET_ACCESS_KEY', 'NOT-SECRET-KEY')
        stub_env_var('CACHE_AWS_BUCKET', 'bucket')
        stub_env_var('CACHE_AWS_S3_REGION', 'moon-west1')
        stub_env_var('CACHE_AWS_S3_ENDPOINT', 'endpoint')
        stub_env_var('CACHE_S3_ACCELERATE', 'sure')

        stub_env_var('NIGHTLY', 'true')
        stub_env_var('CI_PIPELINE_ID', '5555')

        expect(described_class.release_version).to eq('12.121.12-ce.1')
      end
    end
  end

  describe '.docker_tag' do
    before do
      allow(Build::Check).to receive(:on_tag?).and_return(true)
      allow_any_instance_of(Omnibus::BuildVersion).to receive(:semver).and_return('12.121.12')
      allow_any_instance_of(Gitlab::BuildIteration).to receive(:build_iteration).and_return('ce.1')
    end

    it 'returns package version when regular build' do
      expect(described_class.docker_tag).to eq('12.121.12-ce.1')
    end

    it 'respects IMAGE_TAG if set' do
      allow(ENV).to receive(:[]).with('IMAGE_TAG').and_return('foobar')
      expect(described_class.docker_tag).to eq('foobar')
    end
  end

  # Specs for latest_tag and for latest_stable_tag are not really useful since
  # we are stubbing out shell out to git. However, they are showing what we
  # expect to see.
  describe '.latest_tag' do
    context 'when running against stable branches' do
      before do
        stub_is_ee(false)
        stub_env_var('CI_COMMIT_BRANCH', '14-10-stable')
        allow(described_class).to receive(:`).with(/git describe --exact-match/).and_return('12.121.12+rc7.ce.0')
        allow(described_class).to receive(:`).with(/git -c versionsort.prereleaseSuffix=rc tag -l /).and_return('12.121.12+rc7.ce.0')
      end

      it 'calls the shell command with correct arguments' do
        expect(described_class).to receive(:`).with("git -c versionsort.prereleaseSuffix=rc tag -l '14.10*[+.]ce.*' --sort=-v:refname | head -1")

        described_class.latest_tag
      end
    end

    describe 'for CE' do
      before do
        stub_env_var('CI_COMMIT_BRANCH', 'foo-feature-branch')
        stub_is_ee(false)
        allow(described_class).to receive(:`).with("git describe --exact-match 2>/dev/null").and_return('12.121.12+rc7.ce.0')
        allow(described_class).to receive(:`).with("git -c versionsort.prereleaseSuffix=rc tag -l '*[+.]ce.*' --sort=-v:refname | head -1").and_return('12.121.12+rc7.ce.0')
      end

      it 'returns the version of correct edition' do
        expect(described_class.latest_tag).to eq('12.121.12+rc7.ce.0')
      end

      it 'calls the shell command with correct arguments' do
        expect(described_class).to receive(:`).with("git -c versionsort.prereleaseSuffix=rc tag -l '*[+.]ce.*' --sort=-v:refname | head -1")

        described_class.latest_tag
      end
    end

    describe 'for EE' do
      before do
        stub_env_var('CI_COMMIT_BRANCH', 'foo-feature-branch')
        stub_is_ee(true)
        allow(described_class).to receive(:`).with("git -c versionsort.prereleaseSuffix=rc tag -l '*[+.]ee.*' --sort=-v:refname | head -1").and_return('12.121.12+rc7.ee.0')
      end

      it 'returns the version of correct edition' do
        expect(described_class.latest_tag).to eq('12.121.12+rc7.ee.0')
      end
    end
  end

  describe '.latest_stable_tag' do
    describe 'for CE' do
      before do
        stub_env_var('CI_COMMIT_BRANCH', 'foo-feature-branch')
        stub_is_ee(nil)
        allow(described_class).to receive(:`).with("git describe --exact-match 2>/dev/null").and_return('12.121.12+ce.0')
        allow(described_class).to receive(:`).with("git -c versionsort.prereleaseSuffix=rc tag -l '*[+.]ce.*' --sort=-v:refname | awk '!/rc/' | head -1").and_return('12.121.12+ce.0')
      end

      it 'returns the version of correct edition' do
        expect(described_class.latest_stable_tag).to eq('12.121.12+ce.0')
      end
    end

    describe 'for EE' do
      before do
        stub_env_var('CI_COMMIT_BRANCH', 'foo-feature-branch')
        stub_is_ee(true)
        allow(described_class).to receive(:`).with("git -c versionsort.prereleaseSuffix=rc tag -l '*[+.]ee.*' --sort=-v:refname | awk '!/rc/' | head -1").and_return('12.121.12+ee.0')
      end

      it 'returns the version of correct edition' do
        expect(described_class.latest_stable_tag).to eq('12.121.12+ee.0')
      end
    end
  end

  describe '.gitlab_version' do
    describe 'GITLAB_VERSION variable specified' do
      it 'returns passed value' do
        allow(ENV).to receive(:[]).with("GITLAB_VERSION").and_return("9.0.0")
        expect(described_class.gitlab_version).to eq('9.0.0')
      end
    end

    describe 'GITLAB_VERSION variable not specified' do
      it 'returns content of VERSION' do
        allow(File).to receive(:read).with("VERSION").and_return("8.5.6")
        expect(described_class.gitlab_version).to eq('8.5.6')
      end
    end
  end

  describe '.previous_version' do
    it 'detects previous version correctly' do
      allow(described_class).to receive(:`).with("git describe --exact-match 2>/dev/null").and_return('10.4.0+ee.0')
      allow(Build::Info).to receive(:`).with(/git -c versionsort/).and_return("10.4.0+ee.0\n10.3.5+ee.0")

      expect(described_class.previous_version).to eq("10.3.5-ee.0")
    end
  end

  describe '.gitlab_rails repo' do
    describe 'with alternative sources channel selected' do
      before do
        allow(::Gitlab::Version).to receive(:sources_channel).and_return('alternative')
      end

      it 'returns public mirror for GitLab CE' do
        allow(Build::Info).to receive(:package).and_return("gitlab-ce")
        expect(described_class.gitlab_rails_repo).to eq("https://gitlab.com/gitlab-org/gitlab-foss.git")
      end
      it 'returns public mirror for GitLab EE' do
        allow(Build::Info).to receive(:package).and_return("gitlab-ee")
        expect(described_class.gitlab_rails_repo).to eq("https://gitlab.com/gitlab-org/gitlab.git")
      end
    end

    describe 'with default sources channel' do
      before do
        allow(::Gitlab::Version).to receive(:sources_channel).and_return('remote')
      end

      it 'returns dev repo for GitLab CE' do
        allow(Build::Info).to receive(:package).and_return("gitlab-ce")
        expect(described_class.gitlab_rails_repo).to eq("git@dev.gitlab.org:gitlab/gitlabhq.git")
      end
      it 'returns dev repo for GitLab EE' do
        allow(Build::Info).to receive(:package).and_return("gitlab-ee")
        expect(described_class.gitlab_rails_repo).to eq("git@dev.gitlab.org:gitlab/gitlab-ee.git")
      end
    end

    describe 'with security sources channel selected' do
      before do
        allow(::Gitlab::Version).to receive(:sources_channel).and_return('security')
        stub_env_var('CI_JOB_TOKEN', 'CJT')
      end

      it 'returns security mirror for GitLab CE with attached credential' do
        allow(Build::Info).to receive(:package).and_return("gitlab-ce")
        expect(described_class.gitlab_rails_repo).to eq("https://gitlab-ci-token:CJT@gitlab.com/gitlab-org/security/gitlab-foss.git")
      end
      it 'returns security mirror for GitLab EE with attached credential' do
        allow(Build::Info).to receive(:package).and_return("gitlab-ee")
        expect(described_class.gitlab_rails_repo).to eq("https://gitlab-ci-token:CJT@gitlab.com/gitlab-org/security/gitlab.git")
      end
    end
  end

  describe '.deploy_env' do
    before do
      allow(ENV).to receive(:[]).with('AUTO_DEPLOY_ENVIRONMENT').and_return('ad')
      allow(ENV).to receive(:[]).with('PATCH_DEPLOY_ENVIRONMENT').and_return('patch')
      allow(ENV).to receive(:[]).with('RELEASE_DEPLOY_ENVIRONMENT').and_return('r')
    end

    context 'on auto-deploy tag' do
      before do
        allow(Build::Check).to receive(:is_auto_deploy_tag?).and_return(true)
      end
      it 'returns the auto-deploy environment' do
        expect(described_class.deploy_env).to eq('ad')
      end
    end

    context 'on RC tag' do
      before do
        allow(Build::Check).to receive(:is_auto_deploy_tag?).and_return(false)
        allow(Build::Check).to receive(:is_rc_tag?).and_return(true)
      end
      it 'returns the auto-deploy environment' do
        expect(described_class.deploy_env).to eq('patch')
      end
    end

    context 'on latest tag' do
      before do
        allow(Build::Check).to receive(:is_auto_deploy_tag?).and_return(false)
        allow(Build::Check).to receive(:is_rc_tag?).and_return(false)
        allow(Build::Check).to receive(:is_latest_stable_tag?).and_return(true)
      end
      it 'returns the auto-deploy environment' do
        expect(described_class.deploy_env).to eq('r')
      end
    end

    context 'when unable to determine the desired env' do
      before do
        allow(Build::Check).to receive(:is_auto_deploy_tag?).and_return(false)
        allow(Build::Check).to receive(:is_rc_tag?).and_return(false)
        allow(Build::Check).to receive(:is_latest_stable_tag?).and_return(false)
      end
      it 'it returns nil' do
        expect(described_class.deploy_env).to eq(nil)
      end
    end
  end

  describe '.gitlab_rails_ref' do
    context 'with prepend_version true' do
      context 'on tags and stable branches' do
        # On stable branches and tags, generate-facts will not populate version facts
        # So, the content of the VERSION file will be used as-is.
        it 'returns tag with v prefix' do
          allow(File).to receive(:exist?).with(/gitlab-rails_version/).and_return(false)
          allow(File).to receive(:read).with(/VERSION/).and_return('15.7.0')
          expect(described_class.gitlab_rails_ref).to eq('v15.7.0')
        end
      end

      context 'on feature branches' do
        it 'returns commit SHA without any prefix' do
          allow(File).to receive(:exist?).with(/gitlab-rails_version/).and_return(true)
          allow(File).to receive(:read).with(/gitlab-rails_version/).and_return('arandomcommit')
          expect(described_class.gitlab_rails_ref).to eq('arandomcommit')
        end
      end
    end

    context 'with prepend_version false' do
      context 'on tags and stable branches' do
        # On stable branches and tags, generate-facts will not populate version facts
        # So, whatever is on VERSION file, will be used.
        it 'returns tag without v prefix' do
          allow(File).to receive(:exist?).with(/gitlab-rails_version/).and_return(false)
          allow(File).to receive(:read).with(/VERSION/).and_return('15.7.0')
          expect(described_class.gitlab_rails_ref(prepend_version: false)).to eq('15.7.0')
        end
      end

      context 'on feature branches' do
        it 'returns commit SHA without any prefix' do
          allow(File).to receive(:exist?).with(/gitlab-rails_version/).and_return(true)
          allow(File).to receive(:read).with(/gitlab-rails_version/).and_return('arandomcommit')
          expect(described_class.gitlab_rails_ref(prepend_version: false)).to eq('arandomcommit')
        end
      end
    end
  end

  describe '.gcp_release_bucket' do
    it 'returns the release bucket when on a tag' do
      allow(Build::Check).to receive(:on_tag?).and_return(true)
      expect(described_class.gcp_release_bucket).to eq('gitlab-com-pkgs-release')
    end

    it 'returns the build bucket when not on a tag' do
      allow(Build::Check).to receive(:on_tag?).and_return(false)
      expect(described_class.gcp_release_bucket).to eq('gitlab-com-pkgs-builds')
    end
  end
end
