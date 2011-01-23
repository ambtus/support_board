class GithubController < ApplicationController
  skip_before_filter :verify_authenticity_token
  def push
    render :nothing => true
    payload = JSON.parse(params[:payload])
    CodeCommit.create_commits_from_json(payload)
  end
end
