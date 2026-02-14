class PlaylistItemsController < ApplicationController
  before_action :set_playlist
  before_action :set_playlist_item, only: [ :update, :destroy ]

  def create
    @item = @playlist.playlist_items.build(playlist_item_params)
    authorize @playlist, :update?

    if @item.save
      redirect_to @playlist, notice: "Файл добавлен в плейлист."
    else
      redirect_to @playlist, alert: @item.errors.full_messages.join(", ")
    end
  end

  def update
    authorize @playlist, :update?

    if @item.update(playlist_item_params)
      redirect_to @playlist, notice: "Позиция обновлена."
    else
      redirect_to @playlist, alert: @item.errors.full_messages.join(", ")
    end
  end

  def destroy
    authorize @playlist, :update?
    @item.destroy!
    redirect_to @playlist, notice: "Файл удалён из плейлиста."
  end

  private

  def set_playlist
    @playlist = current_user.playlists.find(params[:playlist_id])
  end

  def set_playlist_item
    @item = @playlist.playlist_items.find(params[:id])
  end

  def playlist_item_params
    params.require(:playlist_item).permit(:media_file_id, :position)
  end
end
