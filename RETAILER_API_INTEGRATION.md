# Retailer API Integration Guide

This document explains how to use the newly integrated retailer API endpoints in your Flutter app.

## Available API Endpoints

The following retailer API endpoints have been integrated into `auth_service.dart`:

### 1. Retailer Dashboard (`retailer_dashboard.php`)
- **Method**: `AuthService.loadRetailerDashboard()`
- **Purpose**: Load comprehensive dashboard data for retailers
- **Usage**: Already implemented in the retailer dashboard

### 2. Agreements (`agreements.php`)
- **Methods**:
  - `AuthService.loadRetailerAgreements()` - Load all agreements
  - `AuthService.getRetailerAgreement(agreementId: int)` - Get specific agreement
- **Purpose**: Manage retailer agreements and contracts
- **Example**:
```dart
// Load all agreements
final result = await AuthService.loadRetailerAgreements();
if (result['status'] == 'success') {
  final agreements = result['data']['agreements'] ?? [];
  // Process agreements data
}

// Get specific agreement
final agreement = await AuthService.getRetailerAgreement(agreementId: 123);
```

### 3. Profile (`profile.php`)
- **Methods**:
  - `AuthService.getRetailerProfile()` - Get retailer profile
  - `AuthService.updateRetailerProfile(...)` - Update retailer profile
- **Purpose**: Manage retailer profile information
- **Example**:
```dart
// Get profile
final profile = await AuthService.getRetailerProfile();

// Update profile
final result = await AuthService.updateRetailerProfile(
  firstName: 'John',
  lastName: 'Doe',
  email: 'john.doe@example.com',
  phone: '+1234567890',
);
```

### 4. Store Products (`store_products.php`)
- **Methods**:
  - `AuthService.loadRetailerStoreProducts()` - Load store products
  - `AuthService.addRetailerStoreProduct(...)` - Add product to store
  - `AuthService.updateRetailerStoreProduct(...)` - Update store product
- **Purpose**: Manage products in the retailer's store
- **Example**:
```dart
// Load store products
final products = await AuthService.loadRetailerStoreProducts(
  search: 'rice',
  category: 'food',
  page: 1,
  limit: 20,
);

// Add product to store
final result = await AuthService.addRetailerStoreProduct(
  productId: 123,
  price: 25.50,
  notes: 'Fresh rice',
  stockQuantity: 100,
);

// Update store product
final updateResult = await AuthService.updateRetailerStoreProduct(
  storeProductId: 456,
  price: 26.00,
  stockQuantity: 95,
  isActive: true,
);
```

### 5. Product Catalog (`product_catalog.php`)
- **Methods**:
  - `AuthService.loadRetailerProductCatalog()` - Load product catalog
  - `AuthService.getRetailerProductCatalogItem(productId: int)` - Get specific catalog item
  - `AuthService.getRetailerProductCategories()` - Get product categories
- **Purpose**: Browse and manage the product catalog
- **Example**:
```dart
// Load product catalog
final catalog = await AuthService.loadRetailerProductCatalog(
  search: 'vegetables',
  category: 'fresh_produce',
  sortBy: 'name',
  sortOrder: 'asc',
  page: 1,
  limit: 20,
);

// Get specific catalog item
final item = await AuthService.getRetailerProductCatalogItem(productId: 789);

// Get categories
final categories = await AuthService.getRetailerProductCategories();
```

## Integration in Retailer Dashboard

The retailer dashboard (`lib/pages/retailer_dashboard.dart`) has been updated with buttons to test all the new API endpoints:

1. **Agreements** - Loads and displays agreements data
2. **Profile** - Loads and displays profile information
3. **Store Products** - Loads and displays store products
4. **Product Catalog** - Loads and displays product catalog

## API Response Format

All API endpoints return responses in the following format:

```json
{
  "status": "success" | "error",
  "message": "Description of the result",
  "data": {
    // Actual data from the API
  },
  "code": "API_SPECIFIC_CODE"
}
```

## Error Handling

All methods include comprehensive error handling:

- **Network errors**: Connection timeouts, network failures
- **HTTP errors**: Non-200 status codes
- **Session validation**: Automatic retailer session validation
- **JSON parsing**: Invalid JSON response handling

## Session Management

All retailer API methods automatically:
1. Validate the current retailer session
2. Extract the retailer ID from the session
3. Include the retailer ID in API requests
4. Handle session expiration gracefully

## Testing the Integration

To test the integration:

1. Login as a retailer
2. Navigate to the retailer dashboard
3. Use the new buttons in the "Quick Actions" section:
   - Click "Agreements" to test agreements API
   - Click "Profile" to test profile API
   - Click "Store Products" to test store products API
   - Click "Product Catalog" to test product catalog API

## Base URL Configuration

The API endpoints use the base URL configured in `auth_service.dart`:
```dart
static const String baseUrl = "https://dtisrpmonitoring.bccbsis.com/api";
```

All retailer endpoints are accessed at:
- `$baseUrl/retailer/agreements.php`
- `$baseUrl/retailer/profile.php`
- `$baseUrl/retailer/store_products.php`
- `$baseUrl/retailer/product_catalog.php`
- `$baseUrl/retailer/retailer_dashboard.php`

## Next Steps

1. Test all endpoints with your backend API
2. Implement proper UI components to display the data
3. Add loading states and error handling in your UI
4. Implement data caching if needed
5. Add pagination support for large datasets
