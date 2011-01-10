class GithubController < ApplicationController
  skip_before_filter :verify_authenticity_token
  def push
    payload = JSON.parse(params[:payload])
    commits = payload["commits"]
    commits.each do |commit|
      name = commit["author"]["name"]
      Rails.logger.info "author: #{name}"
      message = commit["message"]
      Rails.logger.info "message: #{message}"
      url = commit["url"]
      Rails.logger.info "url: #{url}"
    end
    repository = payload["repository"]
    time = repository["pushed_at"].to_time
    Rails.logger.info "pushed: #{time}"
    render :nothing => true
  end
end
