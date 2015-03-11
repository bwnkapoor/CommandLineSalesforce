require_relative '../lib/apexpage.rb'
require 'byebug'

describe "ApexPage" do
  describe ".controller" do
    context "basic controller" do
      the_controller = "hello"
      html = "<apex:page controller='#{the_controller}'></apex:page>"
      pg = ApexPage.new( {Markup: html} )
      it{ expect(pg.controller).to eq the_controller }
    end
    context "no controller" do
      html = "<apex:page></apex:page>"
      pg = ApexPage.new( {Markup: html} )
      it{ expect(pg.controller).to eq nil }
    end
  end

  describe ".extensions" do

    context "one extension" do
      the_controller = "hello"
      html = "<apex:page extensions='#{the_controller}'></apex:page>"
      pg = ApexPage.new( {Markup: html} )
      it{ expect(pg.extensions).to eq [the_controller] }
    end

    context "two extensions" do
      extensions = ["extA","extB"]
      ext = extensions.join(",")
      html = "<apex:page extensions='" + ext + "'></apex:page>"
      pg = ApexPage.new( {Markup: html} )
      it{ expect(pg.extensions).to eq extensions }
    end
  end  
end