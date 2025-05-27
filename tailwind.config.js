/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    "./internal/templates/**/*.{html,templ}",
    "./static/**/*.js",
    "./**/*_templ.go",
  ],
  theme: {
    extend: {
      colors: {
        'primary': '#26763C',
        'secondary': '#E1F19F',
        'accent': '#FCBE54',
      }
    },
  },
  plugins: [require("daisyui")],
  daisyui: {
    themes: [
      {
        mytheme: {
          "primary": "#26763C",
          "secondary": "#E1F19F", 
          "accent": "#FCBE54",
          "neutral": "#3d4451",
          "base-100": "#ffffff",
          "info": "#3abff8",
          "success": "#36d399",
          "warning": "#fbbd23",
          "error": "#f87272",
        }
      },
      "light",
      "dark"
    ],
  },
} 
