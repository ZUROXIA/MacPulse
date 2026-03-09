# Security Policy

## Supported Versions

| Version | Supported          |
|---------|--------------------|
| Latest  | :white_check_mark: |

## Reporting a Vulnerability

If you discover a security vulnerability in MacPulse, please report it responsibly.

**Do not open a public issue for security vulnerabilities.**

Instead, please report vulnerabilities via [GitHub Private Vulnerability Reporting](../../security/advisories/new).

When reporting, please include:

- A description of the vulnerability
- Steps to reproduce the issue
- The potential impact
- Any suggested fixes (if applicable)

We will acknowledge receipt within 48 hours and aim to provide a fix or mitigation plan as soon as possible.

## Scope

MacPulse accesses system metrics through macOS APIs (IOKit, Mach, proc). The App Store version runs inside an App Sandbox with restricted privileges. Security concerns related to the following are in scope:

- Data handling and storage (SQLite metrics database)
- Network requests (update checking via GitHub Releases API)
- Process management features (DMG version only)
- Any unintended privilege escalation
