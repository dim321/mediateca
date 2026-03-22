class PlaylistItemsController < ApplicationController
  before_action :set_playlist
  before_action :set_playlist_item, only: [ :update, :destroy ]

  def create
    authorize @playlist, :update?

    saved = false
    @playlist.with_lock do
      next_position = (@playlist.playlist_items.maximum(:position) || 0) + 1
      @item = @playlist.playlist_items.build(create_playlist_item_params.merge(position: next_position))
      saved = @item.save
    end

    if saved
      redirect_to @playlist, notice: t("playlist_items.flash.added")
    else
      redirect_to @playlist, alert: @item.errors.full_messages.join(", ")
    end
  end

  def update
    authorize @playlist, :update?

    if @item.update(playlist_item_params)
      redirect_to @playlist, notice: t("playlist_items.flash.position_updated")
    else
      redirect_to @playlist, alert: @item.errors.full_messages.join(", ")
    end
  end

  def destroy
    authorize @playlist, :update?
    @item.destroy!
    redirect_to @playlist, notice: t("playlist_items.flash.removed")
  end

  private

  def set_playlist
    @playlist = current_user.playlists.find(params[:playlist_id])
  end

  def set_playlist_item
    @item = @playlist.playlist_items.find(params[:id])
  end

  def create_playlist_item_params
    params.require(:playlist_item).permit(:media_file_id)
  end

  def playlist_item_params
    params.require(:playlist_item).permit(:media_file_id, :position)
  end
end
