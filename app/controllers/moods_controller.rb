# frozen_string_literal: true

class MoodsController < ApplicationController
  include CollectionPageSetup
  include QuickCreate
  before_action :set_mood, only: %i[show edit update destroy]

  # GET /moods
  # GET /moods.json
  def index
    page_collection('@moods', 'mood')
  end

  # GET /moods/1
  # GET /moods/1.json
  def show
    if @mood.userid == current_user.id
      @page_edit = edit_mood_path(@mood)
      @page_tooltip = t('moods.edit_mood')
    else
      redirect_to_path(moods_path)
    end
  end

  # GET /moods/new
  def new
    @mood = Mood.new
  end

  # GET /moods/1/edit
  def edit
    return if @mood.userid == current_user.id
    redirect_to_path(mood_path(@mood))
  end

  # POST /moods
  # POST /moods.json
  def create
    @mood = Mood.new(mood_params.merge(userid: current_user.id))
    respond_to do |format|
      if @mood.save
        format.html { redirect_to mood_path(@mood) }
        format.json { render :show, status: :created, location: @mood }
      else
        format.html { render :new }
        format.json { render json: @mood.errors, status: :unprocessable_entity }
      end
    end
  end

  # POST /moods
  # POST /moods.json
  def premade
    Mood.add_premade(current_user.id)
    redirect_to_path(moods_path)
  end

  # PATCH/PUT /moods/1
  # PATCH/PUT /moods/1.json
  def update
    respond_to do |format|
      if @mood.update(mood_params)
        format.html { redirect_to mood_path(@mood) }
        format.json { render :show, status: :ok, location: @mood }
      else
        format.html { render :edit }
        format.json { render json: @mood.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /moods/1
  # DELETE /moods/1.json
  def destroy
    # Remove moods from existing moments
    @moments = current_user.moments.all

    @moments.each do |item|
      item.mood.delete(@mood.id)
      the_moment = Moment.find_by(id: item.id)
      the_moment.update(mood: item.mood)
    end

    @mood.destroy
    redirect_to_path(moods_path)
  end

  # rubocop:disable MethodLength
  def quick_create
    mood = Mood.new(
      userid: current_user.id,
      name: params[:mood][:name],
      description: params[:mood][:description]
    )

    result = if mood.save
               render_checkbox(mood, 'mood', 'moment')
             else
               { error: 'error' }
             end

    respond_with_json(result)
  end
  # rubocop:enable MethodLength

  private

  # Use callbacks to share common setup or constraints between actions.
  # rubocop:disable RescueStandardError
  def set_mood
    @mood = Mood.friendly.find(params[:id])
  rescue
    redirect_to_path(moods_path)
  end
  # rubocop:enable RescueStandardError

  def mood_params
    params.require(:mood).permit(:name, :description)
  end
end
