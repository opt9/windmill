require 'spec_helper'

describe "managing api keys", :type => :feature do
    before :each do |example|
        unless example.metadata[:skip_before] 
            visit '/auth/bypass'
        end
    end
    
    it "requires authentication", :skip_before do
        visit '/apikeys'
        expect(page).to_not have_link "New"
    end
    
    it "lets me make keys" do
        precount = APIKey.count
        visit '/apikeys'
        expect(page).to have_link "New"
        click_link "New"
        expect(page).to have_button "Add"
        click_button "Add"
        expect(APIKey.count).to eq(precount+1)
    end
end