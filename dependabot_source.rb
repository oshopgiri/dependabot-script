Dependabot::Clients::GithubWithRetries.class_eval do
  def fetch_commit(repo, branch)
    response = ref(repo, "tags/#{branch}")

    raise Octokit::NotFound if response.is_a?(Array)

    response.object.sha
  end
end
