# goDial Troubleshooting Guide

This guide follows our modular, easy-to-read philosophy to help you quickly identify and resolve common issues.

## 🚨 Common Issues & Solutions

### 1. NPM Errors

#### Issue: `npm error could not determine executable to run`
**Cause**: Missing or incomplete npm scripts in package.json
**Solution**: Use our updated package.json with proper scripts
```bash
npm run dev        # Start development environment
npm run build      # Build for production
npm run build:css  # Build CSS only
```

#### Issue: `Browserslist: caniuse-lite is outdated`
**Cause**: Outdated browser compatibility database
**Solution**: Update the database (optional, doesn't break functionality)
```bash
npx update-browserslist-db@latest
```

### 2. Air (Hot Reload) Errors

#### Issue: `air: command not found`
**Cause**: Not running in nix-shell environment
**Solution**: Always run development commands in nix-shell
```bash
nix-shell        # Enter nix environment
npm run dev      # Then run dev command
```

#### Issue: Air not detecting changes
**Cause**: Incorrect file paths in .air.toml
**Solution**: Our .air.toml is configured to watch:
- `*.go` files
- `*.templ` files
- `*.html` files
- `*.css` files

### 3. Template Errors

#### Issue: `templ: command not found`
**Cause**: Not in nix-shell environment
**Solution**: 
```bash
nix-shell --run "templ generate"
```

#### Issue: Template parsing errors
**Cause**: Incorrect templ syntax
**Solution**: Check template syntax:
- Use `@component()` for component calls
- Use `{ children... }` for content injection
- Use `{ variable }` for variable interpolation

### 4. CSS/Tailwind Issues

#### Issue: Styles not applying
**Cause**: CSS not built or wrong paths
**Solution**: 
```bash
npm run build:css  # Build CSS
# Check that static/css/output.css exists
```

#### Issue: Tailwind not finding classes
**Cause**: Incorrect content paths in tailwind.config.js
**Solution**: Our config scans:
- `./internal/templates/**/*.{html,templ}`
- `./static/**/*.js`
- `./**/*_templ.go`

## 🛠️ Development Workflow

### Quick Start (Recommended)
```bash
npm run dev
```
This automatically:
1. Enters nix-shell if needed
2. Cleans up old processes
3. Generates templates
4. Builds CSS
5. Starts Air with hot reload
6. Starts CSS watcher

### Manual Step-by-Step
```bash
nix-shell                    # Enter development environment
templ generate              # Generate template files
npm run build:css           # Build Tailwind CSS
air                         # Start hot reload server
```

### Production Build
```bash
npm run build               # Complete production build
npm run start               # Run the built application
```

## 🧹 Clean Reset

If everything seems broken:
```bash
npm run clean               # Remove build artifacts
nix-shell                   # Re-enter environment
npm run build               # Rebuild everything
```

## 📁 File Structure Reference

```
goDial/
├── scripts/
│   └── dev.sh              # Modular development script
├── internal/templates/
│   ├── components/         # Reusable UI components
│   ├── layouts/           # Page layouts
│   └── pages/             # Individual pages
├── static/css/
│   ├── input.css          # Tailwind input file
│   └── output.css         # Generated CSS (auto-generated)
├── .air.toml              # Hot reload configuration
├── tailwind.config.js     # CSS framework configuration
└── package.json           # NPM scripts and dependencies
```

## 🎯 Key Principles

1. **Modularity**: Each script and component has a single responsibility
2. **Environment Consistency**: Always use nix-shell for development
3. **Clear Feedback**: Scripts provide colored output and status messages
4. **Error Handling**: Proper cleanup and graceful failure handling
5. **Documentation**: Self-documenting code and clear naming

## 💡 Tips

- Always check you're in nix-shell before running commands
- Use `npm run dev` for the best development experience
- CSS changes are watched automatically during development
- Template changes trigger automatic rebuilds via Air
- Check process IDs printed by the dev script to monitor what's running

## 🆘 Getting Help

If you encounter issues not covered here:
1. Check the terminal output for specific error messages
2. Verify you're in the correct directory
3. Ensure nix-shell is active
4. Try a clean rebuild with `npm run clean && npm run build` 