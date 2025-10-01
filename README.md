[![CI Artifact Sentinel](https://example.com/ci-artifact-sentinel-badge.svg)](https://example.com/ci-artifact-sentinel) [![Launch Logkeeper](https://github.com/brandonlacoste9-tech/adgenxai-2.0/actions/workflows/launch-logkeeper.yml/badge.svg)](https://github.com/brandonlacoste9-tech/adgenxai-2.0/actions/workflows/launch-logkeeper.yml) [![UI Smoke Tests](https://github.com/brandonlacoste9-tech/adgenxai-2.0/actions/workflows/ui-smoke.yml/badge.svg)](https://github.com/brandonlacoste9-tech/adgenxai-2.0/actions/workflows/ui-smoke.yml)

# AdGenXAI 2.0

Modern AI-powered advertising generation platform with full observability and automated testing.

## Features

- **React SPA**: Built with React 18 and Vite for fast development and production builds
- **TypeScript**: Fully typed for better developer experience and code quality
- **Observability**: Integrated Faro OpenTelemetry tracing to Tempo OTLP endpoint
- **UI Testing**: Automated Playwright tests for smoke testing critical user flows
- **CI/CD**: GitHub Actions workflow for continuous integration and deployment

## Getting Started

### Prerequisites

- Node.js 18 or higher
- npm

### Installation

```bash
npm install
```

### Development

Start the development server:

```bash
npm run dev
```

### Build

Build the application for production:

```bash
npm run build
```

Preview the production build:

```bash
npm run preview
```

### Testing

Run UI smoke tests:

```bash
npm run test:ui
```

## Observability

The application includes Faro OpenTelemetry tracing that sends traces to a Tempo OTLP endpoint.

### Configuration

Set the `VITE_TEMPO_URL` environment variable to your Tempo OTLP endpoint:

```bash
# For local development
VITE_TEMPO_URL=https://your-tempo-endpoint.com

# For production (Netlify)
# Set in Netlify dashboard: Site settings → Environment variables
VITE_TEMPO_URL=https://your-tempo-endpoint.com
```

If `VITE_TEMPO_URL` is not set, tracing will be disabled with a console warning.

## Architecture

- `src/main.tsx` - Application entry point with tracing initialization
- `src/App.tsx` - Main application component with routing
- `src/observability/tracing.ts` - Faro OpenTelemetry tracing setup
- `tests/ui.spec.ts` - Playwright UI smoke tests
- `.github/workflows/ui-smoke.yml` - CI workflow for automated testing

## License

MIT