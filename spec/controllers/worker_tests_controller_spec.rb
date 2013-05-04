require 'spec_helper'

describe WorkerTests do
  render_views

# this spec is just a helloworld check that an app can use the streamworker/workers/worker object
  describe '#inspect' do
    it 'it renders a worker' do
      get :inspect
      expect(response).to render_template("inspect")
      expect(response.body).to include("#&lt;Streamworker::Workers::Worker")
    end

  end
end
