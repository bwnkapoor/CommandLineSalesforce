require_relative '../lib/apexcomponent.rb'

describe 'ApexComponent' do
  describe ".attributes" do
    context "one attribute type" do
      html = "<apex:component>\n" + 
             "  <apex:attribute name='something' type='String'/>\n" +
             "</apex:page>"
      component = ApexComponent.new( {Markup: html} )
      it{ expect(component.attributes).to eq ['String'] }
    end

    context "multiple attribute types" do
      html = "<apex:component>\n" + 
             "  <apex:attribute name='something' type='String'/>\n" +
             "  <apex:attribute name='something' type='Opportunity'/>\n" +
             "</apex:component>"
      component = ApexComponent.new( {Markup: html} )
      it{ expect(component.attributes).to eq ['String','Opportunity'] }
    end
  end

  describe ".controller" do
    context "expect controller view" do
      html = "<apex:component controller='theController'></apex:component>"
      component = ApexComponent.new( {Markup: html} )
      it{ expect(component.controller).to eq "theController" }
    end
  end

  describe ".extensions" do
    context "expect controller view, even when we have a comment block" do
      html = "<!--we have garbage at the top of our function-->\n<apex:component controller='theController' extensions='A,B'></apex:component>"
      component = ApexComponent.new( {Markup: html} )
      it{ expect(component.extensions).to eq ["A","B"] }
    end
  end

end