class CheckoutTotals {
  const CheckoutTotals({
    required this.subtotal,
    required this.shipping,
    required this.tax,
  });

  static const taxRate = 0.13;
  static const shippingFee = 8.0;

  final double subtotal;
  final double shipping;
  final double tax;

  double get total => subtotal + shipping + tax;

  factory CheckoutTotals.fromSubtotal(double subtotal) {
    return CheckoutTotals(
      subtotal: subtotal,
      shipping: shippingFee,
      tax: subtotal * taxRate,
    );
  }
}
