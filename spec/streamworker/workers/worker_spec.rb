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
  let(:worker) { Streamworker::Workers::Worker.new(view_context) }

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
