class App
  module Views
    class Compile < Layout
      def content
        @content || "Enter your updated variables & sass and hang on to yer britches!"
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