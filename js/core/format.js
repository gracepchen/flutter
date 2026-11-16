// Number formatting (lib/util/format.dart).
(function () {
  const cad = new Intl.NumberFormat('en-CA', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
  const whole = new Intl.NumberFormat('en-CA', { maximumFractionDigits: 0 });
  /** U+2212 MINUS SIGN. */
  const MINUS = '−';

  /** `$124,820.42` (a negative shows as `−$812.50`). */
  function formatCad(v) { return (v < 0 ? MINUS : '') + '$' + cad.format(Math.abs(v)); }
  /** `+$1,284.20` or `−$812.50` */
  function formatSignedCad(v) { return (v < 0 ? MINUS : '+') + '$' + cad.format(Math.abs(v)); }
  /** `+1.04%` or `−0.80%` */
  function formatSignedPercent(v, decimals = 2) { return (v < 0 ? MINUS : '+') + Math.abs(v).toFixed(decimals) + '%'; }
  /** `1,234.56` (no currency symbol). */
  function formatPrice(v) { return (v < 0 ? MINUS : '') + cad.format(Math.abs(v)); }
  /** `3,100` */
  function formatWhole(v) { return whole.format(v); }

  const MONTHS = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
  const MON = MONTHS.map((m) => m.slice(0, 3));
  /** `Sep 5, 2021` */
  function formatDate(d) { return `${MON[d.getMonth()]} ${d.getDate()}, ${d.getFullYear()}`; }
  /** `Sep 5` */
  function formatShortDate(d) { return `${MON[d.getMonth()]} ${d.getDate()}`; }

  /** Stand-in for a hidden amount (`hiddenAmount` in Flutter). Add the `$`
   *  or currency yourself, e.g. '$' + IE.HIDDEN or IE.HIDDEN + ' CAD'. */
  const HIDDEN = '\u2022\u2022\u2022\u2022\u2022\u2022';

  Object.assign(IE, { MINUS, HIDDEN, MONTHS, MON, formatCad, formatSignedCad, formatSignedPercent, formatPrice, formatWhole, formatDate, formatShortDate });
})();
