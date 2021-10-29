require 'dependabot/file_fetchers'
require 'dependabot/file_parsers'
require 'dependabot/update_checkers'
require 'dependabot/file_updaters'
require 'dependabot/pull_request_creator'
require 'dependabot/omnibus'
require 'gitlab'
require 'dotenv/load'
require 'byebug'
require 'facets'
require_relative 'vulnerability_fetcher'
require_relative 'dependabot_core'

credentials = [
  {
    'type' => 'git_source',
    'host' => 'github.com',
    'username' => 'x-access-token',
    'password' => ENV['GITHUB_ACCESS_TOKEN']
  }
]

repo_name = 'oshopgiri/dependabot_test'

directory = '/'

branch = 'v1'

package_manager = 'npm_and_yarn'

source = Dependabot::Source.new(
  provider: 'github',
  repo: repo_name,
  directory: directory,
  branch: branch
)

fetcher = Dependabot::FileFetchers.for_package_manager(package_manager).new(
  source: source,
  credentials: credentials
)

files = fetcher.files

parser = Dependabot::FileParsers.for_package_manager(package_manager).new(
  dependency_files: files,
  source: source,
  credentials: credentials
)

dependencies = parser.parse

security_advisories = VulnerabilityFetcher.new(dependencies.select(&:top_level?).map(&:name), package_manager).fetch_advisories

dependencies.select(&:top_level?).each do |dependency|
  security_vulnerabilities = []

  if security_advisories.any?
    security_vulnerabilities = security_advisories[dependency.name].map do |vulnerability|
      Dependabot::SecurityAdvisory.new(
        dependency_name: dependency.name,
        package_manager: package_manager,
        vulnerable_versions: vulnerability[:vulnerable_versions],
        safe_versions: vulnerability[:patched_versions]
      )
    end
  end

  checker = Dependabot::UpdateCheckers.for_package_manager(package_manager).new(
    dependency: dependency,
    dependency_files: files,
    credentials: credentials,
    security_advisories: security_vulnerabilities
  )

  puts "#{dependency.name}\t#{checker.vulnerable?}"
end
