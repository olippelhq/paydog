import { useState } from 'react'
import { Link } from 'react-router-dom'
import { useLogin } from '@/hooks/useAuth'

export default function LoginPage() {
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const login = useLogin()

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault()
    login.mutate({ email, password })
  }

  return (
    <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-dd-50 to-dd-100">
      <div className="w-full max-w-md">
        <div className="bg-white rounded-2xl shadow-xl p-8">
          {/* Logo */}
          <div className="text-center mb-8">
            <div className="text-4xl mb-2">🐾</div>
            <h1 className="text-3xl font-bold text-gray-900">DogPay</h1>
            <p className="text-gray-500 mt-1">Pagamentos simples e seguros</p>
          </div>

          <form onSubmit={handleSubmit} className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Email
              </label>
              <input
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                required
                className="w-full px-4 py-2.5 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-dd-500 focus:border-transparent transition"
                placeholder="seu@email.com"
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Senha
              </label>
              <input
                type="password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                required
                className="w-full px-4 py-2.5 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-dd-500 focus:border-transparent transition"
                placeholder="••••••••"
              />
            </div>

            {login.error && (
              <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded-lg text-sm">
                Email ou senha incorretos
              </div>
            )}

            <button
              type="submit"
              disabled={login.isPending}
              className="w-full bg-dd-600 text-white py-2.5 rounded-lg font-medium hover:bg-dd-700 focus:outline-none focus:ring-2 focus:ring-dd-500 focus:ring-offset-2 disabled:opacity-50 disabled:cursor-not-allowed transition"
            >
              {login.isPending ? 'Entrando...' : 'Entrar'}
            </button>
          </form>

          <p className="text-center text-sm text-gray-600 mt-6">
            Não tem conta?{' '}
            <Link to="/register" className="text-dd-600 hover:text-dd-700 font-medium">
              Cadastre-se
            </Link>
          </p>
        </div>
      </div>
    </div>
  )
}
