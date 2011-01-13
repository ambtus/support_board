class FaqsController < ApplicationController
  def index
    @faqs = params[:rfc] ? Faq.rfc : Faq.faq
    @faqs = Faq.scoped if params[:all]
    @faqs = @faqs.sort_by_vote if params[:by_vote]
  end

  def show
    Rails.logger.debug "show faq session: #{session}"
    @faq = Faq.find(params[:id])
    @details = []
    # special views if still requesting comments
    if @faq.rfc?
      @details = @faq.faq_details
      if current_user.try(:support_volunteer?)
        render :show_volunteer
      elsif current_user || @faq.guest_owner?(session[:authentication_code])
        @details = @details.where(:private => false)
        render :show_commentable
      else # not logged in, can't comment
        @details = @details.where(:private => false)
        render :show_guest
      end
    end
  end

  def edit
    @faq = Faq.find(params[:id])
    if current_user.support_volunteer?
      @faq.faq_details.build(:support_response => true) # create a new empty response template
    else
      flash[:notice] = "Sorry, only support volunteers can edit faqs"
      redirect_to @faq and return
    end
  end

  def update
    @faq = Faq.find(params[:id])
    case params[:commit]
    when "This FAQ answered my question"
      @faq.vote!
    when "Post"
      @faq.post!
    when "Reopen for comments"
      @faq.open_for_comments!(params[:reason])
    when "Add details"
      @faq.comment!(params[:content], params[:official], session[:authentication_code])
    when "Watch this FAQ"
      @faq.watch!(params[:email])
    when "Don't watch this FAQ"
      @faq.unwatch!(params[:email])
    when "Update Faq"
      @faq.update_from_edit!(params[:faq][:position],
                             params[:faq][:title],
                             params[:faq][:content])
    end
    redirect_to @faq and return
  end
end
