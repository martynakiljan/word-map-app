# Word Map App

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## Table of Contents
- [Project Description](#project-description)
- [Tech Stack](#tech-stack)
- [Getting Started](#getting-started)
- [Available Scripts](#available-scripts)
- [Project Scope](#project-scope)
- [Project Status](#project-status)
- [License](#license)

## Project Description

Word Map App is a web application that helps users track visited countries and plan future travels. The application provides an interactive world map where users can mark visited countries, add travel details, and discover new destinations.

### Key Features
- User authentication and private accounts
- Interactive world map with country outlines
- Marking visited countries
- Adding travel details and notes
- Country information and travel inspiration
- Real-time updates and synchronization

## Tech Stack

### Frontend
- React 19
- TypeScript 5
- Astro 5
- React-Leaflet
- Tailwind CSS 4
- Shadcn/ui

### Backend
- Supabase
  - Supabase Auth for authentication
  - PostgreSQL for data storage
  - Supabase Realtime for real-time features

### Other
- GeoJSON for geographical data
- Axios for HTTP requests

### Hosting & CI/CD
- Vercel/Netlify for hosting
- GitHub Actions for CI/CD

## Getting Started

### Prerequisites
- Node.js v22.14.0 (as specified in .nvmrc)
- npm or yarn
- Supabase account

### Installation
1. Clone the repository
```bash
git clone https://github.com/yourusername/word-map-app.git
cd word-map-app
```

2. Install dependencies
```bash
npm install
# or
yarn install
```

3. Set up environment variables
Create a `.env` file in the root directory with the following variables:
```
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_supabase_anon_key
```

4. Start the development server
```bash
npm run dev
# or
yarn dev
```

## Available Scripts

*Scripts will be added once the project is initialized*

## Project Scope

### Current Features
- User authentication
- Interactive world map
- Country marking system
- Travel details management
- Country information display

### Limitations
- Web-only application (no mobile version)
- No social features
- Limited to basic travel tracking functionality

## Project Status

The project is currently in development. The following features are implemented:
- [ ] User authentication
- [ ] Basic map functionality
- [ ] Country marking system
- [ ] Travel details management
- [ ] Country information display

### Planned Improvements
- Mobile responsiveness
- Social sharing features
- Advanced travel planning tools
- Integration with travel APIs

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
