require 'spec_helper'
require 'streamworker/workers/worker'

describe Streamworker::Workers::Worker do
  before(:each) do
    @view_context = double("view_context")
    @view_context.stub(:stylesheet_link_tag) do
      %Q{<link href="/assets/application.css?body=1" rel="stylesheet" type="text/css">}
    end
    @view_context.stub(:javascript_include_tag) do
      (%Q{<script src="/assets/application.js?body=1" type="text/javascript"></script>})
    end
  end

  let(:view_context){ @view_context }
  let(:worker_opts){ {unicorn_timeout: 100}}
  let(:worker) { Streamworker::Workers::Worker.new(view_context, worker_opts) }

  describe "#header" do
    subject{ worker.header }
    its(:length){ should > 1024 }
  end

  describe "#scroll" do
    subject{ worker.scroll }
    it { should be_valid_markup_fragment }
  end

  describe "#header + #footer" do
    specify { (worker.header + worker.footer('finished')).should be_valid_markup }
  end


  describe '#calculate_times' do
    before do
      stub_const('Streamworker::Workers::Worker::QUERIES_PER_BLOCK', 50)
      stub_const('Streamworker::Workers::Worker::TIME_PER_BLOCK', 80)
      Timecop.freeze(Time.local(2012, 7, 7, 7, 0, 0))
    end
    after do
      Timecop.return
    end

    subject { worker.calculate_times }

    context "less than 1 block total" do
      before do
        worker.should_receive(:queries_per_record).at_least(:once).and_return(2)
        worker.should_receive(:num_success).at_least(:once).and_return(7)
        worker.should_receive(:num_errors).at_least(:once).and_return(4)
        Timecop.freeze(Time.local(2012, 7, 7, 7, 1, 0))
      end
      let(:worker_opts){ {unicorn_timeout: 100, num_records: 20}}
      specify { expect(subject[:work_time]).to eq 100 }
      specify { expect(subject[:work_time_remaining]).to eq 40 }
      specify { expect(subject[:time_used]).to eq 60 }
      specify { expect(subject[:time_remaining]).to be_within(0.2).of 49 }
      specify { expect(subject[:total_time]).to be_within(0.2).of 109 }
    end

    context "more than 1 block total" do
    end

    context "unicorn timeout" do
    end
  end
  
  describe "#report_line" do
    subject{ worker.report_line("whatever the string is") }
    it { should be_valid_markup_fragment }
    it { should include("whatever the string is") }
  end

  describe "#report_error" do
    subject{ worker.report_error("whatever the string is") }
    it { should be_valid_markup_fragment }
    it { should include("whatever the string is") }
  end

  describe "#each" do
    subject{ worker.each }

    specify { expect { subject }.to raise_error("Worker subclasses must implement each to yield their output") }
  end
end
