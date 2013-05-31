module Streamworker
  module Workers
    class ShopifyWorker < Worker

      attr_accessor :credit_threshold
      
      def initialize(view_context, opts={})
        @credit_threshold = 28
      end

      def with_shopify_session
        ShopifyAPI::Base.activate_session(opts[:session])
        yield
      ensure 
        ShopifyAPI::Base.clear_session      
      end      
    end
  end
end
