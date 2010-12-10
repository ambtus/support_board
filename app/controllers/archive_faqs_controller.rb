class ArchiveFaqsController < ApplicationController
  def index
    @faqs = ArchiveFaq.where(:posted => true).order(:position)
  end
  def show
    @faq = ArchiveFaq.find(params[:id])
  end
  def edit
    @faq = ArchiveFaq.find(params[:id])
    if current_user.support_volunteer
      @faq.faq_details.build # create a new empty response template
    else
      flash[:notice] = "Sorry, only support volunteers can edit faqs"
      redirect_to @faq and return
    end
  end
  def update
    @faq = ArchiveFaq.find(params[:id])
    if current_user.try(:support_admin)
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
      @faq.update_attributes(params[:archive_faq])
      if @faq.save
        flash[:notice] = "Archive faq updated"
      else
        render :edit and return
      end
    elsif current_user || session[:authentication_code]
      @faq.update_attribute(:faq_details, params[:archive_faq][:faq_details])
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
