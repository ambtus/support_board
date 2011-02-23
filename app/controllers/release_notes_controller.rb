class ReleaseNotesController < ApplicationController
  def index
    if params[:drafts]
      @release_notes = ReleaseNote.drafts
    else
      @release_notes = ReleaseNote.posted
    end
  end
  def new
    if !current_user.try(:support_volunteer?)
      flash[:notice] = "Sorry, only support volunteers can create release notes."
      redirect_to support_path and return
    end
    @release_note = ReleaseNote.new
  end
  def create
    if !current_user.try(:support_volunteer?)
      flash[:notice] = "Sorry, only support volunteers can create release notes."
      redirect_to support_path and return
    end
    @release_note = ReleaseNote.new(params[:release_note])
    if @release_note.save
      flash[:notice] = "release note created"
      redirect_to @release_note
    else
      # reset so don't get field with errors which breaks definition lists
      flash[:error] = @release_note.errors.full_messages.join(", ")
      @release_note = ReleaseNote.new(params[:release_note])
      render :new
    end
  end
  def show
    @release_note = ReleaseNote.find(params[:id])
  end
  def edit
    @release_note = ReleaseNote.find(params[:id])
    if !current_user.try(:support_volunteer?)
      flash[:notice] = "Sorry, only support volunteers can edit release notes."
      redirect_to @release_note and return
    end
    if @release_note.posted && !current_user.try(:support_admin?)
      flash[:notice] = "Sorry, only support admins can edit posted release notes."
      redirect_to @release_note and return
    end
    render :new
  end
  def update
    @release_note = ReleaseNote.find(params[:id])
    if !current_user.try(:support_volunteer?)
      flash[:notice] = "Sorry, only support volunteers can edit release notes."
      redirect_to @release_note and return
    end
    if @release_note.posted && !current_user.try(:support_admin?)
      flash[:notice] = "Sorry, only support admins can edit posted release notes."
      redirect_to @release_note and return
    end
    @release_note.attributes=params[:release_note]
    if @release_note.save
      flash[:notice] = "release note updated"
      redirect_to @release_note
    else
      # reset so don't get field with errors which breaks definition lists
      flash[:error] = @release_note.errors.full_messages.join(", ")
      @release_note = ReleaseNote.new(params[:release_note])
      render :new
    end
  end
end
