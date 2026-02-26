export function formatRupiah(value: number): string {
  if (value === null || value === undefined || isNaN(value)) return "Rp 0";
  return "Rp " + value.toLocaleString("id-ID", { minimumFractionDigits: 0 });
}

export function formatDate(dateStr: string | null | undefined): string {
  if (!dateStr) return "-";
  try {
    const date = new Date(dateStr);
    return date.toLocaleDateString("id-ID", {
      day: "2-digit",
      month: "short",
      year: "numeric",
      hour: "2-digit",
      minute: "2-digit",
    });
  } catch {
    return dateStr;
  }
}

export function formatNumber(value: number): string {
  if (value === null || value === undefined || isNaN(value)) return "0";
  return value.toLocaleString("id-ID", { maximumFractionDigits: 2 });
}
