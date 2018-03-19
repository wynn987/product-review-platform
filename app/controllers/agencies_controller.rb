class AgenciesController < ApplicationController
  include SwaggerDocs::Agencies
  before_action :doorkeeper_authorize!
  before_action :set_agency, only: [:show, :update, :destroy]
  before_action :validate_agency_pressence, only: [:show, :update, :destroy]

  # GET /agencies
  def index
    @agencies = Agency.kept

    render json: @agencies
  end

  # GET /agencies/1
  def show
    render json: @agency
  end

  # POST /agencies
  def create
    @agency = Agency.new(agency_params)

    if @agency.save
      render json: @agency, status: :created, location: @agency
    else
      render json: @agency.errors.messages, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /agencies/1
  def update
    if @agency.update(agency_params)
      render json: @agency
    else
      render json: @agency.errors.messages, status: :unprocessable_entity
    end
  end

  # DELETE /agencies/1
  def destroy
    @agency.discard
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_agency
    @agency = Agency.find_by(id: params[:id])
  end

  def validate_agency_pressence
    render_error(404, "Agency id": ["not found"]) if @agency.nil? || !@agency.presence?
  end

  # Only allow a trusted parameter "white list" through.
  def agency_params
    params.require(:agency).permit(:name, :email, :phone_number, :acronym, :kind, :description)
  end
end