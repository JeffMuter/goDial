{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  buildInputs = with pkgs; [
    # Shell and core utilities
    bash
    
    # Go development
    go
    gopls
    gotools
    go-tools
    templ
    
    # Database tools
    sqlite
    sqlc
    goose
    
    # Development tools
    git
    curl
    jq
    
    # Build tools
    gnumake

    # Web development
    nodejs
    nodePackages.tailwindcss
    air
    
    # Testing tools
    gotestsum  # Better test output
  ];

  shellHook = ''
    echo "🚀 Welcome to goDial development environment!"
    echo ""
    
    # Help function that can be called anytime
    help() {
      echo ""
      echo "🎯 goDial Development Environment Help"
      echo "======================================"
      echo ""
      echo "📋 Available commands:"
      echo ""
      echo "  🚀 Development:"
      echo "    • dev          - Start full development environment (Air + CSS watcher)"
      echo "    • build        - Build application for production"
      echo "    • test         - Run all tests with coverage"
      echo "    • test-watch   - Run tests in watch mode"
      echo ""
      echo "  📊 Database:"
      echo "    • db-status    - Show current database migration status"
      echo "    • db-migrate   - Run pending migrations"
      echo "    • db-rollback  - Rollback last migration"
      echo "    • db-reset     - Reset database (DESTRUCTIVE)"
      echo "    • db-seed      - Seed database with test data"
      echo "    • db-backup    - Create database backup"
      echo ""
      echo "  🔧 Utilities:"
      echo "    • generate     - Generate templates and SQL code"
      echo "    • clean        - Clean build artifacts and temp files"
      echo "    • deps         - Update dependencies"
      echo "    • help         - Show this help message"
      echo ""
      echo "  📦 NPM Scripts (via npm run):"
      echo "    • build:css    - Build Tailwind CSS"
      echo "    • watch:css    - Watch and rebuild CSS on changes"
      echo "    • build:templates - Generate Templ templates"
      echo ""
      echo "📁 Project structure:"
      echo "  • cmd/           - Application entry point"
      echo "  • internal/      - Internal packages (auth, ai, database, etc.)"
      echo "  • db/            - Database schemas, migrations, and queries"
      echo "  • static/        - Static web assets (CSS, JS, images)"
      echo "  • templates/     - Templ HTML templates"
      echo "  • scripts/       - Development and deployment scripts"
      echo ""
      echo "🎯 Quick start guide:"
      echo "  1. Run 'dev' to start development server"
      echo "  2. Visit http://localhost:8080"
      echo "  3. Make changes and enjoy hot reloading!"
      echo ""
      echo "💡 Tips:"
      echo "  • All scripts are in ./scripts/ directory"
      echo "  • Database file: goDial.db (SQLite)"
      echo "  • Environment: \$GODIAL_ENV = development"
      echo "  • Use 'help' anytime to see this message"
      echo ""
      echo "Happy coding! 🎉"
      echo ""
    }
    
    # Auto-setup function
    setup_project() {
      echo "🔧 Setting up development environment..."
      
      # Ensure database exists and is migrated
      if [ ! -f "goDial.db" ]; then
        echo "📊 Creating database..."
        touch goDial.db
      fi
      
      # Run migrations
      echo "📊 Running database migrations..."
      goose -dir db/migrations sqlite3 goDial.db up
      
      # Generate SQL code
      echo "🔧 Generating SQL code..."
      sqlc generate
      
      # Generate templates
      echo "🎨 Generating templates..."
      templ generate
      
      # Initialize node modules if needed
      if [ ! -d "node_modules" ]; then
        echo "📦 Installing Node.js dependencies..."
        npm install
      fi
      
      echo "✅ Development environment ready!"
    }
    
    # Run setup automatically
    setup_project
    
    echo ""
    echo "📋 Available commands:"
    echo "  🚀 Development:"
    echo "    • dev          - Start full development environment (Air + CSS watcher)"
    echo "    • build        - Build application for production"
    echo "    • test         - Run all tests with coverage"
    echo "    • test-watch   - Run tests in watch mode"
    echo ""
    echo "  📊 Database:"
    echo "    • db-status    - Show current database migration status"
    echo "    • db-migrate   - Run pending migrations"
    echo "    • db-rollback  - Rollback last migration"
    echo "    • db-reset     - Reset database (DESTRUCTIVE)"
    echo "    • db-seed      - Seed database with test data"
    echo "    • db-backup    - Create database backup"
    echo ""
    echo "  🔧 Utilities:"
    echo "    • generate     - Generate templates and SQL code"
    echo "    • clean        - Clean build artifacts and temp files"
    echo "    • deps         - Update dependencies"
    echo ""
    echo "📁 Project structure:"
    echo "  • cmd/           - Application entry point"
    echo "  • internal/      - Internal packages (auth, ai, database, etc.)"
    echo "  • db/            - Database schemas, migrations, and queries"
    echo "  • static/        - Static web assets (CSS, JS, images)"
    echo "  • templates/     - Templ HTML templates"
    echo "  • scripts/       - Development and deployment scripts"
    echo ""
    echo "🎯 Quick start:"
    echo "  1. Run 'dev' to start development server"
    echo "  2. Visit http://localhost:8080"
    echo "  3. Make changes and enjoy hot reloading!"
    echo ""
    echo "💡 Type 'help' anytime to see detailed command information!"
    echo ""
    echo "Happy coding! 🎉"
    echo ""
    
    # Set up aliases for convenience
    alias dev='./scripts/dev.sh'
    alias build='./scripts/build.sh'
    alias test='./scripts/test.sh'
    alias test-watch='./scripts/test-watch.sh'
    alias db-status='./scripts/db-status.sh'
    alias db-migrate='./scripts/db-migrate.sh'
    alias db-rollback='./scripts/db-rollback.sh'
    alias db-reset='./scripts/db-reset.sh'
    alias db-seed='./scripts/db-seed.sh'
    alias db-backup='./scripts/db-backup.sh'
    alias generate='./scripts/generate.sh'
    alias clean='./scripts/clean.sh'
    alias deps='./scripts/update-deps.sh'
  '';

  # Set environment variables
  CGO_ENABLED = "1";
  GOPROXY = "https://proxy.golang.org,direct";
  
  # Development settings
  GODIAL_ENV = "development";
  GODIAL_DB_PATH = "goDial.db";
}
