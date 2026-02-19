import { useState } from 'react'
import { useAuthStore } from '@/store/auth'
import { useLogout } from '@/hooks/useAuth'
import { useBalance, useTransactionHistory, useTransfer } from '@/hooks/usePayments'

function formatCurrency(value: number) {
  return new Intl.NumberFormat('pt-BR', {
    style: 'currency',
    currency: 'BRL',
  }).format(value)
}

function formatDate(dateStr: string) {
  return new Intl.DateTimeFormat('pt-BR', {
    dateStyle: 'short',
    timeStyle: 'short',
  }).format(new Date(dateStr))
}

export default function DashboardPage() {
  const user = useAuthStore((s) => s.user)
  const logout = useLogout()

  const { data: balanceData, isLoading: balanceLoading } = useBalance()
  const { data: history, isLoading: historyLoading } = useTransactionHistory()
  const transfer = useTransfer()

  const [toEmail, setToEmail] = useState('')
  const [amount, setAmount] = useState('')
  const [description, setDescription] = useState('')
  const [transferSuccess, setTransferSuccess] = useState<string | null>(null)
  const [transferError, setTransferError] = useState<string | null>(null)

  const handleTransfer = (e: React.FormEvent) => {
    e.preventDefault()
    setTransferSuccess(null)
    setTransferError(null)

    transfer.mutate(
      {
        to_email: toEmail,
        amount: parseFloat(amount),
        description,
      },
      {
        onSuccess: (res) => {
          setTransferSuccess(`Transferência #${res.data.transaction_id.slice(0, 8)} em processamento!`)
          setToEmail('')
          setAmount('')
          setDescription('')
        },
        onError: (err: unknown) => {
          const error = err as { response?: { data?: { error?: string } } }
          setTransferError(error?.response?.data?.error || 'Erro ao processar transferência')
        },
      },
    )
  }

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <header className="bg-white border-b border-gray-200 shadow-sm">
        <div className="max-w-5xl mx-auto px-4 py-4 flex items-center justify-between">
          <div className="flex items-center gap-3">
            <span className="text-2xl">🐾</span>
            <span className="text-xl font-bold text-gray-900">DogPay</span>
          </div>
          <div className="flex items-center gap-4">
            <span className="text-sm text-gray-600">
              Olá, <strong>{user?.name}</strong>
            </span>
            <button
              onClick={logout}
              className="text-sm text-gray-500 hover:text-red-600 transition px-3 py-1.5 rounded-lg hover:bg-red-50"
            >
              Sair
            </button>
          </div>
        </div>
      </header>

      <main className="max-w-5xl mx-auto px-4 py-8 space-y-6">
        {/* Balance Card */}
        <div className="bg-gradient-to-r from-dd-600 to-dd-800 rounded-2xl p-6 text-white shadow-lg">
          <p className="text-dd-200 text-sm font-medium uppercase tracking-wide">
            Saldo disponível
          </p>
          <div className="mt-2">
            {balanceLoading ? (
              <div className="h-10 w-40 bg-dd-500 rounded-lg animate-pulse" />
            ) : (
              <p className="text-4xl font-bold">
                {formatCurrency(balanceData?.balance ?? 0)}
              </p>
            )}
          </div>
          <p className="text-dd-200 text-sm mt-2">{user?.email}</p>
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          {/* Transfer Form */}
          <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-6">
            <h2 className="text-lg font-semibold text-gray-900 mb-4">
              Transferir
            </h2>

            <form onSubmit={handleTransfer} className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Email do destinatário
                </label>
                <input
                  type="email"
                  value={toEmail}
                  onChange={(e) => setToEmail(e.target.value)}
                  required
                  className="w-full px-4 py-2.5 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-dd-500 focus:border-transparent transition text-sm"
                  placeholder="destinatario@email.com"
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Valor (R$)
                </label>
                <input
                  type="number"
                  value={amount}
                  onChange={(e) => setAmount(e.target.value)}
                  required
                  min="0.01"
                  step="0.01"
                  className="w-full px-4 py-2.5 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-dd-500 focus:border-transparent transition text-sm"
                  placeholder="0,00"
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Descrição (opcional)
                </label>
                <input
                  type="text"
                  value={description}
                  onChange={(e) => setDescription(e.target.value)}
                  className="w-full px-4 py-2.5 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-dd-500 focus:border-transparent transition text-sm"
                  placeholder="Ex: Almoço"
                />
              </div>

              {transferSuccess && (
                <div className="bg-green-50 border border-green-200 text-green-700 px-4 py-3 rounded-lg text-sm">
                  {transferSuccess}
                </div>
              )}

              {transferError && (
                <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded-lg text-sm">
                  {transferError}
                </div>
              )}

              <button
                type="submit"
                disabled={transfer.isPending}
                className="w-full bg-dd-600 text-white py-2.5 rounded-lg font-medium hover:bg-dd-700 focus:outline-none focus:ring-2 focus:ring-dd-500 focus:ring-offset-2 disabled:opacity-50 disabled:cursor-not-allowed transition text-sm"
              >
                {transfer.isPending ? 'Enviando...' : 'Transferir'}
              </button>
            </form>
          </div>

          {/* Transaction History */}
          <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-6">
            <h2 className="text-lg font-semibold text-gray-900 mb-4">
              Extrato
            </h2>

            {historyLoading ? (
              <div className="space-y-3">
                {[...Array(3)].map((_, i) => (
                  <div key={i} className="h-14 bg-gray-100 rounded-lg animate-pulse" />
                ))}
              </div>
            ) : !history?.length ? (
              <div className="text-center py-8 text-gray-400">
                <div className="text-3xl mb-2">📭</div>
                <p className="text-sm">Nenhuma transação ainda</p>
              </div>
            ) : (
              <div className="space-y-3 max-h-80 overflow-y-auto">
                {history.map((tx: {
                  id: string
                  from_account_id: string | null
                  to_account_id: string
                  amount: number
                  status: string
                  description: string | null
                  created_at: string
                }) => {
                  const userAccountId = balanceData?.account_id
                  const isOutgoing = tx.from_account_id === userAccountId

                  return (
                    <div
                      key={tx.id}
                      className="flex items-center justify-between p-3 bg-gray-50 rounded-xl"
                    >
                      <div className="flex items-center gap-3">
                        <div
                          className={`w-8 h-8 rounded-full flex items-center justify-center text-sm ${
                            isOutgoing
                              ? 'bg-red-100 text-red-600'
                              : 'bg-green-100 text-green-600'
                          }`}
                        >
                          {isOutgoing ? '↑' : '↓'}
                        </div>
                        <div>
                          <p className="text-sm font-medium text-gray-900">
                            {tx.description || (isOutgoing ? 'Transferência enviada' : 'Transferência recebida')}
                          </p>
                          <p className="text-xs text-gray-400">
                            {formatDate(tx.created_at)}
                          </p>
                        </div>
                      </div>
                      <div className="text-right">
                        <p
                          className={`text-sm font-semibold ${
                            isOutgoing ? 'text-red-600' : 'text-green-600'
                          }`}
                        >
                          {isOutgoing ? '-' : '+'}{formatCurrency(tx.amount)}
                        </p>
                        <span
                          className={`text-xs px-2 py-0.5 rounded-full ${
                            tx.status === 'completed'
                              ? 'bg-green-100 text-green-600'
                              : tx.status === 'pending'
                              ? 'bg-yellow-100 text-yellow-600'
                              : 'bg-red-100 text-red-600'
                          }`}
                        >
                          {tx.status === 'completed' ? 'concluída' : tx.status === 'pending' ? 'processando' : 'falhou'}
                        </span>
                      </div>
                    </div>
                  )
                })}
              </div>
            )}
          </div>
        </div>
      </main>
    </div>
  )
}
