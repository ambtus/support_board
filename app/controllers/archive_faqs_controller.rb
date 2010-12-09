class ArchiveFaqsController < ApplicationController
  def index
    @faqs = ArchiveFaq.where(:posted => true).order(:position)
  end
  def show
    @faq = ArchiveFaq.find(params[:id])
  end
end
