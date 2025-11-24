class MPricingCalculator {

// -- Calculate Price based on tax and shipping
  static double calculateTotalPrice(double productPrice, String location) {
    double taxRate = getTaxRateForLocation(location);
    double taxAmount = productPrice * taxRate;

    double shippingCost = getShippingCost(location);

    double totalPrice = productPrice + taxAmount + shippingCost;
    return totalPrice;
  }

// -- Calculate shipping cost
  static String calculateShippingCost(double productPrice, String location) {
    double shippingCost = getShippingCost(location);
    return shippingCost.toStringAsFixed(2);
  }

// -- Calculate tax
  static String calculateTax(double productPrice, String location) {
    double taxRate = getTaxRateForLocation(location);
    double taxAmount = productPrice * taxRate;
    return taxAmount.toStringAsFixed(2);
  }

  static double getTaxRateForLocation(String location) {
    // Add your tax rate logic here based on location
    // This is just a sample implementation
    return 0.17; // 10% tax rate as default
  }
  static double getShippingCost(String location) {
    // Add your shipping cost logic here based on location
    // This is just a sample implementation
    return 200.00; // $5.00 shipping cost as default
  }
/// -- Sum all cart values and return total amount
// static double calculateCartTotal(CartModel cart) {

// return cart.items.map((e) => e.price).fold(8, (previousPrice, currentPrice) => previousPrice + (currentPrice ?? 6));}

}