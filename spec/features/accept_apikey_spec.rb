require 'spec_helper'

describe "managing api keys", :type => :feature do
    before :each do
        visit '/auth/bypass'
    end
    
    it "requires authentication", skip_before: true do
        visit '/auth/logout'
        visit '/apikeys'
        save_and_open_page
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