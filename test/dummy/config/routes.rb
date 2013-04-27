Rails.application.routes.draw do

  mount Streamworker::Engine => "/streamworker"
end
