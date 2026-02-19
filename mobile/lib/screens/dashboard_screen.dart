import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../models/transaction.dart';
import '../providers/auth_provider.dart';
import '../providers/payment_provider.dart';

final _currencyFmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
final _dateFmt      = DateFormat('dd/MM/yy HH:mm');

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  PaymentProvider? _paymentProvider;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_paymentProvider == null) {
      _paymentProvider = context.read<PaymentProvider>();
      _paymentProvider!.loadData();
      _paymentProvider!.startAutoRefresh();
    }
  }

  @override
  void dispose() {
    _paymentProvider?.stopAutoRefresh();
    super.dispose();
  }

  Future<void> _logout() async {
    context.read<PaymentProvider>().reset();
    await context.read<AuthProvider>().logout();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('🐾', style: TextStyle(fontSize: 22)),
            const SizedBox(width: 8),
            const Text('DogPay'),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) { if (v == 'logout') _logout(); },
            icon: const CircleAvatar(
              backgroundColor: ddPurple100,
              child: Icon(Icons.person, color: ddPurple600, size: 18),
            ),
            itemBuilder: (_) => [
              PopupMenuItem(
                enabled: false,
                child: Text(user?.name ?? '',
                    style: const TextStyle(fontWeight: FontWeight.w600, color: ddPurple800)),
              ),
              PopupMenuItem(
                enabled: false,
                child: Text(user?.email ?? '',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(value: 'logout', child: Text('Sair')),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        color: ddPurple600,
        onRefresh: () => context.read<PaymentProvider>().refresh(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _BalanceCard(userName: user?.name),
              const SizedBox(height: 16),
              _TransferCard(),
              const SizedBox(height: 16),
              _HistoryCard(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Balance Card ────────────────────────────────────────────────────────────

class _BalanceCard extends StatelessWidget {
  final String? userName;
  const _BalanceCard({this.userName});

  @override
  Widget build(BuildContext context) {
    return Consumer<PaymentProvider>(
      builder: (context, payments, child) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [ddPurple600, ddPurple800],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: ddPurple600.withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'SALDO DISPONÍVEL',
              style: TextStyle(color: ddPurple200, fontSize: 11,
                  fontWeight: FontWeight.w600, letterSpacing: 1.2),
            ),
            const SizedBox(height: 8),
            payments.loading
                ? Container(
                    height: 40, width: 160,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  )
                : Text(
                    _currencyFmt.format(payments.balance ?? 0),
                    style: const TextStyle(
                      color: Colors.white, fontSize: 34, fontWeight: FontWeight.w800),
                  ),
            const SizedBox(height: 12),
            if (userName != null)
              Text(userName!,
                  style: const TextStyle(color: ddPurple200, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

// ─── Transfer Card ────────────────────────────────────────────────────────────

class _TransferCard extends StatefulWidget {
  @override
  State<_TransferCard> createState() => _TransferCardState();
}

class _TransferCardState extends State<_TransferCard> {
  final _formKey   = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _amtCtrl   = TextEditingController();
  final _descCtrl  = TextEditingController();

  OverlayEntry? _loadingToast;

  void _showLoadingToast() {
    _loadingToast = OverlayEntry(
      builder: (_) => Positioned(
        top: 80,
        left: 32,
        right: 32,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: ddPurple800.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2.5),
                ),
                SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'Processando transferência...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    Overlay.of(context).insert(_loadingToast!);
    Future.delayed(const Duration(seconds: 5), _dismissLoadingToast);
  }

  void _dismissLoadingToast() {
    _loadingToast?.remove();
    _loadingToast = null;
  }

  @override
  void dispose() {
    _loadingToast?.remove();
    _emailCtrl.dispose();
    _amtCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final payments = context.read<PaymentProvider>();
    payments.clearTransferFeedback();
    _showLoadingToast();
    final ok = await payments.transfer(
      toEmail: _emailCtrl.text.trim(),
      amount: double.parse(_amtCtrl.text.replaceAll(',', '.')),
      description: _descCtrl.text.trim(),
    );
    _dismissLoadingToast();
    if (ok) {
      _emailCtrl.clear();
      _amtCtrl.clear();
      _descCtrl.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Transferir',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: ddPurple800)),
              const SizedBox(height: 16),

              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email do destinatário',
                  prefixIcon: Icon(Icons.person_outline, color: ddPurple600),
                ),
                validator: (v) =>
                    v == null || !v.contains('@') ? 'Email inválido' : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _amtCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Valor (R\$)',
                  prefixIcon: Icon(Icons.attach_money, color: ddPurple600),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Informe o valor';
                  final amt = double.tryParse(v.replaceAll(',', '.'));
                  if (amt == null || amt <= 0) return 'Valor inválido';
                  return null;
                },
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(
                  labelText: 'Descrição (opcional)',
                  prefixIcon: Icon(Icons.notes, color: ddPurple600),
                ),
              ),
              const SizedBox(height: 16),

              Consumer<PaymentProvider>(
                builder: (context, payments, child) {
                  return Column(
                    children: [
                      if (payments.transferSuccess != null)
                        _feedbackBox(payments.transferSuccess!, isError: false),
                      if (payments.transferError != null)
                        _feedbackBox(payments.transferError!, isError: true),
                      const SizedBox(height: 4),
                      ElevatedButton.icon(
                        onPressed: payments.transferring ? null : _submit,
                        icon: payments.transferring
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.send),
                        label: Text(payments.transferring ? 'Enviando...' : 'Transferir'),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _feedbackBox(String msg, {required bool isError}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isError ? Colors.red[50] : Colors.green[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isError ? Colors.red[200]! : Colors.green[200]!),
      ),
      child: Text(msg,
          style: TextStyle(
              color: isError ? Colors.red[700] : Colors.green[700], fontSize: 13)),
    );
  }
}

// ─── History Card ─────────────────────────────────────────────────────────────

class _HistoryCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<PaymentProvider>(
      builder: (context, payments, child) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Extrato',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w700, color: ddPurple800)),
                    IconButton(
                      icon: const Icon(Icons.refresh, color: ddPurple600),
                      onPressed: () => payments.refresh(),
                      tooltip: 'Atualizar',
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                if (payments.loading)
                  ...List.generate(3, (_) => _SkeletonTile())
                else if (payments.history.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Column(children: [
                        Text('📭', style: TextStyle(fontSize: 36)),
                        SizedBox(height: 8),
                        Text('Nenhuma transação ainda',
                            style: TextStyle(color: Colors.grey)),
                      ]),
                    ),
                  )
                else
                  ...payments.history.map(
                    (tx) => _TransactionTile(
                      tx: tx,
                      accountId: payments.accountId ?? '',
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final Transaction tx;
  final String accountId;

  const _TransactionTile({required this.tx, required this.accountId});

  @override
  Widget build(BuildContext context) {
    final isOutgoing = tx.fromAccountId == accountId;
    final color      = isOutgoing ? Colors.red[600]! : Colors.green[600]!;
    final bgColor    = isOutgoing ? Colors.red[50]!  : Colors.green[50]!;
    final icon       = isOutgoing ? Icons.arrow_upward : Icons.arrow_downward;
    final label      = tx.description?.isNotEmpty == true
        ? tx.description!
        : isOutgoing ? 'Transferência enviada' : 'Transferência recebida';

    String statusLabel;
    Color  statusColor;
    switch (tx.status) {
      case 'completed':
        statusLabel = 'concluída'; statusColor = Colors.green[700]!; break;
      case 'pending':
        statusLabel = 'processando'; statusColor = Colors.orange[700]!; break;
      default:
        statusLabel = 'falhou'; statusColor = Colors.red[700]!;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 2),
                Text(_dateFmt.format(tx.createdAt.toLocal()),
                    style: TextStyle(fontSize: 11, color: Colors.grey[500])),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isOutgoing ? '-' : '+'}${_currencyFmt.format(tx.amount)}',
                style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 13),
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(statusLabel,
                    style: TextStyle(color: statusColor, fontSize: 10,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SkeletonTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      height: 60,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}
