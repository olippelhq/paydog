/** @type {import('tailwindcss').Config} */
export default {
  content: [
    './index.html',
    './src/**/*.{js,ts,jsx,tsx}',
  ],
  theme: {
    extend: {
      colors: {
        dd: {
          50:  '#f5f0fb',
          100: '#e8d9f7',
          200: '#c9a8ed',
          300: '#aa77e3',
          400: '#8b4ed9',
          500: '#7b35c2',
          600: '#632CA6', // Datadog brand purple
          700: '#4e2285',
          800: '#3a1964',
          900: '#261043',
        },
      },
    },
  },
  plugins: [],
}
