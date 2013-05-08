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

  describe "#queries_per_record" do
    specify { expect(worker.queries_per_record).to eq 1 } # subclasses define according to their workload
  end

  describe '#calculate_times' do
    before(:each) do
      Timecop.freeze(Time.local(2012, 7, 7, 7, 0, 0))
      stub_const('Streamworker::Workers::Worker::QUERIES_PER_BLOCK', 50)
      stub_const('Streamworker::Workers::Worker::TIME_PER_BLOCK', 80)
      worker.should_receive(:queries_per_record).at_least(:once).and_return(2)
    end
    after do
      Timecop.return
    end

    subject { worker.calculate_times }

    context "less than 1 block total" do
      before(:each) do
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

    context "more than 1 block total, faster than throttle" do
      before(:each) do
        worker.should_receive(:num_success).at_least(:once).and_return(9)
        worker.should_receive(:num_errors).at_least(:once).and_return(3)
        Timecop.freeze(Time.local(2012, 7, 7, 7, 1, 0))
      end
      let(:worker_opts){ {unicorn_timeout: 100, num_records: 40}}
      specify { expect(subject[:work_time]).to eq 100 }
      specify { expect(subject[:work_time_remaining]).to eq 40 }
      specify { expect(subject[:time_used]).to eq 60 }
      specify { expect(subject[:time_remaining]).to be_within(0.2).of 140 }
      specify { expect(subject[:total_time]).to be_within(0.2).of 200 }
    end

    context "more than 1 block total, slower than throttle" do
      before(:each) do
        worker.should_receive(:num_success).at_least(:once).and_return(20)
        worker.should_receive(:num_errors).at_least(:once).and_return(0)
        Timecop.freeze(Time.local(2012, 7, 7, 7, 1, 0))
      end
      let(:worker_opts){ {unicorn_timeout: 100, num_records: 75}}
      specify { expect(worker).not_to be_imminent_timeout }
      specify { expect(subject[:work_time]).to eq 100 }
      specify { expect(subject[:work_time_remaining]).to eq 40 }
      specify { expect(subject[:time_used]).to eq 60 }
      specify { expect(subject[:time_remaining]).to be_within(0.2).of 180 }
      specify { expect(subject[:total_time]).to be_within(0.2).of 240 }
    end

    context "imminent unicorn timeout" do
      before(:each) do
        worker.should_receive(:num_success).at_least(:once).and_return(20)
        worker.should_receive(:num_errors).at_least(:once).and_return(0)
        Timecop.freeze(Time.local(2012, 7, 7, 7, 1, 36))
      end
      let(:worker_opts){ {unicorn_timeout: 100, num_records: 75}}
      specify { expect(worker).to be_imminent_timeout }
    end
  end
  
  describe "#report_line" do
    subject{ worker.report_line("whatever the string is") }
    it { should be_valid_markup_fragment }
    it { should include("whatever the string is") }

    describe '#open_report_line' do
      subject{ worker.open_report_line("whatever the string is") }
      it { should_not be_valid_markup_fragment }
      specify{ expect(subject + worker.close_report_line).to be_valid_markup_fragment}
      it { should include("whatever the string is") }
    end

    describe '#report_fragment' do
      subject{ worker.report_fragment("whatever the string is") }
      context "report line already opened" do
        before { worker.should_receive(:fragment?).at_least(:once).and_return(true)}
        it { should eq "whatever the string is"}
      end
      context "report line not already opened" do
        it { should_not be_valid_markup_fragment }
        specify{ expect(subject + worker.close_report_line).to be_valid_markup_fragment}
        it { should include("whatever the string is") }
      end
    end
  end

  describe "success_line_num" do
    before do
      worker.should_receive(:line_num).at_least(:once).and_return(937)
    end
    subject{ worker.success_line_num}
    it { should be_valid_markup_fragment }
    it { should include("937") }
  end

  describe "error_line_num" do
    before do
      worker.should_receive(:line_num).at_least(:once).and_return(416)
    end
    subject{ worker.error_line_num}
    it { should be_valid_markup_fragment }
    it { should include("416") }
  end

  describe "#report_timeout_footer" do
    before do
      worker.should_receive(:num_records).at_least(:once).and_return(50)
      worker.should_receive(:num_success).at_least(:once).and_return(20)
    end
    # subject{ worker.header + worker.report_timeout_footer }
    specify { expect(worker.header + worker.report_timeout_footer).to be_valid_markup }
    specify { expect(worker.header + worker.report_timeout_footer).to include("we have to stop processing this job after 20 records") }

    specify { expect(worker.header + worker.report_timeout_footer).to include("resubmit the last 30 records.")}
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

  describe '#set_headers' do
    before do
      @response = double('response')
      @headers = {'Content-Length' => 42}
      @response.stub(:headers).and_return(@headers)
      Timecop.freeze(Time.local(2012, 7, 7, 7, 0, 0))

    end
    subject { worker.set_headers(@response) }
    it "should set headers for a streaming response" do
      subject
      expect( @headers.keys).not_to include('Content-Length')
      expect( @headers['Last-Modified']).to eq( Time.local(2012, 7, 7, 7, 0, 0).ctime.to_s )
      expect( @headers['Transfer-Encoding'] ).to eq('chunked')
      expect( @headers['Cache-Control']).to eq('no-cache')
    end
  end

end
