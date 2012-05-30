class App
  module Views
    class Layout < Mustache
      def title
        @title || "Welcome to Pass the Sass"
      end
      def content
        @content
      end
    end
  end
end