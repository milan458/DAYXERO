// Tailwind theme for the DayXero website. Build with `npm run website:css` from the repo root,
// which writes assets/site.css. The Website workflow rebuilds it before every deploy.
module.exports = {
  content: ['./**/*.html', './assets/waitlist.js', './worker/**/*.js', '!./node_modules/**'],
  theme: {
    extend: {
      colors: {
        canvas: '#000000',
        sage: '#BCC388',
        'forest-moss': '#43511C',
        porcelain: '#FFFFFF',
        surface: {
          1: '#121212',
          2: '#161616',
          3: '#1E1E1E',
        },
        coral: '#C85A54',
        amber: '#E5A93C',
      },
      fontFamily: {
        sans: ['Inter', 'sans-serif'],
        mono: ['JetBrains Mono', 'monospace'],
      },
      borderRadius: {
        'card': '32px',
        'capsule': '9999px',
      },
    },
  },
};
