module Dependabot::Clients::GithubWithRetriesExtension
  def fetch_commit(repo, branch)
    super(repo, branch)
  rescue *Dependabot::FileFetchers::Base::CLIENT_NOT_FOUND_ERRORS
    response = ref(repo, "tags/#{branch}")
    raise Octokit::NotFound if response.is_a?(Array)

    response.object.sha
  end
end

class Dependabot::Clients::GithubWithRetries
  prepend Dependabot::Clients::GithubWithRetriesExtension
end
