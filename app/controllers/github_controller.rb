class GithubController < ApplicationController
  skip_before_filter :verify_authenticity_token
  def push
    payload = JSON.parse(params[:payload])
    render :nothing => true
    pushed_at = payload["repository"]["pushed_at"].to_time
    commits = payload["commits"]
    commits.each do |commit|
      cc = CodeCommit.new
      cc.author = commit["author"]["name"]
      cc.message = commit["message"]
      cc.url = commit["url"]
      cc.pushed_at = pushed_at
      cc.save!
    end
  end
end
