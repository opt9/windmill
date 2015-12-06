require 'spec_helper'

describe "managing configuration groups", :type => :feature do
    before :each do |example|
        unless example.metadata[:skip_before] 
            visit '/auth/bypass'
        end
    end
    
    it "requires authentication", :skip_before do
        visit '/configuration-groups'
        expect(page).to have_content "Login"
        expect(page).to have_content "OAuth"
    end
end