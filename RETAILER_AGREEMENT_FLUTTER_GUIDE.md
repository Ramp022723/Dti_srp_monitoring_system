# Retailer Agreement Flutter Page - Implementation Guide

This document explains the Flutter implementation of the retailer agreement page, which is a mobile version of the PHP `retailer_agreement.php` frontend.

## 📱 **Overview**

The `RetailerAgreementPage` is a comprehensive Flutter page that replicates all the functionality of the PHP version, including:

- ✅ **Agreement List Display** - Shows all retailer agreements in a card-based layout
- ✅ **Agreement Details Modal** - Full-screen modal with complete agreement information
- ✅ **Status Management** - Visual status indicators (Active, Expired, Terminated)
- ✅ **Agreement Response** - Radio buttons for Agree/Disagree responses
- ✅ **Image Display** - Shows agreement photos with error handling
- ✅ **Download Functionality** - Download button for agreements
- ✅ **Responsive Design** - Mobile-optimized layout
- ✅ **Error Handling** - Comprehensive error states and loading indicators

## 🎨 **Design Features**

### **Color Scheme**
Matches the PHP version's Bootstrap theme:
```dart
static const Color primaryBlue = Color(0xFF2563EB);
static const Color secondaryBlue = Color(0xFF1D4ED8);
static const Color lightBlue = Color(0xFFDBEAFE);
static const Color successGreen = Color(0xFF28A745);
static const Color dangerRed = Color(0xFFDC3545);
static const Color warningOrange = Color(0xFFFD7E14);
```

### **Typography**
Uses Google Fonts Inter for consistency:
```dart
GoogleFonts.inter(
  fontSize: 16,
  fontWeight: FontWeight.w600,
  color: textDark,
)
```

## 🔧 **API Integration**

### **AuthService Methods Used**

1. **Load Agreements**
```dart
final result = await AuthService.loadRetailerAgreements();
```

2. **Update Agreement Status**
```dart
final result = await AuthService.updateRetailerAgreementStatus(
  agreementId: agreementId,
  acceptanceStatus: status,
);
```

### **API Endpoint**
- **URL**: `https://dtisrpmonitoring.bccbsis.com/api/retailer/agreements.php`
- **Method**: POST
- **Actions**: `list`, `get`, `update_status`

## 📋 **Page Structure**

### **1. Main Page (`RetailerAgreementPage`)**
```dart
Scaffold(
  appBar: AppBar(...),           // Header with title and refresh
  body: _buildAgreementsList(),  // Main content area
)
```

### **2. Content States**
- **Loading State**: `CircularProgressIndicator`
- **Error State**: Error message with retry button
- **Empty State**: No agreements found message
- **Content State**: Grid of agreement cards

### **3. Agreement Card**
```dart
Container(
  decoration: BoxDecoration(...), // Card styling
  child: InkWell(
    onTap: () => _showAgreementModal(agreement),
    child: Column(
      children: [
        // Header with status badge
        // Date range
        // Agreement preview
        // Action buttons
      ],
    ),
  ),
)
```

### **4. Agreement Modal**
```dart
showModalBottomSheet(
  context: context,
  isScrollControlled: true,
  builder: (context) => _buildAgreementModal(agreement),
)
```

## 🎯 **Key Features**

### **1. Status Management**
```dart
String _getStatusText(String status, String endDate) {
  final currentDate = DateTime.now();
  final endDateTime = DateTime.tryParse(endDate) ?? currentDate;
  
  if (status == 'active' && endDateTime.isAfter(currentDate)) {
    return 'Active';
  } else if (endDateTime.isBefore(currentDate)) {
    return 'Expired';
  } else {
    return status.toUpperCase();
  }
}
```

### **2. Date Formatting**
```dart
String _formatDate(String? dateString) {
  if (dateString == null || dateString.isEmpty) return 'N/A';
  
  try {
    final date = DateTime.parse(dateString);
    return '${_getMonthName(date.month)} ${date.day}, ${date.year}';
  } catch (e) {
    return 'Invalid Date';
  }
}
```

### **3. Agreement Preview**
```dart
String _getAgreementPreview(String agreementText) {
  if (agreementText.isEmpty) return 'No agreement text available';
  
  final preview = agreementText.length > 200 
      ? '${agreementText.substring(0, 200)}...'
      : agreementText;
  
  return preview;
}
```

