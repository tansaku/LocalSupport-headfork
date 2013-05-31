require 'spec_helper'

describe Organization do

  before do
    #TODO: Pavel: Is there any need to reload factories definitions each time?
    # I did so cuz here was FactoryGirl.factories.clear and FactoryGirl.find_definitions
    # And it seems .clear method didn't worked and I was getting FactoryGirl::DuplicateDefinitionError:
    # Sequence already registered: name. Nevertheless specs r green if the next line is removed.
    FactoryGirl.reload

    @org1 = FactoryGirl.build(:organization, :name => 'Harrow Bereavement Counselling', :description => 'Bereavement Counselling', :address => '64 pinner road', :postcode => 'HA1 3TE', :donation_info => 'www.harrow-bereavment.co.uk/donate')
    Gmaps4rails.should_receive(:geocode)
    @org1.save!
    @org2 = FactoryGirl.build(:organization, :name => 'Indian Elders Associaton', :description => 'Care for the elderly', :address => '62 pinner road', :postcode => 'HA1 3RE', :donation_info => 'www.indian-elders.co.uk/donate')
    Gmaps4rails.should_receive(:geocode)
    @org2.save!
    @org3 = FactoryGirl.build(:organization, :name => 'Age UK', :description => 'Care for the elderly', :address => '62 pinner road', :postcode => 'HA1 3RE', :donation_info => 'www.age-uk.co.uk/donate')
    Gmaps4rails.should_receive(:geocode)
    @org3.save!
  end

  it 'must be able to humanize description' do
    expect(Organization.humanize_description('THIS IS A GOVERNMENT STRING')).to eq('This is a government string')
  end

  it 'must be able to humanize nil description' do
    expect(Organization.humanize_description(nil)).to eq(nil)
  end

  it 'must be able to extract postcode and address' do
    expect(Organization.parse_address('HARROW BAPTIST CHURCH, COLLEGE ROAD, HARROW, HA1 1BA')).to eq({:address => 'HARROW BAPTIST CHURCH, COLLEGE ROAD, HARROW', :postcode => 'HA1 1BA'})
  end

  it 'must be able to handle postcode extraction when no postcode' do
    expect(Organization.parse_address('HARROW BAPTIST CHURCH, COLLEGE ROAD, HARROW')).to eq({:address =>'HARROW BAPTIST CHURCH, COLLEGE ROAD, HARROW', :postcode => ''})
  end
  
  it 'must be able to handle postcode extraction when nil address' do
     expect(Organization.parse_address(nil)).to eq({:address =>'', :postcode => ''})
  end

  it 'can humanize with all first capitals' do
    expect("HARROW BAPTIST CHURCH, COLLEGE ROAD, HARROW".humanized_all_first_capitals).to eq("Harrow Baptist Church, College Road, Harrow")
  end

  describe 'Creating of Organizations from CSV file' do

    before(:all){ @headers = 'Title,Charity Number,Activities,Contact Name,Contact Address,website,Contact Telephone,date registered,date removed,accounts date,spending,income,company number,OpenlyLocalURL,twitter account name,facebook account name,youtube account name,feed url,Charity Classification,signed up for 1010,last checked,created at,updated at,Removed?'.split(',')}

    it 'must not create org when date removed is not nil' do
      fields = CSV.parse('HARROW BAPTIST CHURCH,1129832,NO INFORMATION RECORDED,MR JOHN ROSS NEWBY,"HARROW BAPTIST CHURCH, COLLEGE ROAD, HARROW",http://www.harrow-baptist.org.uk,020 8863 7837,2009-05-27,2009-05-28,,,,,http://OpenlyLocal.com/charities/57879-HARROW-BAPTIST-CHURCH,,,,,"207,305,108,302,306",false,2010-09-20T21:38:52+01:00,2010-08-22T22:19:07+01:00,2012-04-15T11:22:12+01:00,*****')
      org = create_organization(fields)
      org.should be_nil
    end

    it 'must be able to generate multiple Organizations from text file' do
      attempted_number_to_import = 1006
      actual_number_to_import = 642
      Gmaps4rails.should_receive(:geocode).exactly(actual_number_to_import)
      lambda {
        Organization.import_addresses 'db/data.csv', attempted_number_to_import
      }.should change(Organization, :count).by(actual_number_to_import)
    end

    it 'must be able to handle no postcode in text representation' do
      Gmaps4rails.should_receive(:geocode)
      fields = CSV.parse('HARROW BAPTIST CHURCH,1129832,NO INFORMATION RECORDED,MR JOHN ROSS NEWBY,"HARROW BAPTIST CHURCH, COLLEGE ROAD, HARROW",http://www.harrow-baptist.org.uk,020 8863 7837,2009-05-27,,,,,,http://OpenlyLocal.com/charities/57879-HARROW-BAPTIST-CHURCH,,,,,"207,305,108,302,306",false,2010-09-20T21:38:52+01:00,2010-08-22T22:19:07+01:00,2012-04-15T11:22:12+01:00,*****')
      org = create_organization(fields)
      expect(org.name).to eq('Harrow Baptist Church')
      expect(org.description).to eq('No information recorded')
      expect(org.address).to eq('Harrow Baptist Church, College Road, Harrow')
      expect(org.postcode).to eq('')
      expect(org.website).to eq('http://www.harrow-baptist.org.uk')
      expect(org.telephone).to eq('020 8863 7837')
      expect(org.donation_info).to eq(nil)
    end

    it 'must be able to handle no address in text representation' do
      Gmaps4rails.should_receive(:geocode)
      fields = CSV.parse('HARROW BAPTIST CHURCH,1129832,NO INFORMATION RECORDED,MR JOHN ROSS NEWBY,,http://www.harrow-baptist.org.uk,020 8863 7837,2009-05-27,,,,,,http://OpenlyLocal.com/charities/57879-HARROW-BAPTIST-CHURCH,,,,,"207,305,108,302,306",false,2010-09-20T21:38:52+01:00,2010-08-22T22:19:07+01:00,2012-04-15T11:22:12+01:00,*****')
      org = create_organization(fields)
      expect(org.name).to eq('Harrow Baptist Church')
      expect(org.description).to eq('No information recorded')
      expect(org.address).to eq('')
      expect(org.postcode).to eq('')
      expect(org.website).to eq('http://www.harrow-baptist.org.uk')
      expect(org.telephone).to eq('020 8863 7837')
      expect(org.donation_info).to eq(nil)
    end

    it 'must be able to generate Organization from text representation ensuring words in correct case and postcode is extracted from address' do
      Gmaps4rails.should_receive(:geocode)
      fields = CSV.parse('HARROW BAPTIST CHURCH,1129832,NO INFORMATION RECORDED,MR JOHN ROSS NEWBY,"HARROW BAPTIST CHURCH, COLLEGE ROAD, HARROW, HA1 1BA",http://www.harrow-baptist.org.uk,020 8863 7837,2009-05-27,,,,,,http://OpenlyLocal.com/charities/57879-HARROW-BAPTIST-CHURCH,,,,,"207,305,108,302,306",false,2010-09-20T21:38:52+01:00,2010-08-22T22:19:07+01:00,2012-04-15T11:22:12+01:00,*****')
      org = create_organization(fields)
      expect(org.name).to eq('Harrow Baptist Church')
      expect(org.description).to eq('No information recorded')
      expect(org.address).to eq('Harrow Baptist Church, College Road, Harrow')
      expect(org.postcode).to eq('HA1 1BA')
      expect(org.website).to eq('http://www.harrow-baptist.org.uk')
      expect(org.telephone).to eq('020 8863 7837')
      expect(org.donation_info).to eq(nil)
    end


    it 'should raise error if no columns found' do
      #Headers are without Title header
      @headers = 'Charity Number,Activities,Contact Name,Contact Address,website,Contact Telephone,date registered,date removed,accounts date,spending,income,company number,OpenlyLocalURL,twitter account name,facebook account name,youtube account name,feed url,Charity Classification,signed up for 1010,last checked,created at,updated at,Removed?'.split(',')
      fields = CSV.parse('HARROW BAPTIST CHURCH,1129832,NO INFORMATION RECORDED,MR JOHN ROSS NEWBY,"HARROW BAPTIST CHURCH, COLLEGE ROAD, HARROW, HA1 1BA",http://www.harrow-baptist.org.uk,020 8863 7837,2009-05-27,,,,,,http://OpenlyLocal.com/charities/57879-HARROW-BAPTIST-CHURCH,,,,,"207,305,108,302,306",false,2010-09-20T21:38:52+01:00,2010-08-22T22:19:07+01:00,2012-04-15T11:22:12+01:00,*****')
      lambda{
        create_organization(fields)
      }.should raise_error CSV::MalformedCSVError, "No expected column with name Title in CSV file"
    end

    it 'should save Organization from file without running validations' do
      #As validations are not going to run, calls to Gmaps API won't be performed too
      Gmaps4rails.should_not_receive(:geocode)
      fields = CSV.parse('HARROW BAPTIST CHURCH,1129832,NO INFORMATION RECORDED,MR JOHN ROSS NEWBY,"HARROW BAPTIST CHURCH, COLLEGE ROAD, HARROW, HA1 1BA",http://www.harrow-baptist.org.uk,020 8863 7837,2009-05-27,,,,,,http://OpenlyLocal.com/charities/57879-HARROW-BAPTIST-CHURCH,,,,,"207,305,108,302,306",false,2010-09-20T21:38:52+01:00,2010-08-22T22:19:07+01:00,2012-04-15T11:22:12+01:00,*****')
      row = CSV::Row.new(@headers, fields.flatten)
      org = Organization.create_from_array(row, false)
      expect(org.name).to eq('Harrow Baptist Church')
      expect(org.description).to eq('No information recorded')
      expect(org.address).to eq('Harrow Baptist Church, College Road, Harrow')
      expect(org.postcode).to eq('HA1 1BA')
      expect(org.website).to eq('http://www.harrow-baptist.org.uk')
      expect(org.telephone).to eq('020 8863 7837')
      expect(org.donation_info).to eq(nil)
    end

    def create_organization(fields)
      row = CSV::Row.new(@headers, fields.flatten)
      Organization.create_from_array(row)
    end
  end

  describe 'fetch data as pages' do
    before(:each) do
      Gmaps4rails.should_receive(:geocode).exactly(25).times
      @orgs = []
      #create 25 organizations, so overall will be 25 + 3
      25.times do
        @orgs << FactoryGirl.create(:organization)
      end
    end

    it 'should get :size data starting from :record NO OFFSET' do
      @orgs = Organization.order('updated_at DESC')
      start = @orgs[3]
      offset = 0
      size = 5
      expect(@orgs[4..8]).to eq Organization.get_next(start, offset, size)
    end

    it 'should get :size data starting from :record WITH OFFSET' do
      @orgs = Organization.order('updated_at DESC')
      start = @orgs[3]
      offset = 2
      size = 5
      expect(@orgs[6..10]).to eq Organization.get_next(start, offset, size)
    end

    it 'should get :size data starting from :record BACKWARD NO OFFSET' do
      @orgs = Organization.order('updated_at DESC')
      start = @orgs[10]
      offset = 0
      size = 5
      expect(@orgs[5..9]).to eq Organization.get_prev(start, offset, size)
    end

    it 'should get :size data starting from :record BACKWARD WITH OFFSET' do
      @orgs = Organization.order('updated_at DESC')
      start = @orgs[20]
      offset = 5
      size = 5
      expect(@orgs[10..14]).to eq Organization.get_prev(start, offset, size)
    end
  end

  it 'must have search by keyword' do
    Organization.should respond_to(:search_by_keyword)
  end

  it 'find all orgs that have keyword anywhere in their name or description' do
    Organization.search_by_keyword("elderly").should == [@org2, @org3]
  end
  
  it 'should have gmaps4rails_option hash with :check_process set to false' do
    @org1.gmaps4rails_options[:check_process].should == false
  end

  it 'should geocode when address changes' do
    new_address = '60 pinner road'
    Gmaps4rails.should_receive(:geocode).with("#{new_address}, #{@org1.postcode}", "en", false,"http")
    @org1.update_attributes :address => new_address
  end

  it 'should geocode when new object is created' do
      address = '60 pinner road'
      postcode = 'HA1 3RE'
      Gmaps4rails.should_receive(:geocode).with("#{address}, #{postcode}", "en", false, "http")
      org = FactoryGirl.build(:organization,:address => address, :postcode => postcode, :name => 'Happy and Nice', :gmaps => true)
      org.save
  end

  #TODO: refactor with expect{} instead of should as Rspec 2 promotes
  it 'should delete geocoding errors and save organization' do
    new_address = '777 pinner road'
    @org1.latitude = 77
    @org1.longitude = 77
    Gmaps4rails.should_receive(:geocode).and_raise(Gmaps4rails::GeocodeInvalidQuery)
    @org1.address = new_address
    @org1.update_attributes :address => new_address
    @org1.errors['gmaps4rails_address'].should be_empty
    actual_address = Organization.find_by_name(@org1.name).address
    actual_address.should eq new_address
    @org1.latitude.should eq nil
    @org1.longitude.should eq nil
  end

  it 'should attempt to geocode after failed' do
    Gmaps4rails.should_receive(:geocode).and_raise(Gmaps4rails::GeocodeInvalidQuery)
    @org1.save!
    new_address = '60 pinner road'
    Gmaps4rails.should_receive(:geocode)
    lambda{
      @org1.address = new_address
      # destructive save is called to raise exception if saving fails
      @org1.save!
    }.should_not raise_error
    actual_address = Organization.find_by_name(@org1.name).address
    actual_address.should eq new_address
  end
end
