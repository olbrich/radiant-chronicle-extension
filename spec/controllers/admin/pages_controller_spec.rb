require File.dirname(__FILE__) + '/../../spec_helper'
require File.dirname(__FILE__) + '/../shared/resource_controller'

describe Admin::PagesController do
  dataset :users, :pages

  it_should_behave_like("versioned resource controller")

  before :each do
    login_as :existing
  end
  
  describe "editing a page" do
    integrate_views
    
    before(:each) do
      @page = pages(:first)
      @page.save # version 1
      @page.title = "Draft of First"
      @page.status = Status[:draft]
      @page.save # version 2
    end
    
    it "should load the current version for editing" do
      get :edit, :id => @page.id
      
      assigns[:page].title.should == @page.current.title
      assigns[:page].lock_version.should == @page.current.lock_version
    end
    
    it "should load a specified version for editing" do
      get :edit, :id => @page.id, :version => 1
      
      assigns[:page].title.should == @page.versions.first_version.instance.title
      assigns[:page].lock_version.should == @page.current.lock_version
    end
    
    it "should have the version diff popup" do
      get :edit, :id => page_id(:first)
      response.should be_success
      response.should have_selector("div#version-diff-popup")
    end
  end
  
  describe "previewing a page" do
    integrate_views
    
    before(:each) do
      @page = pages(:first)
    end
    
    it "should add javascript to the flash when view_after_saving is set" do
      put :update, :id=>@page.id, "continue"=>"Save and Continue Editing", "page"=>params_for_page(@page), "view_after_saving"=>"1"
      response.should be_redirect
      flash[:javascript].should =~ %r{window.open}
    end

    it "should not add javascript to the flash when view_after_saving is not set" do
      put :update, :id=>@page.id, "continue"=>"Save and Continue Editing", "page"=>params_for_page(@page)
      response.should be_redirect
      flash[:javascript].should be_nil
    end
    
    it "should set view_after_saving in the session when view_after_saving is set" do
      put :update, :id=>@page.id, "continue"=>"Save and Continue Editing", "page"=>params_for_page(@page), "view_after_saving"=>"1"
      response.should be_redirect
      session[:view_after_saving].should be_true
    end
    
    it "should unset view_after_saving in the session when view_after_saving is not set" do
      session[:view_after_saving] = true
      put :update, :id=>@page.id, "continue"=>"Save and Continue Editing", "page"=>params_for_page(@page)
      response.should be_redirect
      session[:view_after_saving].should_not be_true
    end
    
  end
  
  describe "deleting a page" do
    integrate_views
    
    before :each do
      @page = pages(:first)
      @page.update_attributes(:title => "current", :status_id => Status[:draft].id)
    end
    
    it "should load the live version of the page" do
      get :remove, :id => @page.id
      assigns[:page].title.should_not =~ /current/
    end
    
    it "should be destroyed" do
      delete :destroy, :id => @page.id
      flash[:notice].should == "The pages were successfully removed from the site."
    end
  end
  
  def params_for_page(page)
    {"slug"=>page.slug, "class_name"=>page.class_name, "title"=>page.title, "breadcrumb"=>page.breadcrumb, "lock_version"=>page.lock_version, "parts_attributes"=>[{"name"=>"body", "filter_id"=>"", "content"=>"test"}], "status_id"=>page.status_id, "layout_id"=>page.layout_id, "parent_id"=>page.parent_id}
  end
end