### **4. Image Handling**
```dart
Image.network(
  'https://dtisrpmonitoring.bccbsis.com/uploads/${agreement['agreement_photo']}',
  fit: BoxFit.cover,
  errorBuilder: (context, error, stackTrace) {
    return Container(
      // Error state UI
    );
  },
)
```

## 🔄 **Navigation Integration**

### **From Retailer Dashboard**
The agreements page is accessible from the retailer dashboard:

```dart
// In retailer_dashboard.dart
ElevatedButton.icon(
  onPressed: () => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => const RetailerAgreementPage(),
    ),
  ),
  icon: const Icon(Icons.description),
  label: const Text('Agreements'),
)
```

## 📱 **Mobile Optimizations**

### **1. Responsive Layout**
- Single column grid for mobile
- Full-width cards
- Touch-friendly button sizes

### **2. Modal Design**
- Bottom sheet modal (mobile-friendly)
- Scrollable content
- Handle bar for easy dismissal

### **3. Touch Interactions**
- Tap to view agreement details
- Swipe gestures for modal dismissal
- Pull-to-refresh functionality

## 🎨 **UI Components**

### **1. Status Badges**
```dart
Container(
  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
  decoration: BoxDecoration(
    color: statusColor,
    borderRadius: BorderRadius.circular(20),
  ),
  child: Text(statusText, style: TextStyle(color: Colors.white)),
)
```

### **2. Agreement Cards**
- Rounded corners (12px radius)
- Subtle shadows
- Hover effects (on web)
- InkWell ripple effects

### **3. Modal Components**
- Handle bar for dragging
- Scrollable content area
- Fixed footer with actions
- Close button in header

## 🔧 **Error Handling**

### **1. Network Errors**
```dart
try {
  final result = await AuthService.loadRetailerAgreements();
  // Handle success
} catch (e) {
  setState(() {
    _error = 'Connection error: $e';
    _isLoading = false;
  });
}
```

### **2. Image Loading Errors**
```dart
errorBuilder: (context, error, stackTrace) {
  return Container(
    color: bgLight,
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.image_not_supported, size: 48, color: textLight),
        Text('Photo not available', style: TextStyle(color: textLight)),
      ],
    ),
  );
}
```

### **3. Empty States**
```dart
Widget _buildEmptyState() {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.description_outlined, size: 80, color: textLight.withOpacity(0.5)),
        Text('No Agreements Found', style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold)),
        Text('You don\'t have any agreements yet...', textAlign: TextAlign.center),
        ElevatedButton.icon(onPressed: () => Navigator.pop(context), ...),
      ],
    ),
  );
}
```

## 🚀 **Usage Example**

```dart
// Navigate to agreements page
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const RetailerAgreementPage(),
  ),
);

// The page will automatically:
// 1. Load agreements from API
// 2. Display in card format
// 3. Handle user interactions
// 4. Update agreement status
// 5. Show success/error messages
```

## 📊 **Data Flow**

```
User opens page
    ↓
_loadAgreements() called
    ↓
AuthService.loadRetailerAgreements()
    ↓
API call to agreements.php
    ↓
JSON response with agreements data
    ↓
UI updates with agreement cards
    ↓
User taps agreement card
    ↓
Modal opens with full details
    ↓
User selects Agree/Disagree
    ↓
AuthService.updateRetailerAgreementStatus()
    ↓
API call to update status
    ↓
Success/error message shown
```

## 🔮 **Future Enhancements**

1. **Offline Support** - Cache agreements for offline viewing
2. **Push Notifications** - Notify when new agreements are available
3. **Search/Filter** - Add search functionality for agreements
4. **PDF Viewer** - In-app PDF viewing for agreements
5. **Signature Capture** - Digital signature for agreement acceptance
6. **Agreement Templates** - Pre-defined agreement templates

## 🎯 **Key Differences from PHP Version**

| Feature | PHP Version | Flutter Version |
|---------|-------------|-----------------|
| Layout | Bootstrap Grid | Flutter GridView |
| Modals | Bootstrap Modal | Bottom Sheet Modal |
| Styling | CSS Classes | Flutter Widgets |
| Navigation | Page Redirects | Navigator.push |
| State Management | Server-side | Client-side State |
| Images | HTML img | Image.network |
| Forms | HTML Forms | Flutter Form Widgets |

The Flutter version maintains all the functionality of the PHP version while providing a native mobile experience with better performance and user interaction patterns.
