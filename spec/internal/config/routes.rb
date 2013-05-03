Rails.application.routes.draw do

  match '/worker_tests/inspect' => 'worker_tests#inspect'

end
