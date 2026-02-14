class PlaylistsController < ApplicationController
  before_action :set_playlist, only: [ :show, :edit, :update, :destroy, :reorder ]

  def index
    @pagy, @playlists = pagy(
      :offset,
      policy_scope(Playlist).order(updated_at: :desc),
      limit: 20
    )
  end

  def show
    authorize @playlist
    @playlist_items = @playlist.playlist_items.includes(:media_file)
  end

  def new
    @playlist = current_user.playlists.build
    authorize @playlist
  end

  def create
    @playlist = current_user.playlists.build(playlist_params)
    authorize @playlist

    if @playlist.save
      redirect_to @playlist, notice: "Плейлист создан."
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
    authorize @playlist
  end

  def update
    authorize @playlist

    if @playlist.update(playlist_params)
      redirect_to @playlist, notice: "Плейлист обновлён."
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    authorize @playlist
    @playlist.destroy!
    redirect_to playlists_path, notice: "Плейлист удалён."
  end

  def reorder
    authorize @playlist

    item_ids = params[:item_ids] || []
    ActiveRecord::Base.transaction do
      # Reset all positions to negative values to avoid unique constraint violations
      @playlist.playlist_items.update_all("position = -position")
      # Set new positions
      item_ids.each_with_index do |id, index|
        @playlist.playlist_items.where(id: id).update_all(position: index + 1)
      end
    end
    @playlist.recalculate_total_duration!

    redirect_to @playlist, notice: "Порядок обновлён."
  end

  private

  def set_playlist
    @playlist = current_user.playlists.find(params[:id])
  end

  def playlist_params
    params.require(:playlist).permit(:name, :description)
  end
end
