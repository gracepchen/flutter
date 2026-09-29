/// A U.S.-listed security that can be bought in fractions. Prototype data.
class FractionalSecurity {
  const FractionalSecurity(
    this.symbol,
    this.name,
    this.type,
    this.exchange,
    this.marketCap,
    this.sector,
  );

  final String symbol;
  final String name;

  /// "Stock" or "ETF".
  final String type;

  /// "NASDAQ", "NYSE" or "NYSE Arca".
  final String exchange;

  /// "Mega", "Large" or "Mid".
  final String marketCap;
  final String sector;
}

abstract final class MockFractional {
  static const List<String> exchanges = ['NASDAQ', 'NYSE', 'NYSE Arca'];
  static const List<String> marketCaps = ['Mega', 'Large', 'Mid'];
  static const List<String> sectors = [
    'Communication',
    'Consumer',
    'Diversified',
    'Energy',
    'Financials',
    'Health Care',
    'Technology',
  ];

  static const List<FractionalSecurity> all = [
    FractionalSecurity('AAPL', 'Apple Inc.', 'Stock', 'NASDAQ', 'Mega', 'Technology'),
    FractionalSecurity('MSFT', 'Microsoft Corporation', 'Stock', 'NASDAQ', 'Mega', 'Technology'),
    FractionalSecurity('GOOG', 'Alphabet Inc. Class C', 'Stock', 'NASDAQ', 'Mega', 'Communication'),
    FractionalSecurity('AMZN', 'Amazon.com Inc.', 'Stock', 'NASDAQ', 'Mega', 'Consumer'),
    FractionalSecurity('NVDA', 'NVIDIA Corporation', 'Stock', 'NASDAQ', 'Mega', 'Technology'),
    FractionalSecurity('META', 'Meta Platforms Inc. Class A', 'Stock', 'NASDAQ', 'Mega', 'Communication'),
    FractionalSecurity('TSLA', 'Tesla Inc.', 'Stock', 'NASDAQ', 'Mega', 'Consumer'),
    FractionalSecurity('NFLX', 'Netflix Inc.', 'Stock', 'NASDAQ', 'Large', 'Communication'),
    FractionalSecurity('COST', 'Costco Wholesale Corporation', 'Stock', 'NASDAQ', 'Large', 'Consumer'),
    FractionalSecurity('PEP', 'PepsiCo Inc.', 'Stock', 'NASDAQ', 'Large', 'Consumer'),
    FractionalSecurity('JPM', 'JPMorgan Chase & Co.', 'Stock', 'NYSE', 'Mega', 'Financials'),
    FractionalSecurity('V', 'Visa Inc. Class A', 'Stock', 'NYSE', 'Mega', 'Financials'),
    FractionalSecurity('MA', 'Mastercard Inc. Class A', 'Stock', 'NYSE', 'Large', 'Financials'),
    FractionalSecurity('JNJ', 'Johnson & Johnson', 'Stock', 'NYSE', 'Large', 'Health Care'),
    FractionalSecurity('PFE', 'Pfizer Inc.', 'Stock', 'NYSE', 'Large', 'Health Care'),
    FractionalSecurity('WMT', 'Walmart Inc.', 'Stock', 'NYSE', 'Mega', 'Consumer'),
    FractionalSecurity('PG', 'Procter & Gamble Company', 'Stock', 'NYSE', 'Large', 'Consumer'),
    FractionalSecurity('KO', 'Coca-Cola Company', 'Stock', 'NYSE', 'Large', 'Consumer'),
    FractionalSecurity('DIS', 'Walt Disney Company', 'Stock', 'NYSE', 'Large', 'Communication'),
    FractionalSecurity('VZ', 'Verizon Communications Inc.', 'Stock', 'NYSE', 'Large', 'Communication'),
    FractionalSecurity('XOM', 'Exxon Mobil Corporation', 'Stock', 'NYSE', 'Large', 'Energy'),
    FractionalSecurity('SHEL', 'Shell plc American Depositary Shares', 'Stock', 'NYSE', 'Large', 'Energy'),
    FractionalSecurity('HD', 'Home Depot Inc.', 'Stock', 'NYSE', 'Large', 'Consumer'),
    FractionalSecurity('F', 'Ford Motor Company', 'Stock', 'NYSE', 'Mid', 'Consumer'),
    FractionalSecurity('SPY', 'SPDR S&P 500 ETF Trust', 'ETF', 'NYSE Arca', 'Mega', 'Diversified'),
    FractionalSecurity('VOO', 'Vanguard S&P 500 ETF', 'ETF', 'NYSE Arca', 'Mega', 'Diversified'),
    FractionalSecurity('IVV', 'iShares Core S&P 500 ETF', 'ETF', 'NYSE Arca', 'Mega', 'Diversified'),
    FractionalSecurity('VTI', 'Vanguard Total Stock Market ETF', 'ETF', 'NYSE Arca', 'Mega', 'Diversified'),
    FractionalSecurity('QQQ', 'Invesco QQQ Trust', 'ETF', 'NASDAQ', 'Mega', 'Technology'),
    FractionalSecurity('SCHD', 'Schwab U.S. Dividend Equity ETF', 'ETF', 'NYSE Arca', 'Large', 'Diversified'),
    FractionalSecurity('VYM', 'Vanguard High Dividend Yield ETF', 'ETF', 'NYSE Arca', 'Large', 'Diversified'),
    FractionalSecurity('XLK', 'Technology Select Sector SPDR Fund', 'ETF', 'NYSE Arca', 'Large', 'Technology'),
    FractionalSecurity('DIA', 'SPDR Dow Jones Industrial Average ETF', 'ETF', 'NYSE Arca', 'Large', 'Diversified'),
    FractionalSecurity('IWM', 'iShares Russell 2000 ETF', 'ETF', 'NYSE Arca', 'Large', 'Diversified'),
  ];
}
