# CrabSense UI Components Library

This directory contains reusable UI components following Material Design 3 principles and CrabSense brand guidelines.

## Components Overview

### Cards

#### CrabSenseCard
A glassmorphism card component with frosted glass effect.

**Features:**
- Frosted glass/glassmorphism effect with backdrop blur
- Configurable border radius (default 16dp)
- Optional tap callback
- Customizable padding, margin, elevation
- Optional border with primary color

**Usage:**
```dart
CrabSenseCard(
  onTap: () => print('Card tapped'),
  child: Text('Content'),
)
```

### Buttons

#### PrimaryButton
Elevated button with primary brand color for main actions.

**Features:**
- Loading state with spinner
- Optional leading icon
- Full-width option
- Custom padding support

**Usage:**
```dart
PrimaryButton(
  onPressed: () {},
  child: Text('Submit'),
  isLoading: false,
  fullWidth: true,
)
```

#### SecondaryButton
Outlined button with primary color outline for secondary actions.

**Features:**
- Same features as PrimaryButton
- Outlined style instead of filled

**Usage:**
```dart
SecondaryButton(
  onPressed: () {},
  icon: Icon(Icons.edit),
  child: Text('Edit'),
)
```

#### TextButtonWidget
Borderless text button for tertiary actions.

**Features:**
- Minimal style without background
- Loading state support
- Optional icon

**Usage:**
```dart
TextButtonWidget(
  onPressed: () {},
  child: Text('Cancel'),
)
```

#### IconButtonWidget
Circular icon button for compact actions.

**Features:**
- Customizable icon size
- Optional tooltip
- Custom colors support
- Configurable padding

**Usage:**
```dart
IconButtonWidget(
  onPressed: () {},
  icon: Icons.settings,
  tooltip: 'Settings',
)
```

#### FABButton
Floating Action Button for main screen actions.

**Features:**
- Standard, mini, and extended variants
- Optional label for extended FAB
- Hero tag support for animations
- Custom colors

**Usage:**
```dart
FABButton(
  onPressed: () {},
  icon: Icons.add,
  label: 'Add Item', // Optional for extended FAB
)
```

### Input Fields

#### TextInputField
Reusable text field with validation and styling.

**Features:**
- Validation support
- Obscure text for passwords
- Prefix and suffix icons
- Max length, max lines
- Input formatters
- Various keyboard types
- Read-only and disabled states

**Usage:**
```dart
TextInputField(
  controller: controller,
  labelText: 'Email',
  hintText: 'Enter your email',
  keyboardType: TextInputType.emailAddress,
  validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
)
```

#### DropdownField
Reusable dropdown selector with validation.

**Features:**
- Generic type support
- Custom item label builder
- Validation support
- Full Material Design styling

**Usage:**
```dart
DropdownField<String>(
  items: ['Option 1', 'Option 2'],
  value: selectedValue,
  onChanged: (value) => setState(() => selectedValue = value),
  labelText: 'Select Option',
)
```

#### DatePickerField
Reusable date picker input field.

**Features:**
- Material date picker integration
- Custom date format support
- First/last date constraints
- Clear button
- Readonly state

**Usage:**
```dart
DatePickerField(
  selectedDate: selectedDate,
  onDateSelected: (date) => setState(() => selectedDate = date),
  labelText: 'Select Date',
  firstDate: DateTime(2020),
  lastDate: DateTime(2030),
)
```

### Loading States

#### SkeletonLoader
Animated placeholder for loading states.

**Features:**
- Shimmer animation effect
- Customizable size and colors
- Smooth gradient animation

**Usage:**
```dart
SkeletonLoader(
  width: 200,
  height: 20,
  borderRadius: 8,
)
```

#### SkeletonText
Pre-configured skeleton for text lines.

**Features:**
- Multiple line support
- Configurable line height and spacing
- Last line width factor for realistic appearance

**Usage:**
```dart
SkeletonText(
  lines: 3,
  lineHeight: 16,
  spacing: 8,
)
```

#### SkeletonCircle
Pre-configured skeleton for circular avatars.

**Usage:**
```dart
SkeletonCircle(size: 48)
```

### Error States

#### ErrorStateWidget
Full-screen error display with retry capability.

**Features:**
- Custom title and message
- Optional icon
- Retry button with callback
- Additional action buttons support

**Usage:**
```dart
ErrorStateWidget(
  title: 'Error',
  message: 'Something went wrong',
  onRetry: () => loadData(),
)
```

#### EmptyStateWidget
Full-screen empty state display.

**Usage:**
```dart
EmptyStateWidget(
  title: 'No Items',
  message: 'You have no items yet',
  icon: Icons.inbox,
  actionButton: PrimaryButton(
    onPressed: () => addItem(),
    child: Text('Add Item'),
  ),
)
```

#### NetworkErrorWidget
Pre-configured error for network failures.

**Usage:**
```dart
NetworkErrorWidget(
  onRetry: () => retryConnection(),
)
```

#### TimeoutErrorWidget
Pre-configured error for timeout failures.

**Usage:**
```dart
TimeoutErrorWidget(
  onRetry: () => retryRequest(),
)
```

## Importing Components

Import all components at once:
```dart
import 'package:crabsensemobile/shared/widgets/widgets.dart';
```

Or import individual components:
```dart
import 'package:crabsensemobile/shared/widgets/buttons/primary_button.dart';
import 'package:crabsensemobile/shared/widgets/cards/crabsense_card.dart';
```

## Design Guidelines

All components follow:
- **Material Design 3** principles
- **CrabSense Brand Colors** (Primary #00C8FF, Background #081528)
- **Inter Font Family** for typography
- **8dp Grid System** for spacing
- **Border Radius**: 16dp for cards, 14dp for buttons/inputs
- **Dark Mode** as default theme
- **Glassmorphism** effects on cards

## Requirements Coverage

These components satisfy:
- **Requirements 20.1-20.10**: Material Design 3 UI Implementation
- **Requirements 21.6**: Error handling and user feedback with proper UI components
