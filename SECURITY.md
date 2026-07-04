# Security Policy

## Reporting a Vulnerability

If you believe you have found a security vulnerability in Meshum, **please do not open a
public GitHub issue**. Instead, report it privately to **security@meshum.dev**.

Please include:

- A description of the issue and its potential impact.
- The affected component (`daemon/` or `server/`, with version/commit if known).
- Reproduction steps, proof-of-concept, or any relevant logs.

We aim to acknowledge reports within **3 business days** and to coordinate a fix and
disclosure timeline with you.

## Scope

This policy covers the code in this repository. Vulnerabilities in third-party dependencies
should be reported to their respective maintainers; where applicable, also open a dependabot
alert or contact us so we can track it.

## Out of Scope

- Theoretical issues without a proof-of-concept.
- Social engineering, phishing, or physical attacks.
- Issues requiring already-compromised credentials.

## Supported Versions

Only the latest release line receives security fixes.
