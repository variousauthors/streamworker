require 'spec_helper'

describe WorkerTests do
  render_views

  describe '#inspect' do
    it 'it renders a worker' do
      get :inspect
      expect(response).to render_template("inspect")
      expect(response.body).to include("#&lt;Streamworker::Workers::Worker")
    end

  end
end
