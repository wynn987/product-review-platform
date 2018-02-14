class ProductsController < ApplicationController
  include SwaggerDocs::Products
  before_action :doorkeeper_authorize!
  before_action :set_product, only: [:show, :update, :destroy]

  # GET /companies/:company_id/products
  def index
    @products = Product.where(company_id: params[:company_id])

    render json: @products, methods: [:reviews_count, :aggregate_score]
  end

  # GET /products/1
  def show
    render json: @product, methods: [:reviews_count, :aggregate_score, :company_name]
  end

  # POST /companies/:company_id/products
  def create
    @product = Product.new(product_params.merge(company_id: params[:company_id]))

    if @product.save
      render json: @product, status: :created, location: @product
    else
      render json: @product.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /products/1
  def update
    if @product.update(product_params)
      render json: @product
    else
      render json: @product.errors, status: :unprocessable_entity
    end
  end

  # DELETE /products/1
  def destroy
    @product.discard
    render json: nil, status: :ok
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_product
      @product = Product.find_by(id: params[:id])
      render_id_not_found if @product.nil?
    end

    # Only allow a trusted parameter "white list" through.
    def product_params
      params.require(:product).permit(:name, :description)
    end
end
