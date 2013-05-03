module Streamworker
  module Workers
    class ShopifyWorker < Worker
      def with_shopify_session
        ShopifyAPI::Base.activate_session(opts[:session])
        yield
      ensure 
        ShopifyAPI::Base.clear_session      
      end      
    end
  end
end
