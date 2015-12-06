require 'spec_helper'

describe "managing configuration groups", :type => :feature do
    before :each do
        visit '/auth/bypass'
    end
    
    it "requires authentication", skip_before: true do
        visit '/auth/logout'
        visit '/configuration-groups'
        expect(page).to have_content "Login"
        expect(page).to have_content "OAuth"
        save_and_open_page
    end
end