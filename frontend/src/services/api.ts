import axios from 'axios'
import { useAuthStore } from '@/store/auth'

const AUTH_URL = import.meta.env.VITE_AUTH_API_URL || 'http://localhost:8001'
const PAYMENT_URL = import.meta.env.VITE_PAYMENT_API_URL || 'http://localhost:8002'

export const authApi = axios.create({
  baseURL: AUTH_URL,
  headers: { 'Content-Type': 'application/json' },
})

export const paymentApi = axios.create({
  baseURL: PAYMENT_URL,
  headers: { 'Content-Type': 'application/json' },
})

// Inject JWT token into requests
function addAuthInterceptor(api: typeof authApi) {
  api.interceptors.request.use((config) => {
    const token = useAuthStore.getState().accessToken
    if (token) {
      config.headers.Authorization = `Bearer ${token}`
    }
    return config
  })

  // Handle 401 - try to refresh token
  api.interceptors.response.use(
    (res) => res,
    async (error) => {
      const original = error.config
      if (error.response?.status === 401 && !original._retry) {
        original._retry = true
        const refreshToken = useAuthStore.getState().refreshToken
        if (refreshToken) {
          try {
            const res = await axios.post(`${AUTH_URL}/auth/refresh`, {
              refresh_token: refreshToken,
            })
            const { access_token, refresh_token, user } = res.data
            useAuthStore.getState().setAuth(access_token, refresh_token, user)
            original.headers.Authorization = `Bearer ${access_token}`
            return api(original)
          } catch {
            useAuthStore.getState().logout()
          }
        } else {
          useAuthStore.getState().logout()
        }
      }
      return Promise.reject(error)
    },
  )
}

addAuthInterceptor(authApi)
addAuthInterceptor(paymentApi)

// Auth API calls
export const authService = {
  register: (data: { email: string; password: string; name: string }) =>
    authApi.post('/auth/register', data),
  login: (data: { email: string; password: string }) =>
    authApi.post('/auth/login', data),
  me: () => authApi.get('/auth/me'),
  refresh: (refreshToken: string) =>
    authApi.post('/auth/refresh', { refresh_token: refreshToken }),
}

// Payment API calls
export const paymentService = {
  getBalance: () => paymentApi.get('/payments/balance'),
  transfer: (data: { to_email: string; amount: number; description?: string }) =>
    paymentApi.post('/payments/transfer', data),
  getHistory: () => paymentApi.get('/payments/history'),
}
