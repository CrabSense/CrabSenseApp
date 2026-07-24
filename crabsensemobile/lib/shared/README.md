# Shared Module

This directory contains reusable components, widgets, and services that are used across multiple features.

## Structure

- `widgets/` - Reusable UI components (buttons, cards, inputs, overlays)
- `services/` - Shared services (authentication, storage, logging, notifications)
- `utils/` - Shared utility functions and helpers
- `models/` - Common data models used across features
- `theme/` - Shared theme components and styling

## Responsibilities

- Providing reusable UI components
- Managing cross-feature services
- Shared business logic that doesn't belong to a specific feature
- Common data models and utilities

## Guidelines

- Components should be generic and configurable
- Avoid feature-specific logic in shared components
- Use composition over inheritance
- Document props and usage examples
