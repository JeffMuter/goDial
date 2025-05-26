# goDial Templates

This directory contains a clean, modular template structure designed for easy reading and understanding, with highly modularized components to separate different types of functionality conceptually.

## Structure

```
internal/templates/
├── components/     # Reusable UI components
├── layouts/        # Page layouts and wrappers
└── pages/          # Individual page templates
```

## Components

### Layout Components

#### `layouts/base.templ`
The main layout wrapper that includes:
- HTML document structure
- Meta tags and title management
- Navigation bar
- Footer
- Main content area with `{ children... }`

**Usage:**
```go
@layouts.Base("Page Title") {
    // Your page content here
}
```

### UI Components

#### `components/navbar.templ`
Responsive navigation bar with:
- Mobile hamburger menu
- Desktop navigation links
- Brand logo
- Login button

#### `components/footer.templ`
Simple footer with:
- Navigation links
- Copyright information

#### `components/button.templ`
Flexible button component with variants and sizes:
- Variants: Primary, Secondary, Accent, Ghost, Link
- Sizes: Large, Normal, Small, Tiny

**Usage:**
```go
@components.Button("Click Me", components.Primary, components.Large)
```

#### `components/input.templ`
Comprehensive input components:
- Input types: Text, Email, Password, Number, Tel, URL
- Sizes: Large, Normal, Small, Tiny
- Variants: Primary, Secondary, Accent, Ghost, Bordered
- Both standalone and labeled versions
- Textarea support

**Usage:**
```go
// Simple input
@components.Input(components.Email, "Enter email", "email", components.InputBordered, components.InputNormal)

// Input with label
@components.InputWithLabel("Email Address", components.Email, "Enter email", "email", components.InputBordered, components.InputNormal)

// Textarea with label
@components.TextareaWithLabel("Message", "Type your message...", "message", 4)
```

#### `components/card.templ`
Card component for content display with:
- Title
- Form with textarea input
- Action button

## Pages

#### `pages/home.templ`
Homepage template featuring:
- Hero section with call-to-action
- Grid of feature cards
- Proper component composition

## Design Philosophy

1. **Modularity**: Each component has a single responsibility
2. **Reusability**: Components accept parameters for customization
3. **Consistency**: Standardized naming and structure across components
4. **Flexibility**: Type-safe variants and sizes for styling
5. **Readability**: Clear, semantic HTML with utility-first CSS classes

## Development Workflow

1. **Generate templates**: `templ generate`
2. **Build application**: `go build -o bin/goDial cmd/main.go`
3. **Run with hot reload**: `./buildAir.sh`

## Best Practices

- Always use `@` prefix for component calls
- Use `{ children... }` for content injection in layouts
- Define types for component variants to ensure type safety
- Keep components focused on single responsibilities
- Use descriptive parameter names
- Follow DaisyUI class conventions for consistency 