class WorkerTests < ApplicationController

  def inspect
    @worker = Streamworker::Workers::Worker.new(view_context)

  end
end
