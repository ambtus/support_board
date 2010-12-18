class FaqsController < ApplicationController
  def index
    @faqs = Faq.order(:position)
    if params[:unposted]
      @faqs = @faqs.where(:posted => false)
    else
      @faqs = @faqs.where(:posted => true)
    end
  end

  def show
    @faq = Faq.find(params[:id])
    # don't show details if posted
    if @faq.posted?
      render :show_posted
    else
      if !current_user && session[:authentication_code]
        @faq.faq_details.build # create a new empty response template
        render :show_owner
      elsif !current_user # not logged in, can't comment
        @details = @faq.faq_details.where(:private => false)
        render :show_guest
      elsif current_user.support_volunteer
        @faq.faq_details.build # create a new empty response template
        render :show_volunteer
      else # logged in as non-support volunteer
        @faq.faq_details.build # create a new empty response template
        render :show_user
      end
    end
  end

  def edit
    @faq = Faq.find(params[:id])
    if current_user.support_volunteer
      @faq.faq_details.build # create a new empty response template
    else
      flash[:notice] = "Sorry, only support volunteers can edit faqs"
      redirect_to @faq and return
    end
  end

  def update
    @faq = Faq.find(params[:id])
    if params[:commit] == "This FAQ answered my question"
      FaqVote.create(:faq_id => @faq.id)
    elsif current_user.try(:support_admin)
      case params[:commit]
      when "Post"
        @faq.update_attribute(:user_id, current_user.id)
        @faq.update_attribute(:posted, true)
        redirect_to @faq and return
      when "Unpost"
        @faq.update_attribute(:user_id, current_user.id)
        @faq.update_attribute(:posted, false)
      end
    elsif current_user.try(:support_volunteer)
      @faq.update_attributes(params[:faq])
      if @faq.save
        flash[:notice] = "FAQ updated"
      else
        render :edit and return
      end
    elsif current_user || session[:authentication_code]
      # TODO only update faq_details
      @faq.update_attributes(params[:faq])
      if @faq.save
        flash[:notice] = "Comments added"
      else
        render :edit and return
      end
    else
      flash[:notice] = "Sorry, you don't have permission"
    end
    redirect_to @faq and return
  end
end
