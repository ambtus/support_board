class FaqsController < ApplicationController
  def index
    @faqs = params[:rfc] ? Faq.rfc : Faq.faq
    @faqs = Faq.scoped if params[:all]
  end

  def show
    Rails.logger.debug "show faq session: #{session}"
    @faq = Faq.find(params[:id])
    # special view if still requesting comments
    if @faq.rfc?
      @details = @faq.faq_details
      @details = @details.where(:private => false) if !current_user.try(:support_volunteer?)
      render :show_rfc and return
    end
  end

  def new
    if !current_user.try(:support_volunteer?)
      flash[:error] = "Sorry, only support volunteers can create faqs"
      redirect_to support_path and return
    end
    @faq = Faq.new
    render :edit
  end

  def edit
    @faq = Faq.find(params[:id])
    if !current_user.try(:support_volunteer?)
      flash[:error] = "Sorry, only support volunteers can edit faqs"
      redirect_to @faq and return
    end
  end

  def create
    if !current_user.try(:support_volunteer?)
      flash[:error] = "Sorry, only support volunteers can create faqs."
      redirect_to support_path and return
    end
    @faq = Faq.new(params[:faq])
    if @faq.save
      flash[:notice] = "Faq created"
      redirect_to @faq
    else
      # reset so don't get field with errors which breaks definition lists
      flash[:error] = @ticket.errors.full_messages.join(", ")
      @faq = Faq.new(params[:faq])
      render :edit
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
      @faq.comment!(params[:content], params[:official], params[:private], session[:authentication_code])
    when "Watch this FAQ"
      @faq.watch!(params[:email])
    when "Don't watch this FAQ"
      @faq.unwatch!(params[:email])
    when "Update Faq"
      @faq.update_from_edit!(params[:faq][:position],
                             params[:faq][:summary],
                             params[:faq][:content])
    end
    redirect_to @faq and return
  end
end
