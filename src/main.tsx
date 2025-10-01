import React from 'react'
import ReactDOM from 'react-dom/client'
import App from './App.tsx'
import { initializeTracing } from './observability/tracing'

// Initialize Faro tracing
initializeTracing()

ReactDOM.createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>,
)
