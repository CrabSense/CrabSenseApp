# Core Module

This directory contains shared utilities, constants, extensions, and cross-cutting concerns used across the entire application.

## Structure

- `constants/` - Application-wide constants (colors, dimensions, API endpoints)
- `errors/` - Custom error/exception classes and failure types
- `network/` - HTTP client configuration, interceptors, and network utilities
- `theme/` - Theme data and styling configurations
- `utils/` - Helper functions, extensions, validators
- `extensions/` - Dart extensions for common types

## Responsibilities

- Providing reusable utilities and helpers
- Defining error handling patterns
- Network layer configuration
- Common extensions and type conversions
- Application constants management

## Key Principles

- No dependency on features or presentation layer
- Pure Dart code with minimal Flutter dependencies
- Reusable across different features
