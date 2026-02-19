import { useMutation, useQueryClient } from '@tanstack/react-query'
import { useNavigate } from 'react-router-dom'
import { datadogRum } from '@datadog/browser-rum'
import { authService } from '@/services/api'
import { useAuthStore } from '@/store/auth'

export function useLogin() {
  const setAuth = useAuthStore((s) => s.setAuth)
  const navigate = useNavigate()
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: (data: { email: string; password: string }) =>
      authService.login(data),
    onSuccess: (res) => {
      const { access_token, refresh_token, user } = res.data
      // Limpa cache do usuário anterior antes de navegar
      queryClient.clear()
      setAuth(access_token, refresh_token, user)
      datadogRum.setUser({ id: user.id, email: user.email, name: user.name })
      navigate('/dashboard')
    },
  })
}

export function useRegister() {
  const setAuth = useAuthStore((s) => s.setAuth)
  const navigate = useNavigate()
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: (data: { email: string; password: string; name: string }) =>
      authService.register(data),
    onSuccess: (res) => {
      const { access_token, refresh_token, user } = res.data
      queryClient.clear()
      setAuth(access_token, refresh_token, user)
      datadogRum.setUser({ id: user.id, email: user.email, name: user.name })
      navigate('/dashboard')
    },
  })
}

export function useLogout() {
  const logout = useAuthStore((s) => s.logout)
  const navigate = useNavigate()
  const queryClient = useQueryClient()

  return () => {
    // Limpa todo o cache antes de deslogar
    queryClient.clear()
    datadogRum.clearUser()
    logout()
    navigate('/login')
  }
}
