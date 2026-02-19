import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { paymentService } from '@/services/api'

export function useBalance() {
  return useQuery({
    queryKey: ['balance'],
    queryFn: () => paymentService.getBalance().then((r) => r.data),
    refetchInterval: 10_000,
  })
}

export function useTransactionHistory() {
  return useQuery({
    queryKey: ['history'],
    queryFn: () => paymentService.getHistory().then((r) => r.data.transactions),
    refetchInterval: 5_000,
  })
}

export function useTransfer() {
  const qc = useQueryClient()

  return useMutation({
    mutationFn: (data: { to_email: string; amount: number; description?: string }) =>
      paymentService.transfer(data),
    onSuccess: () => {
      // Invalidate balance and history after transfer
      setTimeout(() => {
        qc.invalidateQueries({ queryKey: ['balance'] })
        qc.invalidateQueries({ queryKey: ['history'] })
      }, 1500)
    },
  })
}
