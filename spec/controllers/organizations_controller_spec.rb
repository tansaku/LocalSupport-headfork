require 'spec_helper'

describe OrganizationsController do
  before :suite do
    FactoryGirl.reload
  end

  def mock_organization(stubs={})
    (@mock_organization ||= mock_model(Organization).as_null_object).tap do |organization|
      organization.stub(stubs) unless stubs.empty?
    end
  end

  describe "GET search" do
    it "searches all organizations as @organizations" do
      result = [mock_organization]
      json='my markers'
      result.should_receive(:to_gmaps4rails).and_return(json)
      Organization.should_receive(:search_by_keyword).with('test').and_return(result)

      get :search, :q => 'test'
      response.should render_template 'index'

      assigns(:organizations).should eq([mock_organization])
      assigns(:json).should eq(json)
    end
  end


  describe "GET index" do

    before(:each) do
      @orgs = []
      #create 25 organizations
      25.times do
        @orgs << FactoryGirl.build(:organization)
      end
    end

    context 'params for scrolling/paging are passed' do
      it 'should show next page' do
        expected = @orgs[5..10]
        Organization.should_receive(:get_next).with(@orgs[0], 0, 10).and_return(expected)
        Organization.should_receive(:find_by_id).with(5).and_return(@orgs[0])
        #Organization.stub(:get_next) { @orgs[5..10] }
        get :index, page: 'next', last: 5
        assigns(:organizations).should eq(expected)
      end

      it 'should show next page, size and offset are specified' do
        expected = @orgs[5..10]
        Organization.should_receive(:get_next).with(@orgs[0], 5, 5).and_return(expected)
        Organization.should_receive(:find_by_id).with(5).and_return(@orgs[0])
        #Organization.stub(:get_next) { @orgs[5..10] }
        get :index, page: 'next', last: 5, size: 5, offset: 5
        assigns(:organizations).should eq(expected)
      end

      #Also tests absence of params[:last]
      it 'should show prev page' do
        expected = @orgs[5..10]
        Organization.should_receive(:get_prev).with(@orgs[0], 0, 10).and_return(expected)
        Organization.should_receive(:order).with('updated_at desc').and_return([@orgs[0]])
        #Organization.stub(:get_next) { @orgs[5..10] }
        get :index, page: 'prev'
        assigns(:organizations).should eq(expected)
      end

    end

  end

describe "GET show" do
  it "assigns the requested organization as @organization" do
    Organization.stub(:find).with("37") { mock_organization }
    get :show, :id => "37"
    assigns(:organization).should be(mock_organization)
  end
end

describe "GET new" do
  context "while signed in" do
    before(:each) do
      @admin = FactoryGirl.create(:charity_worker)
      sign_in :charity_worker, @admin
    end
    it "assigns a new organization as @organization" do
      Organization.stub(:new) { mock_organization }
      get :new
      assigns(:organization).should be(mock_organization)
    end
  end
  context "while not signed in" do
    it "redirects to sign-in" do
      get :new
      expect(response).to redirect_to new_charity_worker_session_path
    end
  end
end

describe "GET edit" do
  context "while signed in" do
    before(:each) do
      @admin = FactoryGirl.create(:charity_worker)
      sign_in :charity_worker, @admin
    end
    it "assigns the requested organization as @organization" do
      Organization.stub(:find).with("37") { mock_organization }
      get :edit, :id => "37"
      assigns(:organization).should be(mock_organization)
    end
  end
  #TODO: way to dry out these redirect specs?
  context "while not signed in" do
    it "redirects to sign-in" do
      get :edit, :id => 37
      expect(response).to redirect_to new_charity_worker_session_path
    end
  end
end

describe "POST create" do
  context "while signed in" do
    before(:each) do
      @admin = FactoryGirl.create(:charity_worker)
      sign_in :charity_worker, @admin
    end
    describe "with valid params" do
      it "assigns a newly created organization as @organization" do
        Organization.stub(:new).with({'these' => 'params'}) { mock_organization(:save => true) }
        post :create, :organization => {'these' => 'params'}
        assigns(:organization).should be(mock_organization)
      end

      it "redirects to the created organization" do
        Organization.stub(:new) { mock_organization(:save => true) }
        post :create, :organization => {}
        response.should redirect_to(organization_url(mock_organization))
      end
    end

    describe "with invalid params" do
      it "assigns a newly created but unsaved organization as @organization" do
        Organization.stub(:new).with({'these' => 'params'}) { mock_organization(:save => false) }
        post :create, :organization => {'these' => 'params'}
        assigns(:organization).should be(mock_organization)
      end

      it "re-renders the 'new' template" do
        Organization.stub(:new) { mock_organization(:save => false) }
        post :create, :organization => {}
        response.should render_template("new")
      end
    end
  end
  context "while not signed in" do
    it "redirects to sign-in" do
      Organization.stub(:new).with({'these' => 'params'}) { mock_organization(:save => true) }
      post :create, :organization => {'these' => 'params'}
      expect(response).to redirect_to new_charity_worker_session_path
    end
  end
end

describe "PUT update" do
  context "while signed in" do
    before(:each) do
      @admin = FactoryGirl.create(:charity_worker)
      sign_in :charity_worker, @admin
    end
    describe "with valid params" do
      it "updates the requested organization" do
        Organization.should_receive(:find).with("37") { mock_organization }
        mock_organization.should_receive(:update_attributes).with({'these' => 'params'})
        put :update, :id => "37", :organization => {'these' => 'params'}
      end

      it "updates donation_info url" do
        Organization.should_receive(:find).with("37") { mock_organization }
        mock_organization.should_receive(:update_attributes).with({'donation_info' => 'http://www.friendly.com/donate'})
        put :update, :id => "37", :organization => {'donation_info' => 'http://www.friendly.com/donate'}
      end

      it "assigns the requested organization as @organization" do
        Organization.stub(:find) { mock_organization(:update_attributes => true) }
        put :update, :id => "1"
        assigns(:organization).should be(mock_organization)
      end

      it "redirects to the organization" do
        Organization.stub(:find) { mock_organization(:update_attributes => true) }
        put :update, :id => "1"
        response.should redirect_to(organization_url(mock_organization))
      end
    end

    describe "with invalid params" do
      it "assigns the organization as @organization" do
        Organization.stub(:find) { mock_organization(:update_attributes => false) }
        put :update, :id => "1"
        assigns(:organization).should be(mock_organization)
      end

      it "re-renders the 'edit' template" do
        Organization.stub(:find) { mock_organization(:update_attributes => false) }
        put :update, :id => "1"
        response.should render_template("edit")
      end
    end
  end
  context "while not signed in" do
    it "redirects to sign-in" do
      put :update, :id => "1", :organization => {'these' => 'params'}
      expect(response).to redirect_to new_charity_worker_session_path
    end
  end
end

describe "DELETE destroy" do
  context "while signed in" do
    before(:each) do
      @admin = FactoryGirl.create(:charity_worker)
      sign_in :charity_worker, @admin
    end
    it "destroys the requested organization" do
      Organization.should_receive(:find).with("37") { mock_organization }
      mock_organization.should_receive(:destroy)
      delete :destroy, :id => "37"
    end

    it "redirects to the organizations list" do
      Organization.stub(:find) { mock_organization }
      delete :destroy, :id => "1"
      response.should redirect_to(organizations_url)
    end
  end
  context "while not signed in" do
    it "redirects to sign-in" do
      delete :destroy, :id => "37"
      expect(response).to redirect_to new_charity_worker_session_path
    end
  end
end

end
