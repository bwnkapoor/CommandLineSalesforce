require_relative '../dependencies'

describe "dependencies" do

  describe '#findStrongTies' do
    context 'with duplicates' do
      x = {"A"=>["B", "C"], "B"=>["A", "C"], "C"=>[]}
      x = findStrongTies(x)
      it{ expect(x).to eq( {"A"=>["B"], "B"=>["A"] } ) }
    end
  end

  describe "#non_cyclical" do
    context "remove non-cyclical" do
      x = {"A"=>["B", "C"], "B"=>["A", "C"], "C"=>[] }
      x = non_cyclical x
      it{ expect(x).to eq( {"C"=>[]} ) }
    end

    context "my current bug" do
      x = {"A"=>[], "B"=>["A", "C"] }
      x = non_cyclical x
      it{ expect(x).to eq( {"A"=>[], "B"=>["A", "C"]} ) }
    end
  end
  
  describe "#tsort" do
    context "With letters" do
      x = {"A"=>["B"], "B"=>[], "C"=>[]}
      x = x.tsort
      it{ expect(x).to eq( ["B", "A", "C"] ) }
  	end
  	
  	context "With numbers" do
  	  x = {1=>[2, 3], 2=>[3], 3=>[], 4=>[]}
  	  x = x.tsort
  	  it{ expect(x).to eq( [3, 2, 1, 4] ) }
  	end
  end

end