class App
  module Views
    class Layout < Mustache
      def title
        @title || "Pass the SASS"
      end
      def content
        @content
      end
    end
  end
end
