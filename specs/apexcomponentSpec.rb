require_relative '../lib/apexcomponent.rb'

describe 'ApexComponent' do
  describe ".attributes" do
    context "one attribute type" do
      html = "<apex:page>\n" + 
             "  <apex:attribute name='something' type='String'/>\n" +
             "</apex:page>"
      component = ApexComponent.new( {Markup: html} )
      it{ expect(component.attributes).to eq ['String'] }
    end

    context "multiple attribute types" do
      html = "<apex:page>\n" + 
             "  <apex:attribute name='something' type='String'/>\n" +
             "  <apex:attribute name='something' type='Opportunity'/>\n" +
             "</apex:page>"
      component = ApexComponent.new( {Markup: html} )
      it{ expect(component.attributes).to eq ['String','Opportunity'] }
    end    
  end
end