import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { datadogRum } from '@datadog/browser-rum'
import { datadogLogs } from '@datadog/browser-logs'
import App from './App'
import './index.css'

datadogRum.init({
  applicationId: '2a4c1405-73e9-47e7-8f2b-4e0be2f8286a',
  clientToken: 'pub1a74b344a3e287c7168d0a7a10253418',
  site: 'datadoghq.com',
  service: 'paydog---web',
  env: 'sandbox',
  sessionSampleRate: 100,
  sessionReplaySampleRate: 100,
  trackBfcacheViews: true,
  trackUserInteractions: true,
  trackResources: true,
  trackLongTasks: true,
  defaultPrivacyLevel: 'mask-user-input',
})

datadogLogs.init({
  clientToken: 'pub1a74b344a3e287c7168d0a7a10253418',
  site: 'datadoghq.com',
  service: 'paydog---web',
  env: 'sandbox',
  forwardErrorsToLogs: true,
  forwardConsoleLogs: 'all',
  sessionSampleRate: 100,
})

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      retry: 1,
      staleTime: 30_000,
    },
  },
})

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <QueryClientProvider client={queryClient}>
      <App />
    </QueryClientProvider>
  </StrictMode>,
)
