class App
  module Views
    class Layout < Mustache
      def title
        @title || "Welcome to Pass the Sass"
      end
      def content
        @content
      end
      def year
        @time.year
      end
    end
  end
end