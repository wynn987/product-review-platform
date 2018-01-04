class ReviewsController < ApplicationController
  before_action :set_review, only: [:show, :update, :destroy]
  before_action :authenticate_user!

  # GET /products/:product_id/reviews
  # GET /services/:service_id/reviews
  def index
    @reviews = []
    if params[:product_id].present?
      @reviews = Product.find(params[:product_id]).reviews
    elsif params[:service_id].present?
      @reviews = Service.find(params[:service_id]).reviews
    else
      render_bad_request("No product_id or service_id specified")
      return
    end

    render json: @reviews, methods: [:company, :likes_count, :comments_count, :strengths]
  end

  # GET /reviews/1
  def show
    render json: @review, methods: [:company, :likes_count, :comments_count, :strengths]
  end

  # POST /products/:product_id/reviews
  # POST /services/:service_id/reviews
  def create
    # Store review_params in a temp variable to avoid
    # repeatedly calling the method
    whitelisted = review_params
    params = {
      score: whitelisted[:score],
      content: whitelisted[:content],
      company_id: whitelisted[:company_id],
      strengths: whitelisted[:strengths] || []
    }
    reviewable = nil
    if whitelisted[:product_id].present?
      params[:reviewable_id] = whitelisted[:product_id]
      params[:reviewable_type] = "Product"
      reviewable = Product.find(whitelisted[:product_id])
    elsif whitelisted[:service_id].present?
      params[:reviewable_id] = whitelisted[:service_id]
      params[:reviewable_type] = "Service"
      reviewable = Service.find(whitelisted[:service_id])
    else
      render_bad_request("No product_id or service_id specified")
      return
    end
    @review = Review.new(params)
    # Update aggregate score of associated vendor company
    company = add_company_score(reviewable.company, whitelisted[:score])

    if @review.save && company.save
      render json: @review, status: :created, location: @review
    else
      render json: @review.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /reviews/1
  def update
    company = nil
    if review_params[:score]
      # Update aggregate score of associated vendor company
      company = update_company_score(@review.reviewable.company, @review.score, review_params[:score])
    end
    if @review.update(review_params) && (company.nil? || company.save)
      render json: @review
    else
      render json: @review.errors, status: :unprocessable_entity
    end
  end

  # DELETE /reviews/1
  def destroy
    # Update aggregate score of associated vendor company
    company = subtract_company_score(@review.reviewable.company, @review.score)
    @review.destroy && company.save
  end

  private
    def add_company_score(company, score)
      company.aggregate_score = company.add_score(score)
      company
    end

    def update_company_score(company, old_score, updated_score)
      company.aggregate_score = company.update_score(old_score, updated_score)
      company
    end

    def subtract_company_score(company, score)
      company.aggregate_score = company.subtract_score(score)
      company
    end

    # Use callbacks to share common setup or constraints between actions.
    def set_review
      @review = Review.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def review_params
      params.require(:review).permit(:score, :content, :product_id, :service_id, :company_id, :strengths)
    end
end
