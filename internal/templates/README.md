# goDial Templates

This directory contains a clean, modular template structure designed for easy reading and understanding, with highly modularized components to separate different types of functionality conceptually.

## Structure

```
internal/templates/
├── components/     # Reusable UI components
│   ├── navigation.templ  # Navigation components (Navbar, Footer)
│   ├── forms.templ       # Form components (Button, Input)
│   └── cards.templ       # Card components (Card, SimpleCard)
├── layouts/        # Page layouts and wrappers
│   ├── base.templ        # Base layout
│   ├── home.templ        # Home page layout
│   └── simple.templ      # Simple layout with Alpine.js
└── pages/          # Individual page templates
    ├── home.templ        # Homepage
    └── stripe.templ      # Stripe payment page
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

#### `layouts/home.templ`
Home page specific layout with same structure as base layout.

#### `layouts/simple.templ`
Simple layout that includes Alpine.js for interactive components.

### Navigation Components (`components/navigation.templ`)

#### `components.Navbar()`
Responsive navigation bar with:
- Brand logo linking to home
- Navigation links (Home, About)
- Login button

#### `components.Footer()`
Simple footer with:
- Navigation links (About, Contact, Privacy)
- Copyright information

### Form Components (`components/forms.templ`)

#### `components.Button(text string, isPrimary bool, isLarge bool)`
Flexible button component with:
- Customizable text
- Primary/secondary styling
- Large/normal sizing
- CSS class composition using `templ.KV`

**Usage:**
```go
@components.Button("Click Me", "/???" true, false)  // Primary, normal size
@components.Button("Large Button", "/???" true, true)  // Primary, large size
```

#### `components.Input(label string, inputType string, name string, placeholder string)`
Form input component with:
- Customizable label
- Input type (text, email, password, etc.)
- Name attribute for form handling
- Placeholder text
- Consistent styling with form-control class

**Usage:**
```go
@components.Input("Email", "email", "user_email", "Enter your email")
```

### Card Components (`components/cards.templ`)

#### `components.Card(title string)`
Interactive card component with:
- Customizable title
- Built-in form with textarea
- Send message button
- Consistent card styling

**Usage:**
```go
@components.Card("Contact Form")
```

#### `components.SimpleCard(title string)`
Simple display card component with:
- Customizable title
- Basic content display
- Minimal styling

**Usage:**
```go
@components.SimpleCard("Feature Title")
```

## Pages

#### `pages/home.templ`
Homepage template featuring:
- Hero section with call-to-action
- Grid of feature cards using Card components
- Uses Home layout

#### `pages/stripe.templ`
Stripe payment page featuring:
- Payment form with Alpine.js interactivity
- User minutes display
- Simple cards for additional features
- Uses Simple layout

## Design Philosophy

1. **Modularity**: Components are organized by functionality (navigation, forms, cards)
2. **Reusability**: Components accept parameters for customization
3. **Consistency**: Standardized naming and structure across components
4. **Flexibility**: Boolean flags and string parameters for styling variations
5. **Readability**: Clear, semantic HTML with utility-first CSS classes
6. **Separation of Concerns**: Related components grouped in dedicated files

## Development Workflow

1. **Generate templates**: `templ generate` or `go run github.com/a-h/templ/cmd/templ@latest generate`
2. **Build application**: `go build -o bin/goDial cmd/main.go`
3. **Run with hot reload**: `./buildAir.sh`

## Best Practices

- Always use `@` prefix for component calls
- Use `{ children... }` for content injection in layouts
- Group related components in the same file (navigation, forms, cards)
- Keep components focused on single responsibilities
- Use descriptive parameter names
- Follow consistent CSS class conventions
- Use `templ.KV` for conditional CSS classes
- Import specific component files as needed: `"goDial/internal/templates/components"`
