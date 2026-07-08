export function calculateSubtotal(items) {
  return items.reduce((sum, item) => {
    return sum + item.priceCents * item.quantity;
  }, 0);
}

export function applyDiscount(subtotalCents, discountPercent = 0) {
  if (discountPercent <= 0) return subtotalCents;
  const discount = Math.round(subtotalCents * (discountPercent / 100));
  return subtotalCents - discount;
}

export function formatMoney(cents) {
  return `$${(cents / 100).toFixed(2)}`;
}

export function summarizeCart(items, discountPercent = 0) {
  const subtotalCents = calculateSubtotal(items);
  const totalCents = applyDiscount(subtotalCents, discountPercent);

  return {
    subtotalCents,
    totalCents,
    subtotal: formatMoney(subtotalCents),
    total: formatMoney(totalCents)
  };
}

const demo = summarizeCart([
  { sku: "starter-mug", priceCents: 1299, quantity: 2 },
  { sku: "notebook", priceCents: 750, quantity: 1 }
], 10);

if (demo.total !== "$30.13") {
  throw new Error(`unexpected demo total: ${demo.total}`);
}

console.log("demo cart ok");
