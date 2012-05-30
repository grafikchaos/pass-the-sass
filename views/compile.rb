class App
  module Views
    class Compile < Layout
      def content
        "Sass Passed - here is your css"
      end
      def domain
        @domain
      end
      def sass
        @sass
      end
      def vars
        @vars
      end
      def compass
        @compass
      end
    end
  end
end