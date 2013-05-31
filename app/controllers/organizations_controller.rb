class OrganizationsController < ApplicationController
  # GET /organizations/search
  # GET /organizations/search.json
  before_filter :authenticate_charity_worker!, :except => [:search, :index, :show]

  def search
    # should this be a model method with a model spec around it ...?

    @organizations = Organization.search_by_keyword(params[:q])
    @json = @organizations.to_gmaps4rails
    respond_to do |format|
      format.html { render :template => 'organizations/index' }
      format.json { render json: @organizations }
    end
  end

  @@PAGE_SIZE = 10
  # GET /organizations
  # GET /organizations.json
  def index
    #FIXME: This comtrollers method seems to be fat, move logic
    #to model
    size = (params[:size]  || '10').to_i
    offset = (params[:offset]  || '0').to_i

    start = Organization.find_by_id(params[:last].to_i) if params[:last]
    start ||= Organization.order('updated_at desc').first

    if params[:page] == 'next' || !params[:page]
      @organizations = Organization.get_next(start, offset, size)
    elsif params[:page] == 'prev'
      @organizations = Organization.get_prev(start, offset, size)
    end
    @json = @organizations.to_gmaps4rails
    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @organizations }
    end
  end

  # GET /organizations/1
  # GET /organizations/1.json
  def show
    @organization = Organization.find(params[:id])
    @json = @organization.to_gmaps4rails
    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @organization }
    end
  end

  # GET /organizations/new
  # GET /organizations/new.json
  def new
    @organization = Organization.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @organization }
    end
  end

  # GET /organizations/1/edit
  def edit
    @organization = Organization.find(params[:id])
  end

  # POST /organizations
  # POST /organizations.json
  def create
    @organization = Organization.new(params[:organization])

    respond_to do |format|
      if @organization.save
        format.html { redirect_to @organization, notice: 'Organization was successfully created.' }
        format.json { render json: @organization, status: :created, location: @organization }
      else
        format.html { render action: "new" }
        format.json { render json: @organization.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /organizations/1
  # PUT /organizations/1.json
  def update
    @organization = Organization.find(params[:id])

    respond_to do |format|
      if @organization.update_attributes(params[:organization])
        format.html { redirect_to @organization, notice: 'Organization was successfully updated.' }
        format.json { head :ok }
      else
        format.html { render action: "edit" }
        format.json { render json: @organization.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /organizations/1
  # DELETE /organizations/1.json
  def destroy
    @organization = Organization.find(params[:id])
    @organization.destroy

    respond_to do |format|
      format.html { redirect_to organizations_url }
      format.json { head :ok }
    end
  end
end
