# Security Policy

## Supported Versions

We release security updates and bug fixes for the latest version of the app.

| Version | Supported          |
| ------- | ------------------ |
| 1.1.x   | :white_check_mark: |
| < 1.1.0 | :x:                |

---

## 🔒 Reporting a Vulnerability

The Nirma Hub team takes the security of our users and data seriously. If you discover a security vulnerability or potential threat within the application, please do **NOT** open a public issue on GitHub.

Instead, please report it privately:

1. **Email**: Contact the lead maintainer directly at `dhruv.nirmahub@gmail.com` (or your preferred contact email).
2. **Details to Include**:
   - Description of the vulnerability.
   - Steps or proof-of-concept (PoC) to reproduce the issue.
   - Potential impact.
   - Suggested mitigation, if known.

We will review your submission promptly, validate the finding, and roll out a patch in the next Play Store release.

---

## 🛡️ Secret & Credential Protection

- **Never** commit `key.properties`, Android keystores (`*.jks`, `*.keystore`), or Supabase `service_role` private keys to this repository.
- Ensure all sensitive environment configs are placed in `.env` and kept in `.gitignore`.
