class MediaFilesController < ApplicationController
  before_action :set_media_file, only: [ :show, :destroy ]

  def index
    @pagy, @media_files = pagy(
      :offset,
      policy_scope(MediaFile).by_media_type(params[:media_type]).recent,
      limit: 20
    )
  end

  def show
    authorize @media_file
  end

  def create
    authorize MediaFile
    result = Media::UploadService.new(
      user: current_user,
      file: params.dig(:media_file, :file),
      title: params.dig(:media_file, :title)
    ).call

    if result.success?
      redirect_to media_file_path(result.media_file), notice: t("media_files.flash.upload_queued")
    else
      flash.now[:alert] = result.error
      @media_files = policy_scope(MediaFile).recent
      render :index, status: :unprocessable_content
    end
  end

  def destroy
    authorize @media_file

    if @media_file.playlist_items.any?
      redirect_to media_files_path, alert: t("media_files.flash.destroy_blocked")
    else
      @media_file.destroy!
      redirect_to media_files_path, notice: t("media_files.flash.destroyed")
    end
  end

  private

  def set_media_file
    @media_file = current_user.media_files.find(params[:id])
  end
end
