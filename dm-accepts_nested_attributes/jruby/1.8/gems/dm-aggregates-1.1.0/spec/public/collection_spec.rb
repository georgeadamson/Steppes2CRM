require 'spec_helper'

describe DataMapper::Collection do

  before :all do
    @dragons   = Dragon.all
    @countries = Country.all
  end

  supported_by :sqlite, :mysql, :postgres do

    it_should_behave_like 'It Has Setup Resources'
    it_should_behave_like 'An Aggregatable Class'

    describe 'ignore invalid query' do
      before :all do
        @dragons = @dragons.all(:id => [])
      end

      [ :size, :count ].each do |method|
        describe "##{method}" do
          it 'should return 0' do
            @dragons.send(method).should == 0
          end
        end
      end

      describe '#min' do
        it 'should return nil' do
          @dragons.min(:id).should == nil
        end
      end

      describe '#max' do
        it 'should return nil' do
          @dragons.max(:id).should == nil
        end
      end

      describe '#avg' do
        it 'should return nil' do
          @dragons.avg(:id).should == nil
        end
      end

      describe '#sum' do
        it 'should return nil' do
          @dragons.sum(:id).should == nil
        end
      end

      describe '#aggregate' do
        it 'should return nil' do
          @dragons.aggregate(:id).should == []
        end
      end
    end

    describe 'with collections created with Set operations' do
      before do
        @collection = @dragons.all(:name => 'George') | @dragons.all(:name => 'Puff')
      end

      describe '#size' do
        subject { @collection.size }

        it { should == 2 }
      end

      describe '#count' do
        subject { @collection.count }

        it { should == 2 }
      end

      describe '#min' do
        subject { @collection.min(:toes_on_claw) }

        it { should == 3 }
      end

      describe '#max' do
        subject { @collection.max(:toes_on_claw) }

        it { should == 4 }
      end

      describe '#avg' do
        subject { @collection.avg(:toes_on_claw) }

        it { should == 3.5 }
      end

      describe '#sum' do
        subject { @collection.sum(:toes_on_claw) }

        it { should == 7 }
      end

      describe '#aggregate' do
        subject { @collection.aggregate(:all.count, :name.count, :toes_on_claw.min, :toes_on_claw.max, :toes_on_claw.avg, :toes_on_claw.sum)}

        it { should == [ 2, 2, 3, 4, 3.5, 7 ] }
      end
    end

    describe 'with a collection limited to 1 result' do

      before do
        @dragons = Dragon.all(:limit => 1)
      end

      describe "#size" do
        it 'should return 1' do
          @dragons.size.should == 1
        end
      end

      describe "#count" do
        it 'should return 1' do
          pending 'TODO: make count apply to the limited collection. Currently limit applies after the count' do
            @dragons.count.should == 1
          end
        end
      end

    end

    describe 'with the order reversed by the grouping field' do
      before do
        @dragons = Dragon.all(:order => [ :birth_at.desc ])
      end

      it 'should display the results in reverse order' do
        @dragons.aggregate(:birth_at, :all.count).should == Dragon.aggregate(:birth_at, :all.count).reverse
      end
    end

  end

end
