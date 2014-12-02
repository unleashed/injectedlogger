module InjectedLogger
  RSpec.describe Logger do
    RSpec.shared_examples "an injected logger" do
      subject { InjectedLogger::Logger }

      context 'levels' do
        it { is_expected.to respond_to :levels }

        it 'provides an array when asked for the levels' do
          expect(subject.levels).to be_kind_of(Array)
        end

        it 'lists the supported levels' do
          expect(subject.levels.sort).to eq(subject.level_info[:supported].sort)
        end
      end

      context 'level info' do
        it { is_expected.to respond_to :level_info }

        it 'provides a hash as information for level info' do
          expect(subject.level_info).to be_kind_of(Hash)
        end

        [:supported, :native, :nonnative, :fallback, :info].each do |key|
          it "provides a :#{key} key in level info" do
            expect(subject.level_info).to have_key(key)
          end
        end

        it 'responds to all native levels' do
          subject.level_info[:native].each do |lvl|
            expect(subject).to respond_to lvl
          end
        end

        it 'responds to all supported levels' do
          subject.level_info[:supported].each do |lvl|
            expect(subject).to respond_to lvl
          end
        end

        it 'maps all native levels to the underlying logger methods' do
          subject.level_info[:native].each do |lvl|
            expect(logger_object).to respond_to lvl
          end
        end

        it 'uses a native level as fallback' do
          fallback = subject.level_info.fetch :fallback, nil
          expect(subject.level_info[:native]).to include(fallback) if fallback
        end

        it 'writes to the logger native methods for each native level' do
          subject.level_info[:native].each_with_index do |lvl, i|
            str = lvl.to_s + i.to_s
            expect(logger_object).to receive(lvl).with(Regexp.new("#{Regexp.escape(str)}$"))
            subject.send lvl, str
          end
        end

      end
    end

    context 'with a Ruby-like logger' do
      let(:logger_object) { Helpers::RubyLikeLogger.new [] }

      before do
        InjectedLogger::Logger.use! logger_object
        #l = InjectedLogger::Logger
        #STDERR.puts "Native: #{l.level_info[:native]} Non-native: #{l.level_info[:nonnative]} Fallback: #{l.level_info[:fallback]} Info: #{l.level_info[:info]}"
      end

      it_behaves_like 'an injected logger'

      it 'responds to all levels defined as constants in the underlying logger' do
        logger_object.singleton_class.const_get(:LEVELS).each do |lvl|
          expect(subject).to respond_to lvl.downcase
        end
      end
    end

  end
end
