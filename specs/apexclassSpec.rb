require_relative '../lib/apexclass'
require 'byebug'

describe 'ApexClass' do
  describe '.extends' do
    context 'standard test' do
      extension = "ExtClass"
      bdy = "privATE class Something extends " + extension
      cls = ApexClass.new( {Body: bdy} )
      it{ expect(cls.extends).to eq(extension) }
    end

    context 'standard ignore braces' do
      extension = "ExtClass"
      bdy = "privATE class Something extends " + extension + "{"
      cls = ApexClass.new( {Body: bdy} )
      it{ expect(cls.extends).to eq(extension) }
    end

    context 'global with sharing ' do
      extension = "ExtClass"
      bdy = "global with sharing class Something extends " + extension + "{"
      cls = ApexClass.new( {Body: bdy} )
      it{ expect(cls.extends).to eq(extension) }
    end
    
    context 'global without sharing ' do
      extension = "ExtClass"
      bdy = "global with sharing class Something extends " + extension + "{"
      cls = ApexClass.new( {Body: bdy} )
      it{ expect(cls.extends).to eq(extension) }
    end
  end
end