require 'spec_helper'

describe WorkerTests do
  render_views

  describe '#inspect' do
    it 'it renders a worker' do
      get :inspect
      response.should contain("Listing widgets")
    end

  end
end
