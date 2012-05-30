class App
  module Views
    class Layout < Mustache
      def title
        @title || "Welcome to Pass the Sass"
      end
    end
  end
end