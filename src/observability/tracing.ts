import { getWebInstrumentations, initializeFaro } from '@grafana/faro-web-sdk';
import { TracingInstrumentation } from '@grafana/faro-web-tracing';

/**
 * Initialize Faro OpenTelemetry tracing for browser → Tempo OTLP
 * Reads Tempo OTLP endpoint from VITE_TEMPO_URL environment variable
 */
export function initializeTracing() {
  const tempoUrl = import.meta.env.VITE_TEMPO_URL;
  
  if (!tempoUrl) {
    console.warn('VITE_TEMPO_URL not configured, tracing disabled');
    return;
  }

  try {
    initializeFaro({
      url: tempoUrl,
      app: {
        name: 'adgenxai-2.0',
        version: '2.0.0',
        environment: import.meta.env.MODE
      },
      instrumentations: [
        ...getWebInstrumentations({
          captureConsole: true,
        }),
        new TracingInstrumentation(),
      ],
    });
    
    console.log('Faro tracing initialized with Tempo endpoint:', tempoUrl);
  } catch (error) {
    console.error('Failed to initialize Faro tracing:', error);
  }
}
